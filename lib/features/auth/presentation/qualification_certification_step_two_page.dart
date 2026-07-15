import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import '../../../shared/widgets/app_toast.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:europepass/shared/ui/test_keys.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/guarded_pop_scope.dart';
import '../../../shared/widgets/unsaved_changes_exit_guard.dart';
import '../../../utils/upload_picker_utils.dart';
import 'qualification_certification_flow.dart';
import 'qualification_preview_resolver.dart';
import 'widgets/qualification_preview_image.dart';
import 'widgets/qualification_progress_stepper.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 记录第二步表单的关键字段快照，用于判断当前页面是否存在未保存改动。
class _QualificationStepTwoSnapshot {
  const _QualificationStepTwoSnapshot({
    required this.businessLicensePath,
    required this.specialPermitPath,
  });

  final String businessLicensePath;
  final String specialPermitPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _QualificationStepTwoSnapshot &&
        other.businessLicensePath == businessLicensePath &&
        other.specialPermitPath == specialPermitPath;
  }

  @override
  int get hashCode => Object.hash(businessLicensePath, specialPermitPath);
}

class QualificationCertificationStepTwoPage extends ConsumerStatefulWidget {
  const QualificationCertificationStepTwoPage({super.key, required this.args});

  final QualificationCertificationPageArgs args;

  @override
  ConsumerState<QualificationCertificationStepTwoPage> createState() =>
      _QualificationCertificationStepTwoPageState();
}

