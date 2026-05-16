import 'dart:io';

import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:dio/dio.dart';

import '../../../shared/network/api_exception.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../../features/files/data/file_models.dart';

class FileService {
  FileService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> confirmUpload({required ConfirmUploadBO request}) async {
    return _apiClient.postVoid('/files/confirm', data: request.toJson());
  }

  Future<FilePresignVO> presign({required FilePresignBO request}) async {
    final response = await _apiClient.post<FilePresignVO>(
      '/files/presign',
      data: request.toJson(),
      decode: (data) => FilePresignVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<FilePresignVO> uploadFile({
    required String path,
    required FileScene scene,
    String accessType = 'PUBLIC',
    String errorMessage = '文件上传失败，请稍后重试',
  }) async {
    final File localFile = File(path);
    if (!localFile.existsSync()) {
      throw ApiException.unknown('file not found');
    }

    final List<int> bytes = await localFile.readAsBytes();
    final String mimeType = resolveMimeType(path);
    final FilePresignVO response = await presign(
      request: FilePresignBO(
        fileName: UploadPickerUtils.basename(path),
        fileType: mimeType,
        fileSize: bytes.length,
        scene: scene,
        accessType: accessType,
      ),
    );

    await putToUploadUrl(
      uploadUrl: response.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
      errorMessage: errorMessage,
    );
    await confirmUpload(
      request: ConfirmUploadBO(
        fileId: response.fileId,
        objectKey: response.objectKey,
        fileSize: bytes.length,
      ),
    );
    return response;
  }

  Future<void> putToUploadUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String mimeType,
    String errorMessage = '文件上传失败，请稍后重试',
  }) async {
    final Dio uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    try {
      final Response<dynamic> response = await uploadDio.put<dynamic>(
        uploadUrl,
        data: bytes,
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
      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw ApiException.http(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    } on DioException catch (error) {
      throw ApiException.http(
        statusCode: error.response?.statusCode,
        message: errorMessage,
        original: error,
      );
    } finally {
      uploadDio.close(force: true);
    }
  }

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

  Future<String> getFileUrl({required int fileId}) async {
    final response = await _apiClient.get<String>(
      '/files/$fileId/url',
      decode: (data) => data as String? ?? '',
    );
    return response;
  }
}
