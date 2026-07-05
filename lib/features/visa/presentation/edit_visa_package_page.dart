import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../shared/widgets/app_toast.dart';
import '../../../shared/models/app_currency.dart';
import '../../../shared/widgets/app_currency_bottom_sheet.dart';
import '../../../shared/widgets/guarded_pop_scope.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/unsaved_changes_exit_guard.dart';
import '../../../utils/upload_picker_utils.dart';

import '../../../app/router/route_paths.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../me/data/dictionary_providers.dart';
import '../../me/presentation/country_options_bottom_sheet.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../application/edit_visa_package/edit_visa_package_controller.dart';
import '../application/edit_visa_package/edit_visa_package_state.dart';
import '../data/visa_package_models.dart';
import '../data/visa_package_providers.dart';
import 'widgets/edit_visa_package_form_widgets.dart';
import 'widgets/edit_visa_package_page_view.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 供测试复用页面快照构建逻辑，确保断言与提交态脏数据判断保持一致。
@visibleForTesting
Object buildEditVisaPackageSnapshotForTest({
  required EditVisaPackageState state,
  required TextEditingController serviceNameController,
  required TextEditingController durationController,
  required PickedUploadFile? coverImage,
  required List<EditVisaPackageTierViewDraft> tiers,
}) {
  return _buildEditVisaPackageSnapshot(
    state: state,
    serviceNameController: serviceNameController,
    durationController: durationController,
    coverImage: coverImage,
    tiers: tiers,
  );
}

/// 按照实际提交结果会使用到的字段构建快照，统一未保存拦截的比较口径。
_EditVisaPackageSnapshot _buildEditVisaPackageSnapshot({
  required EditVisaPackageState state,
  required TextEditingController serviceNameController,
  required TextEditingController durationController,
  required PickedUploadFile? coverImage,
  required List<EditVisaPackageTierViewDraft> tiers,
}) {
  return _EditVisaPackageSnapshot(
    serviceName: serviceNameController.text.trim(),
    duration: durationController.text.trim(),
    countryCode: state.selectedCountryCode,
    visaTypeCode: state.selectedVisaTypeCode,
    currency: state.selectedCurrency.apiValue,
    coverImageId: _collectSnapshotCoverImageIdentity(coverImage),
    tiers: tiers
        .map((EditVisaPackageTierViewDraft tier) {
          final List<String> normalizedSelectedServiceTagCodes =
              tier.selectedServiceTagCodes
                  .map((String item) => item.trim())
                  .where((String item) => item.isNotEmpty)
                  .toSet()
                  .toList(growable: false)
                ..sort();
          final List<String> normalizedCustomServices = <String>[];
          final Set<String> seenCustomServices = <String>{};
          for (final String item in tier.customServices) {
            final String normalized = item.trim();
            if (normalized.isEmpty || !seenCustomServices.add(normalized)) {
              continue;
            }
            normalizedCustomServices.add(normalized);
          }
          final List<_EditVisaPackageMaterialSnapshot> materialSnapshots =
              tier.showMaterials
              ? tier.materials
                    .map((EditVisaPackageMaterialViewDraft material) {
                      return _EditVisaPackageMaterialSnapshot(
                        name: material.titleController.text.trim(),
                        description: material.descriptionController.text.trim(),
                        isRequired: material.isRequired,
                        exampleFileIds: _collectSnapshotExampleFileIds(material),
                      );
                    })
                    .toList(growable: false)
              : const <_EditVisaPackageMaterialSnapshot>[];
          return _EditVisaPackageTierSnapshot(
            tierId: tier.tierId,
            name: tier.nameController.text.trim(),
            price: tier.priceController.text.trim(),
            description: tier.descriptionController.text.trim(),
            showMaterials: tier.showMaterials,
            selectedServiceTagCodes: normalizedSelectedServiceTagCodes,
            customServices: normalizedCustomServices,
            materials: materialSnapshots,
          );
        })
        .toList(growable: false),
  );
}

/// 归一化材料示例文件 ID，和提交请求对齐，避免同值不同顺序造成误判。
List<int> _collectSnapshotExampleFileIds(EditVisaPackageMaterialViewDraft material) {
  final List<int> fileIds = <int>{
    ...material.existingExampleFileIds,
    ...material.exampleFiles
        .where((PickedUploadFile file) => file.state == UploadItemState.success)
        .map((PickedUploadFile file) => file.uploadedFileId)
        .whereType<int>(),
  }.toList(growable: false)
    ..sort();
  return fileIds;
}

/// 归一化封面图快照口径，只统计真实会进入请求体的 success 封面状态。
String _collectSnapshotCoverImageIdentity(PickedUploadFile? coverImage) {
  if (coverImage == null || coverImage.state != UploadItemState.success) {
    return '';
  }
  // 这里必须和提交请求的封面收集逻辑保持一致，避免未提交值被误判为脏数据。
  final int? uploadedFileId = coverImage.uploadedFileId;
  final String normalizedId =
      uploadedFileId != null && uploadedFileId > 0 ? '$uploadedFileId' : '';
  final String resolvedUrl = (coverImage.uploadedFileUrl ?? coverImage.path)
      .trim();
  if (normalizedId.isEmpty && resolvedUrl.isEmpty) {
    return '';
  }
  return '$normalizedId|$resolvedUrl';
}

