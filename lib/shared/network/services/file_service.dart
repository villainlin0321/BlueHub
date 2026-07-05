import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:dio/dio.dart';

import '../../../shared/network/api_exception.dart';
import '../../../shared/logging/app_logger.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../../features/files/data/file_models.dart';

class FileService {
  FileService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 确认文件上传完成。
  ///
  /// 在文件成功上传到对象存储后调用该接口完成业务落库。
  Future<void> confirmUpload({required ConfirmUploadBO request}) async {
    return _apiClient.postVoid('/files/confirm', data: request.toJson());
  }

  /// 申请文件上传预签名信息。
  ///
  /// 返回文件 ID、对象键以及直传所需的上传地址。
  Future<FilePresignVO> presign({required FilePresignBO request}) async {
    final response = await _apiClient.post<FilePresignVO>(
      '/files/presign',
      data: request.toJson(),
      decode: (data) => FilePresignVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 执行完整的文件上传流程。
  ///
  /// 包含读取本地文件、申请预签名、直传对象存储、确认上传以及获取真实访问地址五个步骤。
  Future<FilePresignVO> uploadFile({
    required String path,
    required FileScene scene,
    String accessType = 'PUBLIC',
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final File localFile = File(path);
    if (!localFile.existsSync()) {
      throw ApiException.unknown('file not found');
    }

    final List<int> bytes = await localFile.readAsBytes();
    final String mimeType = resolveMimeType(path);
    final String resolvedErrorMessage = errorMessage.isEmpty
        ? tr('上传.文件上传失败')
        : errorMessage;
    final FilePresignVO response = await presign(
      request: FilePresignBO(
        fileName: UploadPickerUtils.basename(path),
        fileType: mimeType,
        fileSize: bytes.length,
        scene: scene,
        accessType: accessType,
      ),
    );
    final Uri? uploadUri = Uri.tryParse(response.uploadUrl);
    AppLogger.instance.info(
      'FILE_UPLOAD',
      '文件预签名成功',
      context: <String, Object?>{
        'scene': scene.value,
        'fileName': UploadPickerUtils.basename(path),
        'fileSize': bytes.length,
        'mimeType': mimeType,
        'fileId': response.fileId,
        'objectKey': response.objectKey,
        'uploadHost': uploadUri?.host ?? '',
      },
    );

    await putToUploadUrl(
      uploadUrl: response.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
      errorMessage: resolvedErrorMessage,
      onSendProgress: onSendProgress,
    );
    await confirmUpload(
      request: ConfirmUploadBO(
        fileId: response.fileId,
        objectKey: response.objectKey,
        fileSize: bytes.length,
      ),
    );
    AppLogger.instance.info(
      'FILE_UPLOAD',
      '文件上传确认成功',
      context: <String, Object?>{
        'scene': scene.value,
        'fileId': response.fileId,
        'objectKey': response.objectKey,
        'fileSize': bytes.length,
      },
    );
    final String fileUrl = await getFileUrl(fileId: response.fileId);
    return FilePresignVO(
      uploadUrl: response.uploadUrl,
      fileUrl: fileUrl,
      expireIn: response.expireIn,
      objectKey: response.objectKey,
      fileId: response.fileId,
    );
  }

  /// 将二进制文件内容上传到预签名地址。
  ///
  /// 上传失败时会统一抛出带业务提示语的 `ApiException`。
  Future<void> putToUploadUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String mimeType,
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final Uri? uploadUri = Uri.tryParse(uploadUrl);
    final Dio uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    final String resolvedErrorMessage = errorMessage.isEmpty
        ? tr('上传.文件上传失败')
        : errorMessage;
    try {
      final Response<dynamic> response = await uploadDio.put<dynamic>(
        uploadUrl,
        data: bytes,
        onSendProgress: onSendProgress,
        options: Options(
          headers: <String, Object>{
            Headers.contentTypeHeader: mimeType,
            Headers.contentLengthHeader: bytes.length,
          },
          responseType: ResponseType.plain,
          validateStatus: (int? status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      AppLogger.instance.info(
        'FILE_UPLOAD',
        '对象存储直传成功',
        context: <String, Object?>{
          'uploadHost': uploadUri?.host ?? '',
          'uploadPath': uploadUri?.path ?? '',
          'mimeType': mimeType,
          'contentLength': bytes.length,
          'statusCode': response.statusCode,
        },
      );
      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw ApiException.http(
          statusCode: response.statusCode,
          message: resolvedErrorMessage,
        );
      }
    } on DioException catch (error) {
      // 这里补齐对象存储直传失败现场，便于区分超时、403 签名问题或 TLS/网络异常。
      AppLogger.instance.error(
        'FILE_UPLOAD',
        '对象存储直传失败',
        error: error,
        stackTrace: error.stackTrace,
        context: <String, Object?>{
          'uploadHost': uploadUri?.host ?? '',
          'uploadPath': uploadUri?.path ?? '',
          'mimeType': mimeType,
          'contentLength': bytes.length,
          'dioType': error.type.name,
          'statusCode': error.response?.statusCode,
          'responseData': _truncateLogValue(error.response?.data),
          'message': error.message,
        },
      );
      throw ApiException.http(
        statusCode: error.response?.statusCode,
        message: resolvedErrorMessage,
        original: error,
      );
    } finally {
      uploadDio.close(force: true);
    }
  }

  /// 截断较长响应内容，避免上传失败日志把整份 HTML/XML 错误页写满日志文件。
  static String _truncateLogValue(Object? value, {int maxLength = 300}) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return '';
    }
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 根据文件路径推断 MIME 类型。
  ///
  /// 未识别的扩展名会回退为 `application/octet-stream`。
  static String resolveMimeType(String path) {
    final String extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'jpe':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  /// 获取文件的可访问地址。
  Future<String> getFileUrl({required int fileId}) async {
    final response = await _apiClient.get<String>(
      '/files/$fileId/url',
      decode: (data) => data as String? ?? '',
    );
    return response;
  }
}