class _QualificationCertificationStepTwoPageState
    extends ConsumerState<QualificationCertificationStepTwoPage>
    with GuardedPopScopeMixin {
  PickedUploadFile? _businessLicenseImage;
  PickedUploadFile? _specialPermitImage;
  String? _debugBusinessLicensePathForTest;
  late _QualificationStepTwoSnapshot _initialSnapshot;

  QualificationCertificationDraft get _draft => widget.args.draft;
  List<String> get _steps => <String>[
    tr('认证流程.基本信息'),
    tr('认证流程.资质证明'),
    tr('认证流程.服务信息'),
  ];

  @override
  void initState() {
    super.initState();
    if (_draft.businessLicenseDoc != null) {
      final String? previewPath =
          QualificationPreviewResolver.resolvePreviewPath(
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
    _initialSnapshot = _buildCurrentSnapshot();
  }

  /// 采集当前上传区状态，用于和初始值做快照比对。
  _QualificationStepTwoSnapshot _buildCurrentSnapshot() {
    return _QualificationStepTwoSnapshot(
      businessLicensePath:
          _debugBusinessLicensePathForTest ?? _businessLicenseImage?.path ?? '',
      specialPermitPath: _specialPermitImage?.path ?? '',
    );
  }

  /// 统一处理离开第二步页面的动作，存在未保存改动时先弹确认框。
  Future<void> _handleAttemptLeave() async {
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: _buildCurrentSnapshot() != _initialSnapshot,
    );
    if (!mounted || !canLeave) {
      return;
    }
    // 优先执行真实返回；若当前路由栈不可返回，则兜底回到“我的”页。
    scheduleDirectPop(onCannotPop: () => context.go(RoutePaths.me));
  }

  /// 仅供测试注入已选营业执照图片，避免测试依赖真实上传流程。
  void debugSetBusinessLicenseForTest(String imagePath) {
    setState(() {
      // 仅让未保存快照感知“已选择文件”，避免测试环境真的去渲染本地图片。
      _debugBusinessLicensePathForTest = imagePath;
      _draft.businessLicenseDoc = UploadedQualificationDoc(
        docType: QualificationDocType.businessLicense,
        docName: tr('认证流程.营业执照'),
        localPath: imagePath,
      );
    });
  }

  /// 仅供测试直接触发第二步必填校验，避免测试依赖真实跳转环境。
  bool debugValidateRequiredImagesForTest() {
    return _validateRequiredImages();
  }

  /// 校验第二步必填图片是否已经选择完成。
  bool _validateRequiredImages() {
    if (_businessLicenseImage == null &&
        (_debugBusinessLicensePathForTest == null ||
            _debugBusinessLicensePathForTest!.isEmpty)) {
      AppToast.show(
        '认证流程.请上传营业执照'.tr(),
        position: AppToastPosition.center,
      );
      return false;
    }
    return true;
  }

  /// 统一处理第二步“下一步”动作，确保营业执照已准备完成后再进入第三步。
  void _handleNext() {
    if (!_validateRequiredImages()) {
      return;
    }

    context.go(
      RoutePaths.qualificationCertificationStepThree,
      extra: widget.args,
    );
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
        _businessLicenseImage = pickedFile;
        _draft.businessLicenseDoc = UploadedQualificationDoc(
          docType: QualificationDocType.businessLicense,
          docName: docType.localizedDefaultDocName,
          localPath: pickedFile.path,
        );
      } else {
        _specialPermitImage = pickedFile;
        _draft.specialPermitDoc = UploadedQualificationDoc(
          docType: QualificationDocType.specialPermit,
          docName: docType.localizedDefaultDocName,
          localPath: pickedFile.path,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildGuardedPopScope(
      onInterceptPop: _handleAttemptLeave,
      child: Scaffold(
        key: AppTestKeys.pageQualificationCertificationStepTwo,
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleAttemptLeave,
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
                        uploadKey: AppTestKeys
                            .actionQualificationBusinessLicenseUpload,
                        pickedFile: _businessLicenseImage,
                        isUploading: false,
                        onTap: () => _pickQualificationImage(
                          docType: QualificationDocType.businessLicense,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LicenseUploadSection(
                        title: '认证流程.特许经验许可'.tr(),
                        optionalLabel: '通用.选填'.tr(),
                        uploadKey:
                            AppTestKeys.actionQualificationSpecialPermitUpload,
                        pickedFile: _specialPermitImage,
                        isUploading: false,
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
                      onPressed: () => context.go(
                        RoutePaths.qualificationCertification,
                        extra: widget.args,
                      ),
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
                      key: AppTestKeys.actionQualificationStepTwoNext,
                      onPressed: _handleNext,
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
      ),
    );
  }
}

class _LicenseUploadSection extends StatelessWidget {
  const _LicenseUploadSection({
    required this.title,
    required this.onTap,
    this.uploadKey,
    this.pickedFile,
    this.isUploading = false,
    this.isRequired = false,
    this.optionalLabel,
  });

  final String title;
  final VoidCallback onTap;
  final Key? uploadKey;
  final PickedUploadFile? pickedFile;
  final bool isUploading;
  final bool isRequired;
  final String? optionalLabel;

  /// 统一弹出营业执照样例图，便于用户对照上传材料格式。
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: <Widget>[
                  Text(
                    title,
                    style: TestStyle.pingFangMedium(
                      fontSize: 14,
                      color: const Color(0xFF262626),
                    ).copyWith(height: 20 / 14),
                  ),
                  if (isRequired)
                    Text(
                      '*',
                      style: TestStyle.pingFangRegular(
                        fontSize: 14,
                        color: const Color(0xFFFF4D4F),
                      ).copyWith(height: 20 / 14),
                    ),
                  if (optionalLabel != null)
                    Text(
                      '($optionalLabel)',
                      style: TestStyle.pingFangRegular(
                        fontSize: 14,
                        color: const Color(0xFF8C8C8C),
                      ).copyWith(height: 20 / 14),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showSampleDialog(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF096DD9),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                '认证流程.查看样例'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 13,
                  color: const Color(0xFF096DD9),
                ).copyWith(height: 20 / 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _UploadPlaceholder(
          uploadKey: uploadKey,
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
    this.uploadKey,
    this.pickedFile,
    this.isUploading = false,
  });

  final VoidCallback onTap;
  final Key? uploadKey;
  final PickedUploadFile? pickedFile;
  final bool isUploading;

  /// 构建上传空态与已上传态共用的材料预览框，贴近设计稿的虚线描边和蒙层样式。
  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(8);
    return InkWell(
      key: uploadKey,
      onTap: isUploading ? null : onTap,
      borderRadius: borderRadius,
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          // 按设计稿 327x214 维持上传框比例，避免不同宽度下高度失真。
          aspectRatio: 327 / 214,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ClipRRect(
                borderRadius: borderRadius,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: QualificationPreviewImage(
                      previewPath: pickedFile?.path,
                      placeholderAsset:
                          'assets/images/qualification_license_placeholder.png',
                      fit: BoxFit.cover,
                      placeholderFit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                // 通过前景画笔补齐虚线描边，避免为单页精修引入额外依赖。
                child: CustomPaint(
                  painter: const _DashedRoundedRectPainter(
                    color: Color(0xFFD9D9D9),
                    radius: 8,
                  ),
                ),
              ),
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
              if (isUploading)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: borderRadius,
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
      ),
    );
  }
}

/// 为上传框绘制圆角虚线边框，尽量贴近设计稿中的点状描边效果。
class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  /// 逐段裁切圆角路径并绘制虚线，保证四角过渡平滑。
  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 1;
    const double dashLength = 4;
    const double gapLength = 3;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Rect rect = Offset.zero & size;
    final RRect rRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final Path borderPath = Path()..addRRect(rRect);

    for (final PathMetric metric in borderPath.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius;
  }
}