class EditVisaPackagePage extends ConsumerStatefulWidget {
  const EditVisaPackagePage({super.key, this.packageId});

  final int? packageId;

  @override
  ConsumerState<EditVisaPackagePage> createState() =>
      _EditVisaPackagePageState();
}

class _EditVisaPackagePageState extends ConsumerState<EditVisaPackagePage>
    with GuardedPopScopeMixin {
  late final TextEditingController _serviceNameController;
  late final TextEditingController _durationController;
  late final List<EditVisaPackageTierViewDraft> _tiers;
  PickedUploadFile? _coverImage;
  bool _isLoadingPackageDetail = false;
  String? _packageDetailError;
  late _EditVisaPackageSnapshot _initialSnapshot;
  bool _hasInitialSnapshot = false;

  bool get _isEditMode => widget.packageId != null;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController();
    _durationController = TextEditingController();
    _tiers = <EditVisaPackageTierViewDraft>[_createTierDraft()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(editVisaPackageControllerProvider.notifier).loadServiceTags();
      if (_isEditMode) {
        _loadPackageDetail();
        return;
      }
      _initialSnapshot = _buildCurrentSnapshot();
      _hasInitialSnapshot = true;
    });
  }

  /// 汇总会影响提交结果的字段，作为页面未保存状态的判断基线。
  _EditVisaPackageSnapshot _buildCurrentSnapshot() {
    return _buildEditVisaPackageSnapshot(
      state: ref.read(editVisaPackageControllerProvider),
      serviceNameController: _serviceNameController,
      durationController: _durationController,
      coverImage: _coverImage,
      tiers: _tiers,
    );
  }

  /// 提交成功后刷新基线，确保后续返回判断基于最新已提交的数据。
  void _markSavedSnapshot() {
    _initialSnapshot = _buildCurrentSnapshot();
    _hasInitialSnapshot = true;
  }

  /// 统一处理头部返回和系统返回，在存在未保存改动时弹出确认框。
  Future<void> _handleAttemptLeave() async {
    final bool hasUnsavedChanges =
        _hasInitialSnapshot && _buildCurrentSnapshot() != _initialSnapshot;
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: hasUnsavedChanges,
    );
    if (!mounted || !canLeave) {
      return;
    }
    scheduleDirectPop();
  }

  EditVisaPackageTierViewDraft _createTierDraft({
    int tierId = 0,
    bool deletable = false,
  }) {
    return EditVisaPackageTierViewDraft(
      tierId: tierId,
      nameController: TextEditingController(text: '签证编辑.基础套餐'.tr()),
      priceController: TextEditingController(),
      descriptionController: TextEditingController(),
      showMaterials: true,
      selectedServiceTagCodes: <String>{},
      customServices: <String>[],
      materials: <EditVisaPackageMaterialViewDraft>[_createMaterialDraft()],
      deletable: deletable,
    );
  }

  EditVisaPackageMaterialViewDraft _createMaterialDraft() {
    return EditVisaPackageMaterialViewDraft(
      titleController: TextEditingController(),
      descriptionController: TextEditingController(),
      isRequired: false,
      exampleFiles: <PickedUploadFile>[],
      existingExampleFileIds: const <int>[],
    );
  }

  EditVisaPackageMaterialViewDraft _createMaterialDraftFromModel(
    VisaPackageEditMaterialVO material,
  ) {
    final List<PickedUploadFile> existingExampleFiles =
        _buildExistingExampleFiles(material);
    return EditVisaPackageMaterialViewDraft(
      titleController: TextEditingController(text: material.name),
      descriptionController: TextEditingController(text: material.description),
      isRequired: material.isRequired,
      exampleFiles: existingExampleFiles,
      existingExampleFileIds: List<int>.from(material.exampleFileIds),
    );
  }

  List<PickedUploadFile> _buildExistingExampleFiles(
    VisaPackageEditMaterialVO material,
  ) {
    final int itemCount = math.min(
      material.exampleFileIds.length,
      material.exampleFileUrls.length,
    );
    return List<PickedUploadFile>.generate(itemCount, (int index) {
      final int fileId = material.exampleFileIds[index];
      final String fileUrl = material.exampleFileUrls[index].trim();
      final String normalizedPath = _normalizedPathFromUrl(fileUrl);
      return PickedUploadFile(
        id: 'visa_example_$fileId',
        name: _displayNameFromUrl(fileUrl),
        path: normalizedPath.isEmpty ? fileUrl : normalizedPath,
        sourceType: UploadSourceType.file,
        state: UploadItemState.success,
        isImage: UploadPickerUtils.isImagePath(normalizedPath),
        progress: 1,
        uploadedFileId: fileId,
        uploadedFileUrl: fileUrl,
      );
    });
  }

  String _normalizedPathFromUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }
    final String path = uri.path.trim();
    return path.isEmpty ? value : path;
  }

  String _displayNameFromUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    final String lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last.trim()
        : value.trim().split('/').last.trim();
    if (lastSegment.isEmpty) {
      return '签证编辑.示例文件'.tr();
    }
    return Uri.decodeComponent(lastSegment);
  }

  PickedUploadFile? _buildExistingCoverImage(VisaPackageEditVO detail) {
    final int itemCount = math.max(
      detail.coverImageIds.length,
      detail.coverImages.length,
    );
    int? coverImageId;
    String coverImageUrl = '';
    for (int index = 0; index < itemCount; index++) {
      final int? currentId = index < detail.coverImageIds.length
          ? detail.coverImageIds[index]
          : null;
      final String currentUrl = index < detail.coverImages.length
          ? detail.coverImages[index].trim()
          : '';
      if ((currentId ?? 0) <= 0 && currentUrl.isEmpty) {
        continue;
      }
      coverImageId = currentId;
      coverImageUrl = currentUrl;
      break;
    }
    if (coverImageId == null && coverImageUrl.isEmpty) {
      return null;
    }
    return PickedUploadFile(
      id: 'visa_cover_${coverImageId ?? coverImageUrl.hashCode}',
      name: coverImageUrl.isEmpty
          ? '签证编辑.封面图'.tr()
          : _displayNameFromUrl(coverImageUrl),
      path: coverImageUrl,
      sourceType: UploadSourceType.gallery,
      state: UploadItemState.success,
      isImage: true,
      progress: 1,
      uploadedFileId: coverImageId,
      uploadedFileUrl: coverImageUrl.isEmpty ? null : coverImageUrl,
      sizeLabel: null,
    );
  }

  EditVisaPackageTierViewDraft _createTierDraftFromModel(
    VisaPackageEditTierVO tier, {
    required bool deletable,
  }) {
    final List<EditVisaPackageMaterialViewDraft> materials = tier.materials
        .map(_createMaterialDraftFromModel)
        .toList();
    return EditVisaPackageTierViewDraft(
      tierId: tier.tierId,
      nameController: TextEditingController(text: tier.name),
      priceController: TextEditingController(text: _formatPrice(tier.price)),
      descriptionController: TextEditingController(text: tier.description),
      showMaterials: tier.showMaterials,
      selectedServiceTagCodes: tier.services.toSet(),
      customServices: List<String>.from(tier.customServices),
      materials: materials,
      deletable: deletable,
    );
  }

  String _formatPrice(double value) {
    final bool isInteger = value == value.roundToDouble();
    return isInteger
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '服务详情.套餐详情加载失败'.tr() : message;
  }

  void _replaceTiers(List<EditVisaPackageTierViewDraft> nextTiers) {
    for (final EditVisaPackageTierViewDraft tier in _tiers) {
      tier.dispose();
    }
    _tiers
      ..clear()
      ..addAll(nextTiers);
  }

  Future<void> _loadPackageDetail() async {
    final int? packageId = widget.packageId;
    if (packageId == null) {
      return;
    }
    setState(() {
      _isLoadingPackageDetail = true;
      _packageDetailError = null;
    });
    try {
      final VisaPackageEditVO detail = await ref
          .read(visaPackageServiceProvider)
          .getPackageEditDetail(packageId: packageId);
      if (!mounted) {
        return;
      }
      _serviceNameController.text = detail.name;
      _durationController.text = detail.estimatedDays > 0
          ? '${detail.estimatedDays}'
          : '';
      final PickedUploadFile? coverImage = _buildExistingCoverImage(detail);
      final List<EditVisaPackageTierViewDraft> tiers = detail.tiers.isEmpty
          ? <EditVisaPackageTierViewDraft>[_createTierDraft()]
          : detail.tiers
                .asMap()
                .entries
                .map((MapEntry<int, VisaPackageEditTierVO> entry) {
                  return _createTierDraftFromModel(
                    entry.value,
                    deletable: detail.tiers.length > 1 && entry.key > 0,
                  );
                })
                .toList(growable: false);
      _replaceTiers(tiers);
      final EditVisaPackageController controller = ref.read(
        editVisaPackageControllerProvider.notifier,
      );
      controller.setCountryCode(detail.targetCountry);
      controller.setVisaTypeCode(detail.visaType);
      controller.setCurrency(AppCurrency.fromApiValue(detail.currency));
      setState(() {
        _coverImage = coverImage;
        _isLoadingPackageDetail = false;
        _initialSnapshot = _buildCurrentSnapshot();
        _hasInitialSnapshot = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPackageDetail = false;
        _packageDetailError = _normalizeError(error);
      });
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _durationController.dispose();
    for (final EditVisaPackageTierViewDraft tier in _tiers) {
      tier.dispose();
    }
    super.dispose();
  }

  /// 打开服务国家选择面板，并在用户确认后回写国家编码。
  Future<void> _openCountrySheet() async {
    final EditVisaPackageState state = ref.read(
      editVisaPackageControllerProvider,
    );
    final result = await showCountryOptionsBottomSheet(
      context: context,
      ref: ref,
      title: '签证编辑.服务国家'.tr(),
      initialSelectedValues: state.selectedCountryCode == null
          ? const <String>[]
          : <String>[state.selectedCountryCode!],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }
    ref
        .read(editVisaPackageControllerProvider.notifier)
        .setCountryCode(result.first.countryCode.trim());
  }

  /// 打开签证类型选择面板，并处理字典加载失败与空数据提示。
  Future<void> _openVisaTypeSheet() async {
    final EditVisaPackageState state = ref.read(
      editVisaPackageControllerProvider,
    );
    final List<SelectableSheetOption<String>> visaTypeOptions;
    try {
      final List<TagItemVO> tags = await ref.read(
        tagDictionaryProvider(TagCategory.visaType).future,
      );
      visaTypeOptions = _buildVisaTypeOptions(tags);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('签证编辑.签证类型字典加载失败'.tr());
      return;
    }
    if (visaTypeOptions.isEmpty) {
      _showToast('签证编辑.暂无可选签证类型'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '签证编辑.签证类型'.tr(),
      options: visaTypeOptions,
      initialSelectedValues: state.selectedVisaTypeCode == null
          ? const <String>[]
          : <String>[state.selectedVisaTypeCode!],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }
    ref
        .read(editVisaPackageControllerProvider.notifier)
        .setVisaTypeCode(result.first);
  }

  Future<void> _openCurrencySheet() async {
    final EditVisaPackageState state = ref.read(
      editVisaPackageControllerProvider,
    );
    final AppCurrency? result = await showAppCurrencyOptionsBottomSheet(
      context: context,
      initialValue: state.selectedCurrency,
      title: '通用.选择货币'.tr(),
    );
    if (result == null) {
      return;
    }
    ref.read(editVisaPackageControllerProvider.notifier).setCurrency(result);
  }

  Future<void> _handleCoverUploadTap() async {
    FocusScope.of(context).unfocus();
    await _pickCoverFromGallery();
  }

  Future<void> _pickCoverFromGallery() async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromGallery();
      if (pickedFiles.isEmpty) {
        return;
      }
      final PickedUploadFile selectedFile = pickedFiles.first;
      final CroppedFile? croppedFile = await _cropCoverImage(selectedFile.path);
      if (!mounted || croppedFile == null) {
        return;
      }

      final int croppedSize = UploadPickerUtils.readFileSize(croppedFile.path);
      final PickedUploadFile uploadingCover = selectedFile.copyWith(
        path: croppedFile.path,
        name: UploadPickerUtils.basename(croppedFile.path),
        state: UploadItemState.uploading,
        progress: 0,
        sizeLabel: croppedSize > 0
            ? UploadPickerUtils.formatFileSize(croppedSize)
            : null,
        errorMessage: null,
        uploadedFileId: null,
        uploadedFileUrl: null,
      );

      setState(() {
        _coverImage = uploadingCover;
      });
      await _uploadCoverImage(uploadingCover);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('上传.打开相册失败'.tr());
    }
  }

  Future<CroppedFile?> _cropCoverImage(String path) {
    return ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '签证编辑.裁剪封面'.tr(),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: '签证编辑.裁剪封面'.tr(),
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
  }

  Future<void> _uploadCoverImage(PickedUploadFile file) async {
    final fileService = ref.read(fileServiceProvider);
    try {
      final uploaded = await fileService.uploadFile(
        path: file.path,
        scene: FileScene.packageCover,
        errorMessage: '签证编辑.封面上传失败'.tr(),
        onSendProgress: (int sent, int total) {
          if (!mounted || total <= 0 || _coverImage?.id != file.id) {
            return;
          }
          final double progress = (sent / total).clamp(0, 1).toDouble();
          _updateCoverImage(
            (PickedUploadFile current) => current.copyWith(
              state: UploadItemState.uploading,
              progress: progress,
              errorMessage: null,
            ),
          );
        },
      );
      if (!mounted || _coverImage?.id != file.id) {
        return;
      }
      _updateCoverImage(
        (PickedUploadFile current) => current.copyWith(
          state: UploadItemState.success,
          progress: 1,
          errorMessage: null,
          uploadedFileId: uploaded.fileId,
          uploadedFileUrl: uploaded.fileUrl,
        ),
      );
    } catch (error) {
      if (!mounted || _coverImage?.id != file.id) {
        return;
      }
      _updateCoverImage(
        (PickedUploadFile current) => current.copyWith(
          state: UploadItemState.failure,
          progress: 0,
          errorMessage: _resolveUploadErrorMessage(
            error,
            fallback: '签证编辑.封面上传失败'.tr(),
          ),
          uploadedFileId: null,
          uploadedFileUrl: null,
        ),
      );
    }
  }

  void _updateCoverImage(
    PickedUploadFile Function(PickedUploadFile current) update,
  ) {
    final PickedUploadFile? currentCover = _coverImage;
    if (currentCover == null) {
      return;
    }
    setState(() {
      if (_coverImage != null) {
        _coverImage = update(_coverImage!);
      }
    });
  }

  void _handleDeleteCover() {
    setState(() {
      _coverImage = null;
    });
  }

  List<SelectableSheetOption<String>> _buildVisaTypeOptions(
    List<TagItemVO> tags,
  ) {
    return tags
        .map((TagItemVO item) {
          final String code = item.tagCode.trim();
          final String label = item.tagNameZh.trim().isNotEmpty
              ? item.tagNameZh.trim()
              : code;
          return SelectableSheetOption<String>(value: code, label: label);
        })
        .toList(growable: false);
  }

  List<SelectableSheetOption<String>> _buildMaterialTypeOptions(
    List<TagItemVO> tags,
  ) {
    return tags
        .map((TagItemVO item) {
          final String label = item.tagNameZh.trim().isNotEmpty
              ? item.tagNameZh.trim()
              : item.tagCode.trim();
          return SelectableSheetOption<String>(value: label, label: label);
        })
        .toList(growable: false);
  }

  /// 打开材料类型选择面板，并把选择结果写回当前材料项。
  Future<void> _openMaterialTypeSheet(int tierIndex, int materialIndex) async {
    final String currentValue = _tiers[tierIndex]
        .materials[materialIndex]
        .titleController
        .text
        .trim();
    final List<SelectableSheetOption<String>> materialTypeOptions;
    try {
      final List<TagItemVO> tags = await ref.read(
        tagDictionaryProvider(TagCategory.materialType).future,
      );
      materialTypeOptions = _buildMaterialTypeOptions(tags);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('签证编辑.材料类型字典加载失败'.tr());
      return;
    }
    if (materialTypeOptions.isEmpty) {
      _showToast('签证编辑.暂无可选材料类型'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '签证编辑.材料类型'.tr(),
      options: materialTypeOptions,
      initialSelectedValues: currentValue.isEmpty
          ? const <String>[]
          : <String>[currentValue],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }
    setState(() {
      _tiers[tierIndex].materials[materialIndex].titleController.text =
          result.first;
    });
  }

  String? _findLabel(
    List<SelectableSheetOption<String>> options,
    String? selectedValue,
  ) {
    if (selectedValue == null || selectedValue.isEmpty) {
      return null;
    }
    for (final SelectableSheetOption<String> option in options) {
      if (option.value == selectedValue) {
        return option.label;
      }
    }
    return null;
  }

  /// 从页面控制器和档位草稿构建提交所需的表单草稿。
  EditVisaPackageFormDraft _buildFormDraft() {
    final EditVisaPackageState state = ref.read(editVisaPackageControllerProvider);
    return EditVisaPackageFormDraft(
      name: _serviceNameController.text,
      estimatedDays: _durationController.text,
      currency: state.selectedCurrency,
      coverImageIds: _collectCoverImageIds(),
      coverImages: _collectCoverImages(),
      tiers: _tiers
          .map((EditVisaPackageTierViewDraft tier) {
            return EditVisaPackageTierDraftInput(
              tierId: tier.tierId,
              name: tier.nameController.text,
              price: tier.priceController.text,
              description: tier.descriptionController.text,
              showMaterials: tier.showMaterials,
              selectedServiceTagCodes: tier.selectedServiceTagCodes.toList(
                growable: false,
              ),
              customServices: List<String>.from(tier.customServices),
              materials: tier.materials
                  .map((EditVisaPackageMaterialViewDraft material) {
                    return EditVisaPackageMaterialDraftInput(
                      name: material.titleController.text,
                      description: material.descriptionController.text,
                      isRequired: material.isRequired,
                      exampleFileIds: _collectExampleFileIds(material),
                    );
                  })
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  List<int> _collectCoverImageIds() {
    final PickedUploadFile? coverImage = _coverImage;
    if (coverImage == null || coverImage.state != UploadItemState.success) {
      return const <int>[];
    }
    final int? uploadedFileId = coverImage.uploadedFileId;
    if (uploadedFileId == null || uploadedFileId <= 0) {
      return const <int>[];
    }
    return <int>[uploadedFileId];
  }

  List<String> _collectCoverImages() {
    final PickedUploadFile? coverImage = _coverImage;
    if (coverImage == null || coverImage.state != UploadItemState.success) {
      return const <String>[];
    }
    final String resolvedUrl = (coverImage.uploadedFileUrl ?? coverImage.path)
        .trim();
    if (resolvedUrl.isEmpty) {
      return const <String>[];
    }
    return <String>[resolvedUrl];
  }

  List<int> _collectExampleFileIds(EditVisaPackageMaterialViewDraft material) {
    final Set<int> fileIds = <int>{
      ...material.existingExampleFileIds,
      ...material.exampleFiles
          .where(
            (PickedUploadFile file) => file.state == UploadItemState.success,
          )
          .map((PickedUploadFile file) => file.uploadedFileId)
          .whereType<int>(),
    };
    return fileIds.toList(growable: false);
  }

  bool _ensureExampleFilesUploaded() {
    for (int tierIndex = 0; tierIndex < _tiers.length; tierIndex++) {
      final EditVisaPackageTierViewDraft tier = _tiers[tierIndex];
      for (
        int materialIndex = 0;
        materialIndex < tier.materials.length;
        materialIndex++
      ) {
        final EditVisaPackageMaterialViewDraft material =
            tier.materials[materialIndex];
        final bool hasPendingFiles = material.exampleFiles.any(
          (PickedUploadFile file) => file.state != UploadItemState.success,
        );
        if (hasPendingFiles) {
          _showToast(
            '签证编辑.请等待示例文件上传完成'.tr(
              namedArgs: <String, String>{
                'tierIndex': (tierIndex + 1).toString(),
                'materialIndex': (materialIndex + 1).toString(),
              },
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  bool _ensureCoverUploaded() {
    final PickedUploadFile? coverImage = _coverImage;
    if (coverImage == null) {
      return true;
    }
    switch (coverImage.state) {
      case UploadItemState.success:
        return true;
      case UploadItemState.uploading:
        _showToast('签证编辑.请等待封面上传完成'.tr());
        return false;
      case UploadItemState.failure:
        _showToast('签证编辑.请重新上传封面'.tr());
        return false;
    }
  }

  void _showToast(String message) {
    AppToast.show(message);
  }

  Future<void> _handleSaveDraft() async {
    FocusScope.of(context).unfocus();
    if (!_ensureCoverUploaded()) {
      return;
    }
    if (!_ensureExampleFilesUploaded()) {
      return;
    }
    await ref
        .read(editVisaPackageControllerProvider.notifier)
        .saveDraft(_buildFormDraft(), packageId: widget.packageId);
  }

  Future<void> _handlePublish() async {
    FocusScope.of(context).unfocus();
    if (!_ensureCoverUploaded()) {
      return;
    }
    if (!_ensureExampleFilesUploaded()) {
      return;
    }
    await ref
        .read(editVisaPackageControllerProvider.notifier)
        .publish(_buildFormDraft(), packageId: widget.packageId);
  }

  void _handleAddTier() {
    setState(() {
      _tiers.add(_createTierDraft(deletable: true));
    });
  }

  void _handleDeleteTier(int index) {
    if (_tiers.length <= 1) {
      return;
    }
    final EditVisaPackageTierViewDraft draft = _tiers.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _handleAddMaterial(int tierIndex) {
    setState(() {
      _tiers[tierIndex].materials.add(_createMaterialDraft());
    });
  }

  void _handleToggleServiceTag(int tierIndex, String tagCode) {
    setState(() {
      final Set<String> selected = _tiers[tierIndex].selectedServiceTagCodes;
      if (selected.contains(tagCode)) {
        selected.remove(tagCode);
      } else {
        selected.add(tagCode);
      }
    });
  }

  Future<void> _handleAddCustomService(int tierIndex) async {
    final String? result = await showEditVisaPackageCustomServiceDialog(
      context,
    );
    if (result == null) {
      return;
    }
    final String customService = result.trim();
    if (customService.isEmpty) {
      _showToast('签证编辑.请输入自定义服务'.tr());
      return;
    }
    if (_tiers[tierIndex].customServices.contains(customService)) {
      _showToast('签证编辑.该自定义服务已添加'.tr());
      return;
    }
    setState(() {
      _tiers[tierIndex].customServices.add(customService);
    });
  }

  void _handleRemoveCustomService(int tierIndex, String tag) {
    setState(() {
      _tiers[tierIndex].customServices.remove(tag);
    });
  }

  void _handleShowMaterialsChanged(int tierIndex, bool value) {
    setState(() {
      _tiers[tierIndex].showMaterials = value;
      if (value && _tiers[tierIndex].materials.isEmpty) {
        _tiers[tierIndex].materials.add(_createMaterialDraft());
      }
    });
  }

  void _handleMaterialRequiredChanged(
    int tierIndex,
    int materialIndex,
    bool value,
  ) {
    setState(() {
      _tiers[tierIndex].materials[materialIndex].isRequired = value;
    });
  }

  Future<void> _openExampleUploadSheet(int tierIndex, int materialIndex) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        return _VisaPackageUploadTypeBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickExampleFilesFromCamera(tierIndex, materialIndex);
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickExampleFilesFromGallery(tierIndex, materialIndex);
          },
          onFileTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickExampleFilesFromFiles(tierIndex, materialIndex);
          },
        );
      },
    );
  }

  Future<void> _pickExampleFilesFromCamera(
    int tierIndex,
    int materialIndex,
  ) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromCamera();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendExampleFiles(tierIndex, materialIndex, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('上传.打开相机失败'.tr());
    }
  }

  Future<void> _pickExampleFilesFromGallery(
    int tierIndex,
    int materialIndex,
  ) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromGallery();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendExampleFiles(tierIndex, materialIndex, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('上传.打开相册失败'.tr());
    }
  }

  Future<void> _pickExampleFilesFromFiles(
    int tierIndex,
    int materialIndex,
  ) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromFiles();
      if (pickedFiles.isEmpty) {
        _showToast('订单.未能读取所选文件'.tr());
        return;
      }
      await _appendExampleFiles(tierIndex, materialIndex, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast('订单.选择文件失败'.tr());
    }
  }

  Future<void> _appendExampleFiles(
    int tierIndex,
    int materialIndex,
    List<PickedUploadFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }
    final List<PickedUploadFile> pendingFiles = files
        .map(
          (PickedUploadFile file) => file.copyWith(
            state: UploadItemState.uploading,
            progress: 0,
            errorMessage: null,
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        )
        .toList(growable: false);
    setState(() {
      _tiers[tierIndex].materials[materialIndex].exampleFiles =
          <PickedUploadFile>[
            ..._tiers[tierIndex].materials[materialIndex].exampleFiles,
            ...pendingFiles,
          ];
    });
    await _uploadPickedExampleFiles(tierIndex, materialIndex, pendingFiles);
  }

  Future<void> _uploadPickedExampleFiles(
    int tierIndex,
    int materialIndex,
    List<PickedUploadFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }
    final fileService = ref.read(fileServiceProvider);
    for (final PickedUploadFile file in files) {
      try {
        final uploaded = await fileService.uploadFile(
          path: file.path,
          scene: FileScene.material,
          errorMessage: '签证编辑.示例文件上传失败'.tr(),
          onSendProgress: (int sent, int total) {
            if (!mounted || total <= 0) {
              return;
            }
            final double progress = (sent / total).clamp(0, 1).toDouble();
            _updateExampleFile(
              tierIndex,
              materialIndex,
              file.id,
              (PickedUploadFile current) => current.copyWith(
                state: UploadItemState.uploading,
                progress: progress,
                errorMessage: null,
              ),
            );
          },
        );
        if (!mounted) {
          return;
        }
        _updateExampleFile(
          tierIndex,
          materialIndex,
          file.id,
          (PickedUploadFile current) => current.copyWith(
            state: UploadItemState.success,
            progress: 1,
            errorMessage: null,
            uploadedFileId: uploaded.fileId,
            uploadedFileUrl: uploaded.fileUrl,
          ),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        _updateExampleFile(
          tierIndex,
          materialIndex,
          file.id,
          (PickedUploadFile current) => current.copyWith(
            state: UploadItemState.failure,
            progress: 0,
            errorMessage: _resolveUploadErrorMessage(
              error,
              fallback: '订单.上传失败请重试'.tr(),
            ),
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        );
      }
    }
  }

  void _updateExampleFile(
    int tierIndex,
    int materialIndex,
    String fileId,
    PickedUploadFile Function(PickedUploadFile current) update,
  ) {
    setState(() {
      _tiers[tierIndex].materials[materialIndex].exampleFiles =
          _tiers[tierIndex].materials[materialIndex].exampleFiles
              .map((PickedUploadFile item) {
                if (item.id != fileId) {
                  return item;
                }
                return update(item);
              })
              .toList(growable: false);
    });
  }

  void _handleDeleteExampleFile(
    int tierIndex,
    int materialIndex,
    PickedUploadFile file,
  ) {
    setState(() {
      final EditVisaPackageMaterialViewDraft material =
          _tiers[tierIndex].materials[materialIndex];
      material.exampleFiles = material.exampleFiles
          .where((PickedUploadFile item) => item.id != file.id)
          .toList(growable: false);
      final int? uploadedFileId = file.uploadedFileId;
      if (uploadedFileId != null) {
        material.existingExampleFileIds = material.existingExampleFileIds
            .where((int item) => item != uploadedFileId)
            .toList(growable: false);
      }
    });
  }

  String _resolveUploadErrorMessage(Object error, {required String fallback}) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      final String normalized = message.substring('Exception: '.length).trim();
      return normalized.isEmpty ? fallback : normalized;
    }
    return message.isEmpty ? fallback : message;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EditVisaPackageState>(editVisaPackageControllerProvider, (
      EditVisaPackageState? previous,
      EditVisaPackageState next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showToast(next.feedbackMessage!);
        ref.read(editVisaPackageControllerProvider.notifier).clearFeedback();
      }

      if (previous?.submitSuccessId != next.submitSuccessId &&
          next.submitSuccessId > 0) {
        _markSavedSnapshot();
        scheduleDirectPop(
          result: true,
          onCannotPop: () => context.go(RoutePaths.jobs),
        );
      }
    });

    final EditVisaPackageState state = ref.watch(
      editVisaPackageControllerProvider,
    );
    final EditVisaPackageController controller = ref.read(
      editVisaPackageControllerProvider.notifier,
    );
    final List<SelectableSheetOption<String>> visaTypeOptions = ref
        .watch(tagDictionaryProvider(TagCategory.visaType))
        .maybeWhen(
          data: _buildVisaTypeOptions,
          orElse: () => const <SelectableSheetOption<String>>[],
        );
    final Map<String, String> countryLabelMap = ref
        .watch(countrySearchProvider(const CountrySearchQuery()))
        .maybeWhen(
          data: (result) => buildCountryLabelMap(result.list),
          orElse: () => const <String, String>{},
        );
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    if (_isEditMode && _isLoadingPackageDetail) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_isEditMode && _packageDetailError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '服务详情.套餐详情加载失败'.tr(),
                  style: TestStyle.pingFangMedium(fontSize: 16, color: Color(0xFF262626)),
                ),
                const SizedBox(height: 8),
                Text(
                  _packageDetailError!,
                  textAlign: TextAlign.center,
                  style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadPackageDetail,
                  child: Text('通用.重试'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return buildGuardedPopScope(
      onInterceptPop: _handleAttemptLeave,
      child: EditVisaPackagePageView(
        bottomPadding: mediaQuery.padding.bottom,
        serviceNameController: _serviceNameController,
        durationController: _durationController,
        coverImage: _coverImage,
        selectedCountryLabel: state.selectedCountryCode == null
            ? null
            : resolveCountryLabel(state.selectedCountryCode!, countryLabelMap),
        selectedVisaTypeLabel: _findLabel(
          visaTypeOptions,
          state.selectedVisaTypeCode,
        ),
        selectedCurrencyLabel: state.selectedCurrency.labelKey.tr(),
        state: state,
        tiers: _tiers,
        // 统一走页面级离开判断，避免头部返回绕过未保存拦截。
        onBackTap: () {
          _handleAttemptLeave();
        },
        onSaveDraftTap: _handleSaveDraft,
        onPublishTap: _handlePublish,
        onCoverUploadTap: _handleCoverUploadTap,
        onDeleteCoverTap: _handleDeleteCover,
        onCountryTap: _openCountrySheet,
        onVisaTypeTap: _openVisaTypeSheet,
        onCurrencyTap: _openCurrencySheet,
        onRetryLoadServiceTags: () => controller.loadServiceTags(force: true),
        onAddTier: _handleAddTier,
        onDeleteTier: _handleDeleteTier,
        onAddMaterial: _handleAddMaterial,
        onAddCustomService: _handleAddCustomService,
        onRemoveCustomService: _handleRemoveCustomService,
        onToggleServiceTag: _handleToggleServiceTag,
        onShowMaterialsChanged: _handleShowMaterialsChanged,
        onMaterialRequiredChanged: _handleMaterialRequiredChanged,
        onMaterialTypeTap: _openMaterialTypeSheet,
        onExampleUploadTap: _openExampleUploadSheet,
        onDeleteExampleFile: _handleDeleteExampleFile,
        tagLabelBuilder: controller.tagLabel,
      ),
    );
  }
}

class _EditVisaPackageSnapshot {
  const _EditVisaPackageSnapshot({
    required this.serviceName,
    required this.duration,
    required this.countryCode,
    required this.visaTypeCode,
    required this.currency,
    required this.coverImageId,
    required this.tiers,
  });

  final String serviceName;
  final String duration;
  final String? countryCode;
  final String? visaTypeCode;
  final String currency;
  final String coverImageId;
  final List<_EditVisaPackageTierSnapshot> tiers;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EditVisaPackageSnapshot &&
            serviceName == other.serviceName &&
            duration == other.duration &&
            countryCode == other.countryCode &&
            visaTypeCode == other.visaTypeCode &&
            currency == other.currency &&
            coverImageId == other.coverImageId &&
            listEquals(tiers, other.tiers);
  }

  @override
  int get hashCode => Object.hash(
        serviceName,
        duration,
        countryCode,
        visaTypeCode,
        currency,
        coverImageId,
        Object.hashAll(tiers),
      );
}

class _EditVisaPackageTierSnapshot {
  const _EditVisaPackageTierSnapshot({
    required this.tierId,
    required this.name,
    required this.price,
    required this.description,
    required this.showMaterials,
    required this.selectedServiceTagCodes,
    required this.customServices,
    required this.materials,
  });

  final int tierId;
  final String name;
  final String price;
  final String description;
  final bool showMaterials;
  final List<String> selectedServiceTagCodes;
  final List<String> customServices;
  final List<_EditVisaPackageMaterialSnapshot> materials;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EditVisaPackageTierSnapshot &&
            tierId == other.tierId &&
            name == other.name &&
            price == other.price &&
            description == other.description &&
            showMaterials == other.showMaterials &&
            listEquals(
              selectedServiceTagCodes,
              other.selectedServiceTagCodes,
            ) &&
            listEquals(customServices, other.customServices) &&
            listEquals(materials, other.materials);
  }

  @override
  int get hashCode => Object.hash(
        tierId,
        name,
        price,
        description,
        showMaterials,
        Object.hashAll(selectedServiceTagCodes),
        Object.hashAll(customServices),
        Object.hashAll(materials),
      );
}

