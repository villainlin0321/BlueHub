import 'dart:io';

import '../../../shared/widgets/app_toast.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../utils/upload_picker_utils.dart';
import '../application/qualification_upload_helper.dart';
import 'qualification_certification_flow.dart';
import 'qualification_preview_resolver.dart';
import 'widgets/qualification_progress_stepper.dart';

import 'package:europepass/shared/ui/test_style.dart';

class QualificationCertificationStepTwoPage extends ConsumerStatefulWidget {
  const QualificationCertificationStepTwoPage({super.key, required this.args});

  final QualificationCertificationPageArgs args;

  @override
  ConsumerState<QualificationCertificationStepTwoPage> createState() =>
      _QualificationCertificationStepTwoPageState();
}

class _QualificationCertificationStepTwoPageState
    extends ConsumerState<QualificationCertificationStepTwoPage> {
  PickedUploadFile? _businessLicenseImage;
  PickedUploadFile? _specialPermitImage;
  bool _isUploadingBusinessLicense = false;
  bool _isUploadingSpecialPermit = false;

  QualificationCertificationRole get _role => widget.args.role;
  QualificationCertificationDraft get _draft => widget.args.draft;
  List<String> get _steps => <String>[
    tr('认证流程.基本信息'),
    tr('认证流程.资质证明'),
    tr('认证流程.服务信息'),
  ];

  @override
  /// 初始化第二页历史上传文件，确保编辑场景能直接回显本地或远端图片。
  void initState() {
    super.initState();
    if (_draft.businessLicenseDoc != null) {
      final String? previewPath = QualificationPreviewResolver.resolvePreviewPath(
        _draft.businessLicenseDoc,
      );
      if (previewPath != null) {
        _businessLicenseImage = PickedUploadFile(
          id: 'qualification-business-license',
          name: _draft.businessLicenseDoc!.docName,
          path: previewPath,
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
          isImage: true,
          sizeLabel: '',
        );
      }
    }
    if (_draft.specialPermitDoc != null) {
      final String? previewPath =
          QualificationPreviewResolver.resolvePreviewPath(
            _draft.specialPermitDoc,
          );
      if (previewPath != null) {
        _specialPermitImage = PickedUploadFile(
          id: 'qualification-special-permit',
          name: _draft.specialPermitDoc!.docName,
          path: previewPath,
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
          isImage: true,
          sizeLabel: '',
        );
      }
    }
  }

  Future<void> _pickQualificationImage({
    required QualificationDocType docType,
  }) async {
    final List<PickedUploadFile> files =
        await UploadPickerUtils.pickImagesWithSourceSheet(
          context: context,
          title: tr('上传.选择图片'),
        );
    if (!mounted || files.isEmpty) {
      return;
    }

    final PickedUploadFile pickedFile = files.firstWhere(
      (PickedUploadFile file) => file.isImage,
      orElse: () => files.first,
    );
    setState(() {
      if (docType == QualificationDocType.businessLicense) {
        _isUploadingBusinessLicense = true;
      } else {
        _isUploadingSpecialPermit = true;
      }
    });
    try {
      final UploadedQualificationDoc uploadedDoc =
          await QualificationUploadHelper.uploadQualificationImage(
            ref: ref,
            role: _role,
            file: pickedFile,
            docType: docType,
            docName: docType.localizedDefaultDocName,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (docType == QualificationDocType.businessLicense) {
          _businessLicenseImage = pickedFile;
          _draft.businessLicenseDoc = uploadedDoc;
        } else {
          _specialPermitImage = pickedFile;
          _draft.specialPermitDoc = uploadedDoc;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show('认证流程.上传失败'.tr());
    } finally {
      if (mounted) {
        setState(() {
          if (docType == QualificationDocType.businessLicense) {
            _isUploadingBusinessLicense = false;
          } else {
            _isUploadingSpecialPermit = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '认证流程.资质认证'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '认证流程.实名认证提示'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF8C8C8C),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: QualificationProgressStepper(
                labels: _steps,
                currentStep: 2,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LicenseUploadSection(
                      title: '认证流程.营业执照'.tr(),
                      isRequired: true,
                      pickedFile: _businessLicenseImage,
                      isUploading: _isUploadingBusinessLicense,
                      onTap: () => _pickQualificationImage(
                        docType: QualificationDocType.businessLicense,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LicenseUploadSection(
                      title: '认证流程.特许经验许可'.tr(),
                      optionalLabel: '通用.选填'.tr(),
                      pickedFile: _specialPermitImage,
                      isUploading: _isUploadingSpecialPermit,
                      onTap: () => _pickQualificationImage(
                        docType: QualificationDocType.specialPermit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD9D9D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '认证流程.上一步'.tr(),
                      style: TestStyle.pingFangRegular(
                        fontSize: 16,
                        color: Color(0xFF171A1D),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => context.push(
                      RoutePaths.qualificationCertificationStepThree,
                      extra: widget.args,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF096DD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '认证流程.下一步'.tr(),
                      style: TestStyle.pingFangRegular(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseUploadSection extends StatelessWidget {
  const _LicenseUploadSection({
    required this.title,
    required this.onTap,
    this.pickedFile,
    this.isUploading = false,
    this.isRequired = false,
    this.optionalLabel,
  });

  final String title;
  final VoidCallback onTap;
  final PickedUploadFile? pickedFile;
  final bool isUploading;
  final bool isRequired;
  final String? optionalLabel;

  void _showSampleDialog(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'business-license-sample',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Image.asset(
                        'assets/images/image_business_license.png',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              title,
              style: TestStyle.medium(fontSize: 14, color: Color(0xFF262626)),
            ),
            if (isRequired) ...<Widget>[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TestStyle.regular(
                  fontSize: 14,
                  color: Color(0xFFFF4D4F),
                ),
              ),
            ],
            if (optionalLabel != null) ...<Widget>[
              const SizedBox(width: 4),
              Text(
                optionalLabel!,
                style: TestStyle.regular(
                  fontSize: 13,
                  color: Color(0xFF8C8C8C),
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () => _showSampleDialog(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '认证流程.查看样例'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF096DD9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _UploadPlaceholder(
          pickedFile: pickedFile,
          isUploading: isUploading,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({
    required this.onTap,
    this.pickedFile,
    this.isUploading = false,
  });

  final VoidCallback onTap;
  final PickedUploadFile? pickedFile;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD9D9D9),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _buildPreviewImage(),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0x80000000),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/images/qualification_camera.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 根据当前文件路径构建占位图、本地图片或缓存网络图片。
  Widget _buildPreviewImage() {
    final String? path = pickedFile?.path.trim();
    if (path == null || path.isEmpty) {
      return const _QualificationPlaceholderImage();
    }
    if (QualificationPreviewResolver.isNetworkPath(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const _QualificationPlaceholderImage(),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _QualificationPlaceholderImage(),
    );
  }
}

/// 渲染第二页上传区域的默认占位图，供空态和加载失败场景复用。
class _QualificationPlaceholderImage extends StatelessWidget {
  const _QualificationPlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage('assets/images/qualification_license_placeholder.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0x80000000),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/images/qualification_camera.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
