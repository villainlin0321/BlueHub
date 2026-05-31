import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../files/data/file_models.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../shared/widgets/upload_image_grid.dart';

class ServiceDetailReportPage extends StatefulWidget {
  const ServiceDetailReportPage({super.key});

  @override
  State<ServiceDetailReportPage> createState() =>
      _ServiceDetailReportPageState();
}

class _ServiceDetailReportPageState extends State<ServiceDetailReportPage> {
  static const int _maxContentLength = 500;
  static const int _maxAttachments = 9;
  static const String _uploadAsset =
      'assets/images/service_detail_report_upload.svg';

  final TextEditingController _contentController = TextEditingController();
  List<String> _attachmentUrls = const <String>[];
  bool _isUploadingImages = false;

  bool get _canSubmit =>
      !_isUploadingImages &&
      (_contentController.text.trim().isNotEmpty || _attachmentUrls.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSubmit() {
    if (!_canSubmit) {
      return;
    }
    _showMessage('服务详情.举报已提交'.tr());
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
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
                              hintStyle: const TextStyle(
                                color: Color(0xFF8C8C8C),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                              counterText: '',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${_contentController.text.characters.length}/$_maxContentLength',
                            style: const TextStyle(
                              color: Color(0xFFBFBFBF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                            ),
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
                      _attachmentUrls = imageUrls;
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
        onPressed: _handleSubmit,
      ),
    );
  }
}

class _ReportSubmitBar extends StatelessWidget {
  const _ReportSubmitBar({required this.enabled, required this.onPressed});

  final bool enabled;
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
                '订单.提交材料'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
