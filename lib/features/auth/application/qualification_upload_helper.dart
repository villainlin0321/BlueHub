import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_exception.dart';
import '../../employer/data/employer_providers.dart';
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

  /// 在最终提交前统一上传草稿中的本地资质图片，并一次性登记 `docs` 数组。
  static Future<void> uploadDraftQualifications({
    required WidgetRef ref,
    required QualificationCertificationRole role,
    required QualificationCertificationDraft draft,
  }) async {
    draft.businessLicenseDoc = await _resolveDraftDocument(
      ref: ref,
      document: draft.businessLicenseDoc,
    );
    draft.specialPermitDoc = await _resolveDraftDocument(
      ref: ref,
      document: draft.specialPermitDoc,
    );
    draft.idCardEmblemDoc = await _resolveDraftDocument(
      ref: ref,
      document: draft.idCardEmblemDoc,
    );
    draft.idCardPortraitDoc = await _resolveDraftDocument(
      ref: ref,
      document: draft.idCardPortraitDoc,
    );

    final List<DocItemBO> docs = draft.qualificationDocs();
    if (docs.isEmpty) {
      return;
    }

    await _uploadQualificationsWithRetry(
      ref: ref,
      role: role,
      request: UploadQualificationDocsBO(docs: docs),
    );
  }

  /// 将单个草稿文档解析为最终可提交状态：历史远端图片直接复用，本地图片先上传文件。
  static Future<UploadedQualificationDoc?> _resolveDraftDocument({
    required WidgetRef ref,
    required UploadedQualificationDoc? document,
  }) async {
    if (document == null) {
      return null;
    }
    if (document.hasRemoteFile && !document.hasLocalFile) {
      return document;
    }
    if (!document.hasLocalFile) {
      return document.hasRemoteFile ? document : null;
    }

    final FilePresignVO presign = await ref
        .read(fileServiceProvider)
        .uploadFile(
          path: document.localPath,
          scene: document.docType.uploadScene,
          errorMessage: '上传.文件上传失败'.tr(),
        );

    return UploadedQualificationDoc(
      docType: document.docType,
      docName: document.docName,
      fileId: presign.fileId,
      fileUrl: presign.fileUrl,
      localPath: document.localPath,
    );
  }

  /// 规避文件确认后立即登记资质时的短暂一致性窗口，失败时做有限重试。
  static Future<void> _uploadQualificationsWithRetry({
    required WidgetRef ref,
    required QualificationCertificationRole role,
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
        if (role == QualificationCertificationRole.company) {
          await ref
              .read(employerServiceProvider)
              .uploadQualifications(request: request);
        } else {
          await ref
              .read(providerServiceProvider)
              .uploadQualifications(request: request);
        }
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
