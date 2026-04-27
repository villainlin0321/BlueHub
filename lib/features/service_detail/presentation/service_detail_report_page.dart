import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../utils/upload_picker_utils.dart';

class ServiceDetailReportPage extends StatefulWidget {
  const ServiceDetailReportPage({super.key});

  @override
  State<ServiceDetailReportPage> createState() => _ServiceDetailReportPageState();
}

class _ServiceDetailReportPageState extends State<ServiceDetailReportPage> {
  static const int _maxContentLength = 500;
  static const int _maxAttachments = 9;
  static const String _uploadAsset =
      'assets/images/service_detail_report_upload.svg';

  final TextEditingController _contentController = TextEditingController();
  final List<PickedUploadFile> _attachments = <PickedUploadFile>[];

  bool get _canSubmit =>
      _contentController.text.trim().isNotEmpty || _attachments.isNotEmpty;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showUploadSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        return _UploadTypeBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFiles(
              picker: UploadPickerUtils.pickFromCamera,
              errorMessage: '打开相机失败，请稍后重试',
            );
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFiles(
              picker: UploadPickerUtils.pickFromGallery,
              errorMessage: '打开相册失败，请稍后重试',
            );
          },
          onFileTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFiles(
              picker: UploadPickerUtils.pickFromFiles,
              errorMessage: '选择文件失败，请稍后重试',
            );
          },
        );
      },
    );
  }

  Future<void> _pickFiles({
    required Future<List<PickedUploadFile>> Function() picker,
    required String errorMessage,
  }) async {
    if (_attachments.length >= _maxAttachments) {
      _showMessage('最多只能选择$_maxAttachments项');
      return;
    }

    try {
      final List<PickedUploadFile> pickedFiles = await picker();
      if (!mounted || pickedFiles.isEmpty) {
        return;
      }

      final int availableCount = _maxAttachments - _attachments.length;
      final List<PickedUploadFile> acceptedFiles = pickedFiles
          .take(availableCount)
          .toList();
      if (acceptedFiles.isEmpty) {
        _showMessage('最多只能选择$_maxAttachments项');
        return;
      }

      setState(() {
        _attachments.addAll(acceptedFiles);
      });

      if (acceptedFiles.length < pickedFiles.length) {
        _showMessage('最多只能选择$_maxAttachments项');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(errorMessage);
    }
  }

  void _removeAttachment(PickedUploadFile file) {
    setState(() {
      _attachments.removeWhere((PickedUploadFile item) => item.id == file.id);
    });
  }

  void _handleSubmit() {
    if (!_canSubmit) {
      return;
    }
    _showMessage('举报已提交（占位）');
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
        title: Text('举报', style: titleStyle),
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
                    '举报内容',
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
                              LengthLimitingTextInputFormatter(_maxContentLength),
                            ],
                            decoration: const InputDecoration(
                              hintText: '请输入...',
                              hintStyle: TextStyle(
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
                  _AttachmentGrid(
                    attachments: _attachments,
                    maxAttachments: _maxAttachments,
                    uploadAssetPath: _uploadAsset,
                    onAddTap: _showUploadSheet,
                    onDeleteTap: _removeAttachment,
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

class _AttachmentGrid extends StatelessWidget {
  const _AttachmentGrid({
    required this.attachments,
    required this.maxAttachments,
    required this.uploadAssetPath,
    required this.onAddTap,
    required this.onDeleteTap,
  });

  final List<PickedUploadFile> attachments;
  final int maxAttachments;
  final String uploadAssetPath;
  final VoidCallback onAddTap;
  final ValueChanged<PickedUploadFile> onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final bool showAddTile = attachments.length < maxAttachments;
    final int itemCount = attachments.length + (showAddTile ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= attachments.length) {
          return _AddAttachmentTile(
            assetPath: uploadAssetPath,
            onTap: onAddTap,
          );
        }

        final PickedUploadFile file = attachments[index];
        return _AttachmentTile(
          file: file,
          onDeleteTap: () => onDeleteTap(file),
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.file, required this.onDeleteTap});

  final PickedUploadFile file;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file.isImage
                  ? _ImageAttachmentContent(path: file.path)
                  : _FileAttachmentContent(file: file),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _AttachmentDeleteButton(onTap: onDeleteTap),
        ),
      ],
    );
  }
}

class _ImageAttachmentContent extends StatelessWidget {
  const _ImageAttachmentContent({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final File imageFile = File(path);
    if (!imageFile.existsSync()) {
      return const _MissingAttachmentFallback();
    }

    return Image.file(
      imageFile,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _MissingAttachmentFallback(),
    );
  }
}

class _FileAttachmentContent extends StatelessWidget {
  const _FileAttachmentContent({required this.file});

  final PickedUploadFile file;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/order_upload_file_pdf.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(height: 8),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 16 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingAttachmentFallback extends StatelessWidget {
  const _MissingAttachmentFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/images/order_upload_file_photo.svg',
        width: 32,
        height: 32,
      ),
    );
  }
}

class _AttachmentDeleteButton extends StatelessWidget {
  const _AttachmentDeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.close_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  const _AddAttachmentTile({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              assetPath,
              width: 24,
              height: 24,
              placeholderBuilder: (_) => const Icon(
                Icons.add_photo_alternate_outlined,
                size: 24,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '上传图片',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF595959),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadTypeBottomSheet extends StatelessWidget {
  const _UploadTypeBottomSheet({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
  });

  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onFileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 224,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 52,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 36),
                    Expanded(
                      child: Center(
                        child: Text(
                          '上传类型',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF171A1D),
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                height: 25 / 17,
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/order_upload_sheet_close.svg',
                              width: 14,
                              height: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36.75, 24, 36.75, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _UploadTypeAction(
                      label: '拍照上传',
                      iconAssetPath: 'assets/images/order_upload_sheet_camera.svg',
                      onTap: onCameraTap,
                    ),
                    _UploadTypeAction(
                      label: '本地相册',
                      iconAssetPath: 'assets/images/order_upload_sheet_gallery.svg',
                      onTap: onGalleryTap,
                    ),
                    _UploadTypeAction(
                      label: '本地文件',
                      iconAssetPath: 'assets/images/order_upload_sheet_file.svg',
                      onTap: onFileTap,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF171A1D),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTypeAction extends StatelessWidget {
  const _UploadTypeAction({
    required this.label,
    required this.iconAssetPath,
    required this.onTap,
  });

  final String label;
  final String iconAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAssetPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF595959),
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 18 / 13,
              ),
            ),
          ],
        ),
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
              child: const Text(
                '提交',
                style: TextStyle(
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