class _EditVisaPackageMaterialSnapshot {
  const _EditVisaPackageMaterialSnapshot({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.exampleFileIds,
  });

  final String name;
  final String description;
  final bool isRequired;
  final List<int> exampleFileIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EditVisaPackageMaterialSnapshot &&
            name == other.name &&
            description == other.description &&
            isRequired == other.isRequired &&
            listEquals(exampleFileIds, other.exampleFileIds);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        isRequired,
        Object.hashAll(exampleFileIds),
      );
}

class _VisaPackageUploadTypeBottomSheet extends StatelessWidget {
  const _VisaPackageUploadTypeBottomSheet({
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
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: bottomSafeArea),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 52,
                  child: Row(
                    children: <Widget>[
                      const SizedBox(width: 40),
                      const Spacer(),
                      Text(
                        '签证编辑.上传示例文件'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF171A1D),
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              height: 25 / 17,
                            ),
                      ),
                      const Spacer(),
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
                  padding: const EdgeInsets.fromLTRB(36.75, 24, 36.75, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _VisaPackageUploadTypeAction(
                        label: '订单.拍照上传'.tr(),
                        iconAssetPath:
                            'assets/images/order_upload_sheet_camera.svg',
                        onTap: onCameraTap,
                      ),
                      _VisaPackageUploadTypeAction(
                        label: '订单.本地相册'.tr(),
                        iconAssetPath:
                            'assets/images/order_upload_sheet_gallery.svg',
                        onTap: onGalleryTap,
                      ),
                      _VisaPackageUploadTypeAction(
                        label: '订单.本地文件'.tr(),
                        iconAssetPath:
                            'assets/images/order_upload_sheet_file.svg',
                        onTap: onFileTap,
                      ),
                    ],
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

class _VisaPackageUploadTypeAction extends StatelessWidget {
  const _VisaPackageUploadTypeAction({
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAssetPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TestStyle.regular(fontSize: 13, color: const Color(0xFF595959)),
            ),
          ],
        ),
      ),
    );
  }
}
