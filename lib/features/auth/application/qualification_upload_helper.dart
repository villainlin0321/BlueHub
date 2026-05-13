import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_exception.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../visa/data/provider_models.dart';
import '../../visa/data/provider_providers.dart';
import '../presentation/qualification_certification_flow.dart';

class QualificationUploadHelper {
  QualificationUploadHelper._();

  /// 上传资质图片：先走文件预签名上传，再回调资质接口登记文档信息。
  static Future<UploadedQualificationDoc> uploadQualificationImage({
    required WidgetRef ref,
    required PickedUploadFile file,
    required QualificationDocType docType,
    String? docName,
  }) async {
    final String path = file.path;
    final File localFile = File(path);
    if (!localFile.existsSync()) {
      throw ApiException.unknown('qualification file not found');
    }

    final List<int> bytes = await localFile.readAsBytes();
    final String mimeType = _resolveMimeType(path);
    final FilePresignVO presign = await ref
        .read(fileServiceProvider)
        .presign(
          request: FilePresignBO(
            fileName: UploadPickerUtils.basename(path),
            fileType: mimeType,
            fileSize: bytes.length,
            scene: docType.uploadScene,
            accessType: 'PUBLIC',
          ),
        );

    await _putFileToPresignedUrl(
      uploadUrl: presign.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
    );
    await ref
        .read(fileServiceProvider)
        .confirmUpload(
          request: ConfirmUploadBO(
            fileId: presign.fileId,
            objectKey: presign.objectKey,
            fileSize: bytes.length,
          ),
        );

    final UploadedQualificationDoc uploadedDoc = UploadedQualificationDoc(
      docType: docType,
      docName: docName?.trim().isNotEmpty == true
          ? docName!.trim()
          : docType.defaultDocName,
      fileId: presign.fileId,
      fileUrl: presign.fileUrl,
      localPath: path,
    );
    await ref
        .read(providerServiceProvider)
        .uploadQualifications(
          request: UploadQualificationDocsBO(
            docs: <DocItemBO>[uploadedDoc.toDocItemBO()],
          ),
        );
    return uploadedDoc;
  }

  static Future<void> _putFileToPresignedUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String mimeType,
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
          message: '文件上传失败，请稍后重试',
        );
      }
    } on DioException catch (error) {
      throw ApiException.http(
        statusCode: error.response?.statusCode,
        message: '文件上传失败，请稍后重试',
        original: error,
      );
    } finally {
      uploadDio.close(force: true);
    }
  }

  static String _resolveMimeType(String path) {
    final String extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
