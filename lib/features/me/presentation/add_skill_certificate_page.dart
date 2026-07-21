import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../files/data/file_models.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../shared/widgets/upload_image_grid.dart';

import 'package:europepass/shared/ui/test_style.dart';
class AddSkillCertificatePage extends ConsumerStatefulWidget {
  const AddSkillCertificatePage({super.key, this.args});

  final AddSkillCertificatePageArgs? args;

  @override
  ConsumerState<AddSkillCertificatePage> createState() =>
      _AddSkillCertificatePageState();
}

class _AddSkillCertificatePageState
    extends ConsumerState<AddSkillCertificatePage> {
  static const int _maxAttachments = 1;
  static const String _uploadAsset =
      'assets/images/service_detail_report_upload.svg';

  String? _certificateName;
  ResumeTimePickerValue? _issuedAt;
  List<String> _uploadedImageUrls = const <String>[];
  List<UploadedImageValue> _uploadedImages = const <UploadedImageValue>[];
  bool _isUploadingImages = false;

  AddSkillCertificatePageArgs get _resolvedArgs =>
      widget.args ?? const AddSkillCertificatePageArgs();

  bool get _isEditMode => _resolvedArgs.initialValue != null;

  @override
  void initState() {
    super.initState();
    final ResumeCertificateFormResult? initialValue =
        _resolvedArgs.initialValue;
    if (initialValue == null) {
      return;
    }
    _certificateName = initialValue.title;
    _issuedAt = initialValue.issuedAt;
    _uploadedImageUrls = List<String>.from(
      initialValue.networkImageUrls,
      growable: false,
    );
    if (initialValue.imageFileId != null && _uploadedImageUrls.isNotEmpty) {
      _uploadedImages = <UploadedImageValue>[
        UploadedImageValue(
          fileId: initialValue.imageFileId!,
          fileUrl: _uploadedImageUrls.first,
          previewPath: _uploadedImageUrls.first,
        ),
      ];
    }
  }

  Future<List<SelectableSheetOption<String>>> _loadCertificateOptions() async {
    final List<TagItemVO> tags = await ref.read(
      tagDictionaryProvider(TagCategory.skillCertType).future,
    );
    return tags
        .map((TagItemVO item) {
          final String label = item.tagNameZh.trim().isNotEmpty
              ? item.tagNameZh.trim()
              : item.tagCode.trim();
          return SelectableSheetOption<String>(value: label, label: label);
        })
        .toList(growable: false);
  }

  Future<void> _openCertificateSheet() async {
    final List<SelectableSheetOption<String>> certificateOptions;
    try {
      certificateOptions = await _loadCertificateOptions();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('我的.技能证书字典加载失败'.tr());
      return;
    }
    if (certificateOptions.isEmpty) {
      if (!mounted) {
        return;
      }
      _showMessage('我的.暂无可选技能证书'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '我的.技能证书'.tr(),
      options: certificateOptions,
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
      title: '我的.获得时间'.tr(),
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

  void _showMessage(String message) {
    AppToast.show(message);
  }

  void _handleSave() {
    if (_isUploadingImages) {
      _showMessage('我的.图片上传中请稍候'.tr());
      return;
    }
    if (_certificateName == null) {
      _showMessage('我的.请选择技能证书'.tr());
      return;
    }
    if (_issuedAt == null) {
      _showMessage('我的.请选择获得时间'.tr());
      return;
    }
    if (_uploadedImages.isEmpty) {
      _showMessage('我的.请上传证书图片'.tr());
      return;
    }
    final UploadedImageValue selectedImage = _uploadedImages.first;

    context.pop(
      ResumeCertificatePageResult.saved(
        ResumeCertificateFormResult(
          title: _certificateName!,
          issuedAt: _issuedAt!,
          localImagePaths: const <String>[],
          networkImageUrls: _uploadedImageUrls,
          imageFileId: selectedImage.fileId,
        ),
      ),
    );
  }

  void _handleDelete() {
    context.pop(const ResumeCertificatePageResult.deleted());
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
        title: Text(
          '我的.技能证书'.tr(),
          style: TestStyle.pingFangMedium(fontSize: 17, color: Color(0xE6000000)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
          children: <Widget>[
            _CertificateSelectorField(
              label: '我的.技能证书'.tr(),
              value: _certificateName,
              onTap: _openCertificateSheet,
            ),
            const SizedBox(height: 16),
            _CertificateSelectorField(
              label: '我的.获得时间'.tr(),
              value: _issuedAt?.format(ResumeTimePickerType.singleMonth),
              onTap: _openTimeSheet,
            ),
            const SizedBox(height: 16),
            Text(
              '我的.证书图片'.tr(),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF595959)),
            ),
            const SizedBox(height: 12),
            UploadImageGrid(
              scene: FileScene.cert,
              maxImages: _maxAttachments,
              uploadAssetPath: _uploadAsset,
              initialUploadedValues:
                  _resolvedArgs.initialValue?.imageFileId == null ||
                      _resolvedArgs.initialValue!.networkImageUrls.isEmpty
                  ? const <UploadedImageValue>[]
                  : <UploadedImageValue>[
                      UploadedImageValue(
                        fileId: _resolvedArgs.initialValue!.imageFileId!,
                        fileUrl:
                            _resolvedArgs.initialValue!.networkImageUrls.isEmpty
                            ? ''
                            : _resolvedArgs.initialValue!.networkImageUrls.first,
                        previewPath:
                            _resolvedArgs.initialValue!.networkImageUrls.isEmpty
                            ? ''
                            : _resolvedArgs.initialValue!.networkImageUrls.first,
                      ),
                    ],
              initialImagePaths: <String>[
                ..._resolvedArgs.initialValue?.localImagePaths ??
                    const <String>[],
                ..._resolvedArgs.initialValue?.networkImageUrls ??
                    const <String>[],
              ],
              onChanged: (List<String> imageUrls) {
                _uploadedImageUrls = imageUrls;
              },
              onUploadedChanged: (List<UploadedImageValue> uploadedImages) {
                _uploadedImages = uploadedImages;
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
              Row(
                children: <Widget>[
                  if (_isEditMode) ...<Widget>[
                    Expanded(
                      flex: 110,
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _handleDelete,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEB),
                            foregroundColor: const Color(0xFFD9363E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '我的.删除'.tr(),
                            style: TestStyle.pingFangRegular(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _isEditMode ? 221 : 1,
                    child: SizedBox(
                      height: 44,
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
                        child: Text(
                          '我的.保存'.tr(),
                          style: TestStyle.pingFangRegular(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 33),
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
    this.localImagePaths = const <String>[],
    this.networkImageUrls = const <String>[],
    this.imageFileId,
  });

  final String title;
  final ResumeTimePickerValue issuedAt;
  final List<String> localImagePaths;
  final List<String> networkImageUrls;
  final int? imageFileId;
}

class AddSkillCertificatePageArgs {
  const AddSkillCertificatePageArgs({this.initialValue});

  final ResumeCertificateFormResult? initialValue;
}

class ResumeCertificatePageResult {
  const ResumeCertificatePageResult.saved(this.value) : deleted = false;

  const ResumeCertificatePageResult.deleted() : value = null, deleted = true;

  final ResumeCertificateFormResult? value;
  final bool deleted;
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
            style: TestStyle.regular(fontSize: 14, color: Color(0xFF595959)),
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
                        value ?? '通用.请选择'.tr(),
                        style: TestStyle.pingFangRegular(fontSize: 16, color: value == null
                              ? const Color(0xFFBFBFBF)
                              : const Color(0xFF171A1D)),
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
