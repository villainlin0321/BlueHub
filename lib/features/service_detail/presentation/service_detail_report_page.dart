import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../complaint/data/complaint_models.dart';
import '../../complaint/data/complaint_providers.dart';
import '../../complaint/presentation/complaint_detail_page.dart';
import '../../files/data/file_models.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../shared/widgets/upload_image_grid.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
class ServiceDetailReportPageArgs {
  const ServiceDetailReportPageArgs({
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.initialTitle = '',
  });

  final String targetType;
  final int targetId;
  final String targetName;
  final String initialTitle;
}

class ServiceDetailReportPage extends ConsumerStatefulWidget {
  const ServiceDetailReportPage({super.key, required this.args});

  final ServiceDetailReportPageArgs args;

  @override
  ConsumerState<ServiceDetailReportPage> createState() =>
      _ServiceDetailReportPageState();
}

class _ServiceDetailReportPageState
    extends ConsumerState<ServiceDetailReportPage> {
  static const int _maxTitleLength = 200;
  static const int _maxContentLength = 500;
  static const int _maxAttachments = 9;
  static const String _uploadAsset =
      'assets/images/service_detail_report_upload.svg';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<UploadedImageValue> _attachments = const <UploadedImageValue>[];
  bool _isUploadingImages = false;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isUploadingImages &&
      !_isSubmitting &&
      widget.args.targetId > 0 &&
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.args.initialTitle.trim();
    _titleController.addListener(_handleContentChanged);
    _contentController.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_handleContentChanged)
      ..dispose();
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    setState(() {});
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final int complaintId = await ref
          .read(complaintServiceProvider)
          .createComplaint(
            request: CreateComplaintBO(
              targetType: widget.args.targetType,
              targetId: widget.args.targetId,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              attachmentFileIds: _attachments
                  .map((UploadedImageValue item) => item.fileId)
                  .toList(growable: false),
            ),
          );
      if (!mounted) {
        return;
      }
      _showMessage('投诉.已提交'.tr());
      context.pushReplacement(
        RoutePaths.complaintDetail,
        extra: ComplaintDetailPageArgs(complaintId: complaintId),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error));
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.serviceDetail);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(
          color: const Color(0xE6000000),
          fontWeight: FontWeight.w500,
          fontSize: 17,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text('服务详情.举报'.tr(), style: titleStyle),
      ),
      body: TapBlankToDismissKeyboard(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: <Widget>[
            Container(
              width: 351,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '服务详情.举报内容'.tr(),
                    style: TestStyle.pingFangRegular(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.args.targetName.trim().isEmpty
                          ? '投诉.未命名对象'.tr()
                          : widget.args.targetName.trim(),
                      style: TestStyle.pingFangMedium(fontSize: 13, color: Color(0xFF262626)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '投诉.标题'.tr(),
                    style: TestStyle.pingFangRegular(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _titleController,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(_maxTitleLength),
                      ],
                      decoration: InputDecoration(
                        hintText: '投诉.请输入投诉标题'.tr(),
                        border: InputBorder.none,
                      ),
                      style: TestStyle.pingFangRegular(fontSize: 13, color: Color(0xFF262626)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '投诉.内容'.tr(),
                    style: TestStyle.pingFangRegular(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 264,
                    width: 327,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            expands: true,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            inputFormatters: <TextInputFormatter>[
                              LengthLimitingTextInputFormatter(
                                _maxContentLength,
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText: '通用.请输入'.tr(),
                              hintStyle: TestStyle.pingFangRegular(fontSize: 13, color: Color(0xFF8C8C8C)),
                              border: InputBorder.none,
                              isCollapsed: true,
                              counterText: '',
                            ),
                            style: TestStyle.regular(fontSize: 13, color: Color(0xFF262626)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${_contentController.text.characters.length}/$_maxContentLength',
                            style: TestStyle.regular(fontSize: 12, color: Color(0xFFBFBFBF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  UploadImageGrid(
                    scene: FileScene.material,
                    maxImages: _maxAttachments,
                    uploadAssetPath: _uploadAsset,
                    onChanged: (List<String> imageUrls) {
                      imageUrls;
                    },
                    onUploadedChanged: (List<UploadedImageValue> items) {
                      _attachments = items;
                    },
                    onUploadingChanged: (bool isUploading) {
                      setState(() {
                        _isUploadingImages = isUploading;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ReportSubmitBar(
        enabled: _canSubmit,
        isSubmitting: _isSubmitting,
        onPressed: _handleSubmit,
      ),
    );
  }

  String _resolveErrorMessage(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '投诉.提交失败'.tr() : message;
  }
}

class _ReportSubmitBar extends StatelessWidget {
  const _ReportSubmitBar({
    required this.enabled,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
            ),
          ),
          child: SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF096DD9),
                disabledBackgroundColor: const Color(
                  0xFF096DD9,
                ).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isSubmitting ? '通用.提交中'.tr() : '通用.提交'.tr(),
                style: TestStyle.pingFangMedium(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
