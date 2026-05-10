import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../application/edit_visa_package/edit_visa_package_controller.dart';
import '../application/edit_visa_package/edit_visa_package_state.dart';
import 'widgets/edit_visa_package_form_widgets.dart';
import 'widgets/edit_visa_package_page_view.dart';

class EditVisaPackagePage extends ConsumerStatefulWidget {
  const EditVisaPackagePage({super.key});

  @override
  ConsumerState<EditVisaPackagePage> createState() =>
      _EditVisaPackagePageState();
}

class _EditVisaPackagePageState extends ConsumerState<EditVisaPackagePage> {
  static const List<SelectableSheetOption<String>> _countryOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: 'DE', label: '德国'),
        SelectableSheetOption<String>(value: 'FR', label: '法国'),
        SelectableSheetOption<String>(value: 'CH', label: '瑞士'),
        SelectableSheetOption<String>(value: 'GB', label: '英国'),
        SelectableSheetOption<String>(value: 'IT', label: '意大利'),
        SelectableSheetOption<String>(value: 'ES', label: '西班牙'),
      ];
  static const List<SelectableSheetOption<String>> _visaTypeOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: 'work', label: '工作'),
        SelectableSheetOption<String>(value: 'travel', label: '旅行'),
        SelectableSheetOption<String>(value: 'tech', label: '技术'),
        SelectableSheetOption<String>(value: 'nursing', label: '护理'),
        SelectableSheetOption<String>(value: 'study', label: '留学'),
      ];
  static const List<SelectableSheetOption<String>> _materialTypeOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(
          value: '护照原件及复印件',
          label: '护照原件及复印件',
        ),
      ];

  late final TextEditingController _serviceNameController;
  late final TextEditingController _durationController;
  late final List<EditVisaPackageTierViewDraft> _tiers;

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
    });
  }

  EditVisaPackageTierViewDraft _createTierDraft({bool deletable = false}) {
    return EditVisaPackageTierViewDraft(
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
    final EditVisaPackageState state = ref.read(editVisaPackageControllerProvider);
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '服务国家',
      options: _countryOptions,
      initialSelectedValues: state.selectedCountryCode == null
          ? const <String>[]
          : <String>[state.selectedCountryCode!],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }
    ref.read(editVisaPackageControllerProvider.notifier).setCountryCode(
      result.first,
    );
  }

  Future<void> _openVisaTypeSheet() async {
    final EditVisaPackageState state = ref.read(editVisaPackageControllerProvider);
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '签证类型',
      options: _visaTypeOptions,
      initialSelectedValues: state.selectedVisaTypeCode == null
          ? const <String>[]
          : <String>[state.selectedVisaTypeCode!],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }
    ref.read(editVisaPackageControllerProvider.notifier).setVisaTypeCode(
      result.first,
    );
  }

  Future<void> _openMaterialTypeSheet(int tierIndex, int materialIndex) async {
    final String currentValue =
        _tiers[tierIndex].materials[materialIndex].titleController.text.trim();
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '材料类型',
      options: _materialTypeOptions,
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
      tiers: _tiers.map((EditVisaPackageTierViewDraft tier) {
        return EditVisaPackageTierDraftInput(
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
              isRequired: material.isRequired,
            );
          }).toList(growable: false),
        );
      }).toList(growable: false),
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
        .saveDraft(_buildFormDraft());
  }

  Future<void> _handlePublish() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(editVisaPackageControllerProvider.notifier)
        .publish(_buildFormDraft());
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
    final String? result = await showEditVisaPackageCustomServiceDialog(context);
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

    final EditVisaPackageState state = ref.watch(editVisaPackageControllerProvider);
    final EditVisaPackageController controller = ref.read(
      editVisaPackageControllerProvider.notifier,
    );
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return EditVisaPackagePageView(
      topPadding: mediaQuery.padding.top,
      bottomPadding: mediaQuery.padding.bottom,
      serviceNameController: _serviceNameController,
      durationController: _durationController,
      selectedCountryLabel: _findLabel(_countryOptions, state.selectedCountryCode),
      selectedVisaTypeLabel: _findLabel(
        _visaTypeOptions,
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
