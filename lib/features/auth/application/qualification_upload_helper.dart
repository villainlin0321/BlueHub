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

  static const Duration _initialQualificationSyncDelay = Duration(
    milliseconds: 300,
  );
  static const List<Duration> _qualificationRetryDelays = <Duration>[
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(milliseconds: 1500),
  ];

  /// 上传资质图片：先走文件预签名上传，再回调资质接口登记文档信息。
  static Future<UploadedQualificationDoc> uploadQualificationImage({
    required WidgetRef ref,
    required PickedUploadFile file,
    required QualificationDocType docType,
    String? docName,
  }) async {
    final String path = file.path;
    final FilePresignVO presign = await ref
        .read(fileServiceProvider)
        .uploadFile(
          path: path,
          scene: docType.uploadScene,
          errorMessage: '文件上传失败，请稍后重试',
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

    await _uploadQualificationsWithRetry(
      ref: ref,
      request: UploadQualificationDocsBO(
        docs: <DocItemBO>[uploadedDoc.toDocItemBO()],
      ),
    );
    return uploadedDoc;
  }

  /// 规避文件确认后立即登记资质时的短暂一致性窗口，失败时做有限重试。
  static Future<void> _uploadQualificationsWithRetry({
    required WidgetRef ref,
    required UploadQualificationDocsBO request,
  }) async {
    await Future.delayed(_initialQualificationSyncDelay);

    Object? lastError;
    for (
      int attempt = 0;
      attempt <= _qualificationRetryDelays.length;
      attempt++
    ) {
      try {
        await ref
            .read(providerServiceProvider)
            .uploadQualifications(request: request);
        return;
      } catch (error) {
        lastError = error;
        if (!_shouldRetryQualificationUpload(error) ||
            attempt >= _qualificationRetryDelays.length) {
          rethrow;
        }
        await Future.delayed(_qualificationRetryDelays[attempt]);
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  static bool _shouldRetryQualificationUpload(Object error) {
    if (error is! ApiException) {
      return false;
    }
    if (error.type == ApiExceptionType.network ||
        error.type == ApiExceptionType.unknown) {
      return true;
    }
    return error.type == ApiExceptionType.http &&
        (error.statusCode == null || error.statusCode! >= 500);
  }
}
