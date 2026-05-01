import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../shared/widgets/upload_placeholder_tile.dart';
import '../../../utils/upload_picker_utils.dart';

class AddSkillCertificatePage extends StatefulWidget {
  const AddSkillCertificatePage({super.key});

  @override
  State<AddSkillCertificatePage> createState() =>
      _AddSkillCertificatePageState();
}

class _AddSkillCertificatePageState extends State<AddSkillCertificatePage> {
  static const int _maxAttachments = 9;
  static const String _uploadAsset =
      'assets/images/service_detail_report_upload.svg';
  static const List<SelectableSheetOption<String>> _certificateOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: '中式烹调师·五级', label: '中式烹调师·五级'),
        SelectableSheetOption<String>(value: '中式面点师·五级', label: '中式面点师·五级'),
        SelectableSheetOption<String>(value: '电工职业资格证', label: '电工职业资格证'),
        SelectableSheetOption<String>(value: '焊工职业资格证', label: '焊工职业资格证'),
        SelectableSheetOption<String>(value: '护理员职业技能证', label: '护理员职业技能证'),
        SelectableSheetOption<String>(value: '保育师职业技能证', label: '保育师职业技能证'),
      ];

  String? _certificateName;
  ResumeTimePickerValue? _issuedAt;
  final List<PickedUploadFile> _selectedImages = <PickedUploadFile>[];

  Future<void> _openCertificateSheet() async {
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '技能证书',
      options: _certificateOptions,
      initialSelectedValues: _certificateName == null
          ? const <String>[]
          : <String>[_certificateName!],
      multiple: false,
    );

    if (result == null || result.isEmpty) {
      return;
    }

    setState(() {
      _certificateName = result.first;
    });
  }

  Future<void> _openTimeSheet() async {
    final ResumeTimePickerValue? result = await showResumeTimePickerBottomSheet(
      context: context,
      type: ResumeTimePickerType.singleMonth,
      title: '获得时间',
      initialValue:
          _issuedAt ??
          ResumeTimePickerValue.suggestedSingleMonth(DateTime.now()),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _issuedAt = result;
    });
  }

  Future<void> _openImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (BuildContext sheetContext) {
        return _ImageSourceBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickImage(
              picker: UploadPickerUtils.pickFromCamera,
              errorMessage: '打开相机失败，请稍后重试',
            );
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickImage(
              picker: UploadPickerUtils.pickFromGallery,
              errorMessage: '打开相册失败，请稍后重试',
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage({
    required Future<List<PickedUploadFile>> Function() picker,
    required String errorMessage,
  }) async {
    if (_selectedImages.length >= _maxAttachments) {
      _showMessage('最多只能选择$_maxAttachments张');
      return;
    }

    try {
      final List<PickedUploadFile> files = await picker();
      if (!mounted || files.isEmpty) {
        return;
      }

      final List<PickedUploadFile> images = files
          .where((PickedUploadFile item) => item.isImage)
          .toList();
      final List<PickedUploadFile> candidates = images.isEmpty ? files : images;
      final int availableCount = _maxAttachments - _selectedImages.length;
      final List<PickedUploadFile> acceptedFiles = candidates
          .take(availableCount)
          .toList();
      if (acceptedFiles.isEmpty) {
        _showMessage('最多只能选择$_maxAttachments张');
        return;
      }

      setState(() {
        _selectedImages.addAll(acceptedFiles);
      });

      if (acceptedFiles.length < candidates.length) {
        _showMessage('最多只能选择$_maxAttachments张');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(errorMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSave() {
    if (_certificateName == null) {
      _showMessage('请选择技能证书');
      return;
    }
    if (_issuedAt == null) {
      _showMessage('请选择获得时间');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showMessage('请上传证书图片');
      return;
    }

    context.pop(
      ResumeCertificateFormResult(
        title: _certificateName!,
        issuedAt: _issuedAt!,
        imagePaths: _selectedImages
            .map((PickedUploadFile file) => file.path)
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF171A1D),
          ),
        ),
        title: const Text(
          '添加技能证书',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
          children: <Widget>[
            _CertificateSelectorField(
              label: '技能证书',
              value: _certificateName,
              onTap: _openCertificateSheet,
            ),
            const SizedBox(height: 16),
            _CertificateSelectorField(
              label: '获得时间',
              value: _issuedAt?.format(ResumeTimePickerType.singleMonth),
              onTap: _openTimeSheet,
            ),
            const SizedBox(height: 16),
            const Text(
              '证书图片',
              style: TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            _CertificateImageGrid(
              attachments: _selectedImages,
              maxAttachments: _maxAttachments,
              uploadAssetPath: _uploadAsset,
              onAddTap: _openImageSourceSheet,
              onDeleteTap: (PickedUploadFile file) {
                setState(() {
                  _selectedImages.removeWhere(
                    (PickedUploadFile item) => item.id == file.id,
                  );
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 44,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF096DD9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 22 / 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 33)
            ],
          ),
        ),
      ),
    );
  }
}

class ResumeCertificateFormResult {
  const ResumeCertificateFormResult({
    required this.title,
    required this.issuedAt,
    required this.imagePaths,
  });

  final String title;
  final ResumeTimePickerValue issuedAt;
  final List<String> imagePaths;
}

class _CertificateSelectorField extends StatelessWidget {
  const _CertificateSelectorField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                  ),
                ),
                padding: const EdgeInsets.only(top: 15, bottom: 15, right: 1),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        value ?? '请选择',
                        style: TextStyle(
                          color: value == null
                              ? const Color(0xFFBFBFBF)
                              : const Color(0xFF171A1D),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFBFBFBF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateImagePreviewTile extends StatelessWidget {
  const _CertificateImagePreviewTile({
    required this.file,
    required this.onDeleteTap,
  });

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
              child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const ColoredBox(color: Color(0xFFF5F7FA));
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDeleteTap,
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
          ),
        ),
      ],
    );
  }
}

class _CertificateImageGrid extends StatelessWidget {
  const _CertificateImageGrid({
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
          return UploadPlaceholderTile(
            assetPath: uploadAssetPath,
            onTap: onAddTap,
          );
        }

        final PickedUploadFile file = attachments[index];
        return _CertificateImagePreviewTile(
          file: file,
          onDeleteTap: () => onDeleteTap(file),
        );
      },
    );
  }
}

class _ImageSourceBottomSheet extends StatelessWidget {
  const _ImageSourceBottomSheet({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 52,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 36),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '选择图片',
                        style: TextStyle(
                          color: Color(0xFF171A1D),
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 25 / 17,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF171A1D),
                    ),
                  ),
                ],
              ),
            ),
            _BottomSheetActionItem(label: '拍照', onTap: onCameraTap),
            _BottomSheetActionItem(label: '从相册选择', onTap: onGalleryTap),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetActionItem extends StatelessWidget {
  const _BottomSheetActionItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF171A1D),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 22 / 16,
          ),
        ),
      ),
    );
  }
}
