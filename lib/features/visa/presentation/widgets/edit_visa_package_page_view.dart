import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/data/config_models.dart';
import '../../application/edit_visa_package/edit_visa_package_state.dart';
import '../edit_visa_package_styles.dart';
import 'edit_visa_package_form_widgets.dart';

class EditVisaPackagePageView extends StatelessWidget {
  const EditVisaPackagePageView({
    super.key,
    required this.topPadding,
    required this.bottomPadding,
    required this.serviceNameController,
    required this.durationController,
    required this.selectedCountryLabel,
    required this.selectedVisaTypeLabel,
    required this.state,
    required this.tiers,
    required this.onBackTap,
    required this.onSaveDraftTap,
    required this.onPublishTap,
    required this.onCountryTap,
    required this.onVisaTypeTap,
    required this.onRetryLoadServiceTags,
    required this.onAddTier,
    required this.onDeleteTier,
    required this.onAddMaterial,
    required this.onAddCustomService,
    required this.onRemoveCustomService,
    required this.onToggleServiceTag,
    required this.onShowMaterialsChanged,
    required this.onMaterialRequiredChanged,
    required this.onMaterialTypeTap,
    required this.tagLabelBuilder,
  });

  final double topPadding;
  final double bottomPadding;
  final TextEditingController serviceNameController;
  final TextEditingController durationController;
  final String? selectedCountryLabel;
  final String? selectedVisaTypeLabel;
  final EditVisaPackageState state;
  final List<EditVisaPackageTierViewDraft> tiers;
  final VoidCallback onBackTap;
  final VoidCallback onSaveDraftTap;
  final VoidCallback onPublishTap;
  final VoidCallback onCountryTap;
  final VoidCallback onVisaTypeTap;
  final VoidCallback onRetryLoadServiceTags;
  final VoidCallback onAddTier;
  final ValueChanged<int> onDeleteTier;
  final ValueChanged<int> onAddMaterial;
  final ValueChanged<int> onAddCustomService;
  final void Function(int tierIndex, String tag) onRemoveCustomService;
  final void Function(int tierIndex, String tagCode) onToggleServiceTag;
  final void Function(int tierIndex, bool value) onShowMaterialsChanged;
  final void Function(int tierIndex, int materialIndex, bool value)
      onMaterialRequiredChanged;
  final void Function(int tierIndex, int materialIndex) onMaterialTypeTap;
  final String Function(TagItemVO tag) tagLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EditVisaPackageStyles.pageBackground,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double contentWidth = math.min(
            constraints.maxWidth,
            EditVisaPackageStyles.designWidth,
          );

          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: <Widget>[
                          EditVisaPackageHeader(
                            topPadding: topPadding,
                            onBackTap: onBackTap,
                            onSaveDraftTap: onSaveDraftTap,
                            isSavingDraft: state.isSavingDraft,
                            actionsEnabled:
                                !state.isSavingDraft && !state.isPublishing,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            child: Column(
                              children: <Widget>[
                                _BasicInfoSection(
                                  serviceNameController: serviceNameController,
                                  durationController: durationController,
                                  selectedCountryLabel: selectedCountryLabel,
                                  selectedVisaTypeLabel: selectedVisaTypeLabel,
                                  onCountryTap: onCountryTap,
                                  onVisaTypeTap: onVisaTypeTap,
                                ),
                                const SizedBox(height: 12),
                                _TierConfigSection(
                                  state: state,
                                  tiers: tiers,
                                  onRetryLoadServiceTags: onRetryLoadServiceTags,
                                  onAddTier: onAddTier,
                                  onDeleteTier: onDeleteTier,
                                  onAddMaterial: onAddMaterial,
                                  onAddCustomService: onAddCustomService,
                                  onRemoveCustomService: onRemoveCustomService,
                                  onToggleServiceTag: onToggleServiceTag,
                                  onShowMaterialsChanged: onShowMaterialsChanged,
                                  onMaterialRequiredChanged:
                                      onMaterialRequiredChanged,
                                  onMaterialTypeTap: onMaterialTypeTap,
                                  tagLabelBuilder: tagLabelBuilder,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              EditVisaPackageBottomBar(
                width: contentWidth,
                bottomPadding: bottomPadding,
                onTap: onPublishTap,
                isPublishing: state.isPublishing,
                enabled: !state.isSavingDraft && !state.isPublishing,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({
    required this.serviceNameController,
    required this.durationController,
    required this.selectedCountryLabel,
    required this.selectedVisaTypeLabel,
    required this.onCountryTap,
    required this.onVisaTypeTap,
  });

  final TextEditingController serviceNameController;
  final TextEditingController durationController;
  final String? selectedCountryLabel;
  final String? selectedVisaTypeLabel;
  final VoidCallback onCountryTap;
  final VoidCallback onVisaTypeTap;

  @override
  Widget build(BuildContext context) {
    return EditVisaPackageSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EditVisaPackageSectionTitle(title: '签证编辑.基础信息'.tr()),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '签证编辑.套餐总名称'.tr(),
            required: true,
            child: EditVisaPackageInputField(
              controller: serviceNameController,
              hintText: '签证编辑.套餐总名称示例'.tr(),
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '签证编辑.服务国家'.tr(),
            required: true,
            child: EditVisaPackageSelectorField(
              text: selectedCountryLabel,
              hintText: '通用.请选择'.tr(),
              onTap: onCountryTap,
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '签证编辑.签证类型'.tr(),
            required: true,
            child: EditVisaPackageSelectorField(
              text: selectedVisaTypeLabel,
              hintText: '通用.请选择'.tr(),
              onTap: onVisaTypeTap,
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '签证编辑.预计周期工作日'.tr(),
            required: true,
            child: EditVisaPackageInputField(
              controller: durationController,
              hintText: '签证编辑.预计周期示例'.tr(),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierConfigSection extends StatelessWidget {
  const _TierConfigSection({
    required this.state,
    required this.tiers,
    required this.onRetryLoadServiceTags,
    required this.onAddTier,
    required this.onDeleteTier,
    required this.onAddMaterial,
    required this.onAddCustomService,
    required this.onRemoveCustomService,
    required this.onToggleServiceTag,
    required this.onShowMaterialsChanged,
    required this.onMaterialRequiredChanged,
    required this.onMaterialTypeTap,
    required this.tagLabelBuilder,
  });

  final EditVisaPackageState state;
  final List<EditVisaPackageTierViewDraft> tiers;
  final VoidCallback onRetryLoadServiceTags;
  final VoidCallback onAddTier;
  final ValueChanged<int> onDeleteTier;
  final ValueChanged<int> onAddMaterial;
  final ValueChanged<int> onAddCustomService;
  final void Function(int tierIndex, String tag) onRemoveCustomService;
  final void Function(int tierIndex, String tagCode) onToggleServiceTag;
  final void Function(int tierIndex, bool value) onShowMaterialsChanged;
  final void Function(int tierIndex, int materialIndex, bool value)
      onMaterialRequiredChanged;
  final void Function(int tierIndex, int materialIndex) onMaterialTypeTap;
  final String Function(TagItemVO tag) tagLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return EditVisaPackageSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EditVisaPackageSectionTitle(title: '签证编辑.多档位套餐配置'.tr()),
          const SizedBox(height: 16),
          ...tiers.asMap().entries.map((MapEntry<int, EditVisaPackageTierViewDraft> entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == tiers.length - 1 ? 0 : 24,
              ),
              child: _TierCard(
                tierIndex: entry.key,
                tier: entry.value,
                state: state,
                onRetryLoadServiceTags: onRetryLoadServiceTags,
                onDeleteTier: onDeleteTier,
                onAddMaterial: onAddMaterial,
                onAddCustomService: onAddCustomService,
                onRemoveCustomService: onRemoveCustomService,
                onToggleServiceTag: onToggleServiceTag,
                onShowMaterialsChanged: onShowMaterialsChanged,
                onMaterialRequiredChanged: onMaterialRequiredChanged,
                onMaterialTypeTap: onMaterialTypeTap,
                tagLabelBuilder: tagLabelBuilder,
              ),
            );
          }),
          const SizedBox(height: 20),
          EditVisaPackageSecondaryButton(
            label: '签证编辑.添加套餐档位'.tr(),
            onTap: onAddTier,
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tierIndex,
    required this.tier,
    required this.state,
    required this.onRetryLoadServiceTags,
    required this.onDeleteTier,
    required this.onAddMaterial,
    required this.onAddCustomService,
    required this.onRemoveCustomService,
    required this.onToggleServiceTag,
    required this.onShowMaterialsChanged,
    required this.onMaterialRequiredChanged,
    required this.onMaterialTypeTap,
    required this.tagLabelBuilder,
  });

  final int tierIndex;
  final EditVisaPackageTierViewDraft tier;
  final EditVisaPackageState state;
  final VoidCallback onRetryLoadServiceTags;
  final ValueChanged<int> onDeleteTier;
  final ValueChanged<int> onAddMaterial;
  final ValueChanged<int> onAddCustomService;
  final void Function(int tierIndex, String tag) onRemoveCustomService;
  final void Function(int tierIndex, String tagCode) onToggleServiceTag;
  final void Function(int tierIndex, bool value) onShowMaterialsChanged;
  final void Function(int tierIndex, int materialIndex, bool value)
      onMaterialRequiredChanged;
  final void Function(int tierIndex, int materialIndex) onMaterialTypeTap;
  final String Function(TagItemVO tag) tagLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        EditVisaPackageTierHeader(
          title: '签证编辑.档位套餐'.tr(),
          showDelete: tier.deletable,
          onDeleteTap: tier.deletable ? () => onDeleteTier(tierIndex) : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: EditVisaPackageLabeledField(
                label: '签证编辑.档位名称'.tr(),
                child: EditVisaPackageInputField(
                  controller: tier.nameController,
                  hintText: '通用.请输入'.tr(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EditVisaPackageLabeledField(
                label: '签证编辑.价格元'.tr(),
                child: EditVisaPackageInputField(
                  controller: tier.priceController,
                  hintText: '通用.请输入'.tr(),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('签证编辑.包含服务'.tr(), style: EditVisaPackageStyles.fieldLabel),
        const SizedBox(height: 8),
        EditVisaPackageServiceTagContent(
          serviceTags: state.serviceTags,
          selectedServiceTagCodes: tier.selectedServiceTagCodes,
          isLoadingServiceTags: state.isLoadingServiceTags,
          serviceTagsError: state.serviceTagsError,
          onRetryLoadServiceTags: onRetryLoadServiceTags,
          onServiceTagTap: (String tagCode) => onToggleServiceTag(tierIndex, tagCode),
          tagLabelBuilder: tagLabelBuilder,
          customServices: tier.customServices,
          onAddCustomService: () => onAddCustomService(tierIndex),
          onRemoveCustomService: (String tag) =>
              onRemoveCustomService(tierIndex, tag),
        ),
        const SizedBox(height: 20),
        EditVisaPackageLabeledField(
          label: '签证编辑.套餐描述'.tr(),
          child: EditVisaPackageMultilineField(
            controller: tier.descriptionController,
            hintText: '签证编辑.套餐描述提示'.tr(),
            maxLength: 100,
          ),
        ),
        const SizedBox(height: 20),
        EditVisaPackageRadioGroup(
          value: tier.showMaterials,
          onChanged: (bool value) => onShowMaterialsChanged(tierIndex, value),
        ),
        if (tier.showMaterials) ...<Widget>[
          const SizedBox(height: 20),
          ...tier.materials.asMap().entries.map(
            (MapEntry<int, EditVisaPackageMaterialViewDraft> entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == tier.materials.length - 1 ? 0 : 16,
                ),
                child: _MaterialCard(
                  tierIndex: tierIndex,
                  materialIndex: entry.key,
                  material: entry.value,
                  onMaterialRequiredChanged: onMaterialRequiredChanged,
                  onMaterialTypeTap: onMaterialTypeTap,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          EditVisaPackageAddMaterialButton(
            label: '签证编辑.添加材料'.tr(),
            onTap: () => onAddMaterial(tierIndex),
          ),
        ],
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.tierIndex,
    required this.materialIndex,
    required this.material,
    required this.onMaterialRequiredChanged,
    required this.onMaterialTypeTap,
  });

  final int tierIndex;
  final int materialIndex;
  final EditVisaPackageMaterialViewDraft material;
  final void Function(int tierIndex, int materialIndex, bool value)
      onMaterialRequiredChanged;
  final void Function(int tierIndex, int materialIndex) onMaterialTypeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '签证编辑.材料序号'.tr(
                  namedArgs: <String, String>{
                    'index': (materialIndex + 1).toString(),
                  },
                ),
                style: EditVisaPackageStyles.fieldLabel,
              ),
            ),
            Text(
              material.isRequired ? '签证编辑.必填'.tr() : '通用.选填'.tr(),
              style: EditVisaPackageStyles.materialMeta,
            ),
            const SizedBox(width: 8),
            EditVisaPackageSwitch(
              value: material.isRequired,
              activeColor: EditVisaPackageStyles.primary,
              inactiveColor: EditVisaPackageStyles.border,
              onChanged: (bool value) {
                onMaterialRequiredChanged(tierIndex, materialIndex, value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        EditVisaPackageSelectorField(
          text: material.titleController.text.trim().isEmpty
              ? null
              : material.titleController.text.trim(),
          hintText: '签证编辑.选择材料类型'.tr(),
          onTap: () => onMaterialTypeTap(tierIndex, materialIndex),
        ),
        const SizedBox(height: 12),
        EditVisaPackageInputField(
          controller: material.descriptionController,
          hintText: '签证编辑.请输入材料描述'.tr(),
        ),
      ],
    );
  }
}
