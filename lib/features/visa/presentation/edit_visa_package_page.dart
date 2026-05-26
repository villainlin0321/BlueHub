import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
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

class EditVisaPackagePage extends ConsumerStatefulWidget {
  const EditVisaPackagePage({super.key, this.packageId});

  final int? packageId;

  @override
  ConsumerState<EditVisaPackagePage> createState() =>
      _EditVisaPackagePageState();
}

class _EditVisaPackagePageState extends ConsumerState<EditVisaPackagePage> {
  late final TextEditingController _serviceNameController;
  late final TextEditingController _durationController;
  late final List<EditVisaPackageTierViewDraft> _tiers;
  bool _isLoadingPackageDetail = false;
  String? _packageDetailError;

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
      }
    });
  }

  EditVisaPackageTierViewDraft _createTierDraft({
    int tierId = 0,
    bool deletable = false,
  }) {
    return EditVisaPackageTierViewDraft(
      tierId: tierId,
      nameController: TextEditingController(text: '基础套餐'),
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
    );
  }

  EditVisaPackageMaterialViewDraft _createMaterialDraftFromModel(
    MaterialBO material,
  ) {
    return EditVisaPackageMaterialViewDraft(
      titleController: TextEditingController(text: material.name),
      descriptionController: TextEditingController(text: material.description),
      isRequired: material.isRequired,
    );
  }

  EditVisaPackageTierViewDraft _createTierDraftFromModel(
    TierVO tier, {
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
    return message.isEmpty ? '套餐详情加载失败，请稍后重试' : message;
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
      final VisaPackageVO detail = await ref
          .read(visaPackageServiceProvider)
          .getPackageDetail(packageId: packageId);
      if (!mounted) {
        return;
      }
      _serviceNameController.text = detail.name;
      _durationController.text = detail.estimatedDays > 0
          ? '${detail.estimatedDays}'
          : '';
      final List<EditVisaPackageTierViewDraft> tiers = detail.tiers.isEmpty
          ? <EditVisaPackageTierViewDraft>[_createTierDraft()]
          : detail.tiers.asMap().entries.map((
              MapEntry<int, TierVO> entry,
            ) {
              return _createTierDraftFromModel(
                entry.value,
                deletable: detail.tiers.length > 1 && entry.key > 0,
              );
            }).toList(growable: false);
      _replaceTiers(tiers);
      final EditVisaPackageController controller = ref.read(
        editVisaPackageControllerProvider.notifier,
      );
      controller.setCountryCode(detail.targetCountry);
      controller.setVisaTypeCode(detail.visaType);
      setState(() {
        _isLoadingPackageDetail = false;
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

  Future<void> _openCountrySheet() async {
    final EditVisaPackageState state = ref.read(
      editVisaPackageControllerProvider,
    );
    final result = await showCountryOptionsBottomSheet(
      context: context,
      ref: ref,
      title: '服务国家',
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
      _showSnackBar('签证类型字典加载失败');
      return;
    }
    if (visaTypeOptions.isEmpty) {
      _showSnackBar('暂无可选签证类型');
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '签证类型',
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

  List<SelectableSheetOption<String>> _buildVisaTypeOptions(
    List<TagItemVO> tags,
  ) {
    return tags.map((TagItemVO item) {
      final String code = item.tagCode.trim();
      final String label = item.tagNameZh.trim().isNotEmpty
          ? item.tagNameZh.trim()
          : code;
      return SelectableSheetOption<String>(value: code, label: label);
    }).toList(growable: false);
  }

  List<SelectableSheetOption<String>> _buildMaterialTypeOptions(
    List<TagItemVO> tags,
  ) {
    return tags.map((TagItemVO item) {
      final String label = item.tagNameZh.trim().isNotEmpty
          ? item.tagNameZh.trim()
          : item.tagCode.trim();
      return SelectableSheetOption<String>(value: label, label: label);
    }).toList(growable: false);
  }

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
      _showSnackBar('材料类型字典加载失败');
      return;
    }
    if (materialTypeOptions.isEmpty) {
      _showSnackBar('暂无可选材料类型');
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '材料类型',
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

  EditVisaPackageFormDraft _buildFormDraft() {
    return EditVisaPackageFormDraft(
      name: _serviceNameController.text,
      estimatedDays: _durationController.text,
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
          materials: tier.materials.map((EditVisaPackageMaterialViewDraft material) {
            return EditVisaPackageMaterialDraftInput(
              name: material.titleController.text,
              description: material.descriptionController.text,
              isRequired: material.isRequired,);
                  })
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSaveDraft() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(editVisaPackageControllerProvider.notifier)
        .saveDraft(_buildFormDraft(), packageId: widget.packageId);
  }

  Future<void> _handlePublish() async {
    FocusScope.of(context).unfocus();
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
      _showSnackBar('请输入自定义服务');
      return;
    }
    if (_tiers[tierIndex].customServices.contains(customService)) {
      _showSnackBar('该自定义服务已添加');
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

  @override
  Widget build(BuildContext context) {
    ref.listen<EditVisaPackageState>(editVisaPackageControllerProvider, (
      EditVisaPackageState? previous,
      EditVisaPackageState next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showSnackBar(next.feedbackMessage!);
        ref.read(editVisaPackageControllerProvider.notifier).clearFeedback();
      }

      if (previous?.submitSuccessId != next.submitSuccessId &&
          next.submitSuccessId > 0) {
        if (Navigator.of(context).canPop()) {
          context.pop(true);
        } else {
          context.go(RoutePaths.jobs);
        }
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
                const Text(
                  '套餐详情加载失败',
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _packageDetailError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadPackageDetail,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return EditVisaPackagePageView(
      topPadding: mediaQuery.padding.top,
      bottomPadding: mediaQuery.padding.bottom,
      serviceNameController: _serviceNameController,
      durationController: _durationController,
      selectedCountryLabel: state.selectedCountryCode == null
          ? null
          : resolveCountryLabel(state.selectedCountryCode!, countryLabelMap),
      selectedVisaTypeLabel: _findLabel(
        visaTypeOptions,
        state.selectedVisaTypeCode,
      ),
      state: state,
      tiers: _tiers,
      onBackTap: () => Navigator.of(context).maybePop(),
      onSaveDraftTap: _handleSaveDraft,
      onPublishTap: _handlePublish,
      onCountryTap: _openCountrySheet,
      onVisaTypeTap: _openVisaTypeSheet,
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
      tagLabelBuilder: controller.tagLabel,
    );
  }
}
