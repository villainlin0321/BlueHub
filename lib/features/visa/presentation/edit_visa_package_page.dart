import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'edit_visa_package_styles.dart';

class EditVisaPackagePage extends StatefulWidget {
  const EditVisaPackagePage({super.key});

  @override
  State<EditVisaPackagePage> createState() => _EditVisaPackagePageState();
}

class _EditVisaPackagePageState extends State<EditVisaPackagePage> {
  late final TextEditingController _serviceNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _visaTypeController;
  late final TextEditingController _durationController;
  late final List<_EditVisaPackageTierDraft> _tiers;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController();
    _countryController = TextEditingController();
    _visaTypeController = TextEditingController();
    _durationController = TextEditingController();
    _tiers = <_EditVisaPackageTierDraft>[
      _createTierDraft(
        serviceItems: const <_EditVisaPackageServiceItem>[
          _EditVisaPackageServiceItem(label: '中餐厨师', selected: true),
          _EditVisaPackageServiceItem(label: '表格填写', selected: true),
          _EditVisaPackageServiceItem(label: '面签陪同'),
          _EditVisaPackageServiceItem(label: '翻译服务'),
          _EditVisaPackageServiceItem(label: '面签辅导'),
          _EditVisaPackageServiceItem(label: '加急处理'),
          _EditVisaPackageServiceItem(label: '拒签退款'),
          _EditVisaPackageServiceItem(label: '自定义', addStyle: true),
        ],
        showMaterials: true,
        materials: <_EditVisaPackageMaterialDraft>[
          _EditVisaPackageMaterialDraft(
            label: '材料1',
            requiredLabel: '必填',
            enabled: true,
            titleController: TextEditingController(text: '护照原件及复印件'),
            descriptionController: TextEditingController(
              text: '有效期需超过预计逗留期至少3个月',
            ),
            titleHint: '选择材料类型',
            descriptionHint: '请输入材料描述（20字以内）',
            trailingAsset: 'assets/images/visa_package_chevron_blue.svg',
          ),
          _EditVisaPackageMaterialDraft(
            label: '材料2',
            requiredLabel: '选填',
            enabled: false,
            titleController: TextEditingController(),
            descriptionController: TextEditingController(),
            titleHint: '选择材料类型',
            descriptionHint: '请输入材料描述（20字以内）',
            trailingAsset: 'assets/images/visa_package_chevron_gray.svg',
          ),
        ],
      ),
      _createTierDraft(
        serviceItems: const <_EditVisaPackageServiceItem>[
          _EditVisaPackageServiceItem(label: '审核材料', selected: true),
          _EditVisaPackageServiceItem(label: '表格填写', selected: true),
          _EditVisaPackageServiceItem(label: '面签陪同'),
          _EditVisaPackageServiceItem(label: '翻译服务'),
          _EditVisaPackageServiceItem(label: '面签辅导'),
          _EditVisaPackageServiceItem(label: '加急处理'),
          _EditVisaPackageServiceItem(label: '拒签退款'),
          _EditVisaPackageServiceItem(label: '自定义', addStyle: true),
        ],
        showMaterials: false,
        materials: <_EditVisaPackageMaterialDraft>[],
        deletable: true,
      ),
    ];
  }

  _EditVisaPackageTierDraft _createTierDraft({
    required List<_EditVisaPackageServiceItem> serviceItems,
    required bool showMaterials,
    required List<_EditVisaPackageMaterialDraft> materials,
    bool deletable = false,
  }) {
    return _EditVisaPackageTierDraft(
      nameController: TextEditingController(text: '基础套餐'),
      priceController: TextEditingController(),
      descriptionController: TextEditingController(),
      showMaterials: showMaterials,
      serviceItems: serviceItems,
      materials: materials,
      deletable: deletable,
    );
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _countryController.dispose();
    _visaTypeController.dispose();
    _durationController.dispose();
    for (final _EditVisaPackageTierDraft tier in _tiers) {
      tier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double topPadding = mediaQuery.padding.top;
    final double bottomPadding = mediaQuery.padding.bottom;

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
                          _EditVisaPackageHeader(
                            topPadding: topPadding,
                            onBackTap: _handleBack,
                            onSaveDraftTap: _handleSaveDraft,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            child: Column(
                              children: <Widget>[
                                _buildBasicInfoSection(),
                                const SizedBox(height: 12),
                                _buildTierConfigSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _EditVisaPackageBottomBar(
                width: contentWidth,
                bottomPadding: bottomPadding,
                onTap: _handlePublish,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return EditVisaPackageSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const EditVisaPackageSectionTitle(title: '基础信息'),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '套餐总名称',
            required: true,
            child: EditVisaPackageInputField(
              controller: _serviceNameController,
              hintText: '例如：德国厨师工作签包过',
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '服务国家',
            required: true,
            child: EditVisaPackageInputField(
              controller: _countryController,
              hintText: '请选择',
              readOnly: true,
              trailing: const _EditVisaPackageFieldArrow(),
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '签证类型',
            required: true,
            child: EditVisaPackageInputField(
              controller: _visaTypeController,
              hintText: '请选择',
              readOnly: true,
              trailing: const _EditVisaPackageFieldArrow(),
            ),
          ),
          const SizedBox(height: 16),
          EditVisaPackageLabeledField(
            label: '预计周期 (工作日)',
            required: true,
            child: EditVisaPackageInputField(
              controller: _durationController,
              hintText: '例如：20',
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

  Widget _buildTierConfigSection() {
    return EditVisaPackageSectionCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const EditVisaPackageSectionTitle(title: '多档位套餐配置'),
          const SizedBox(height: 16),
          ..._tiers.asMap().entries.map((
            MapEntry<int, _EditVisaPackageTierDraft> entry,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == _tiers.length - 1 ? 0 : 24,
              ),
              child: _buildTierCard(entry.key, entry.value),
            );
          }),
          const SizedBox(height: 20),
          EditVisaPackageSecondaryButton(
            label: '添加套餐档位',
            onTap: _handleAddTier,
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(int index, _EditVisaPackageTierDraft tier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        EditVisaPackageTierHeader(
          title: '档位套餐',
          showDelete: tier.deletable,
          onDeleteTap: tier.deletable ? () => _handleDeleteTier(index) : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: EditVisaPackageLabeledField(
                label: '档位名称',
                child: EditVisaPackageInputField(
                  controller: tier.nameController,
                  hintText: '请输入',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EditVisaPackageLabeledField(
                label: '价格 (元)',
                child: EditVisaPackageInputField(
                  controller: tier.priceController,
                  hintText: '请输入',
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
        const Text('包含服务', style: EditVisaPackageStyles.fieldLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: tier.serviceItems
              .map(
                (_EditVisaPackageServiceItem item) =>
                    EditVisaPackageServiceChip(
                      label: item.label,
                      selected: item.selected,
                      addStyle: item.addStyle,
                    ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        EditVisaPackageLabeledField(
          label: '套餐描述',
          child: EditVisaPackageMultilineField(
            controller: tier.descriptionController,
            hintText: '请输入…',
            maxLength: 100,
          ),
        ),
        const SizedBox(height: 20),
        EditVisaPackageRadioGroup(
          title: '是否展示所需材料',
          value: tier.showMaterials,
          onChanged: (bool value) {
            setState(() => tier.showMaterials = value);
          },
        ),
        if (tier.showMaterials) ...<Widget>[
          const SizedBox(height: 20),
          ...tier.materials.asMap().entries.map((
            MapEntry<int, _EditVisaPackageMaterialDraft> entry,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == tier.materials.length - 1 ? 0 : 16,
              ),
              child: _buildMaterialCard(tier: tier, material: entry.value),
            );
          }),
          const SizedBox(height: 16),
          EditVisaPackageAddMaterialButton(
            label: '添加材料',
            onTap: () => _handleAddMaterial(tier),
          ),
        ],
      ],
    );
  }

  Widget _buildMaterialCard({
    required _EditVisaPackageTierDraft tier,
    required _EditVisaPackageMaterialDraft material,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                material.label,
                style: EditVisaPackageStyles.fieldLabel,
              ),
            ),
            Text(
              material.requiredLabel,
              style: EditVisaPackageStyles.materialMeta,
            ),
            const SizedBox(width: 8),
            EditVisaPackageSwitch(
              value: material.enabled,
              activeColor: EditVisaPackageStyles.primary,
              inactiveColor: EditVisaPackageStyles.border,
              onChanged: (bool value) {
                setState(() {
                  material.enabled = value;
                  material.requiredLabel = value ? '必填' : '选填';
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        EditVisaPackageInputField(
          controller: material.titleController,
          hintText: material.titleHint,
          readOnly: material.trailingAsset != null,
          trailing: material.trailingAsset == null
              ? null
              : _EditVisaPackageMaterialTrailingIcon(
                  assetPath: material.trailingAsset!,
                ),
        ),
        const SizedBox(height: 12),
        EditVisaPackageInputField(
          controller: material.descriptionController,
          hintText: material.descriptionHint,
        ),
      ],
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _handleSaveDraft() {
    _showHint('存草稿交互已预留，可直接接入保存接口。');
  }

  void _handlePublish() {
    _showHint('立即发布交互已预留，可直接接入发布接口。');
  }

  void _handleAddMaterial(_EditVisaPackageTierDraft tier) {
    setState(() {
      tier.materials.add(
        _EditVisaPackageMaterialDraft(
          label: '材料${tier.materials.length + 1}',
          requiredLabel: '选填',
          enabled: false,
          titleController: TextEditingController(),
          descriptionController: TextEditingController(),
          titleHint: '选择材料类型',
          descriptionHint: '请输入材料描述（20字以内）',
          trailingAsset: 'assets/images/visa_package_chevron_gray.svg',
        ),
      );
    });
  }

  void _handleAddTier() {
    setState(() {
      _tiers.add(
        _createTierDraft(
          serviceItems: const <_EditVisaPackageServiceItem>[
            _EditVisaPackageServiceItem(label: '审核材料', selected: true),
            _EditVisaPackageServiceItem(label: '表格填写', selected: true),
            _EditVisaPackageServiceItem(label: '面签陪同'),
            _EditVisaPackageServiceItem(label: '翻译服务'),
            _EditVisaPackageServiceItem(label: '面签辅导'),
            _EditVisaPackageServiceItem(label: '加急处理'),
            _EditVisaPackageServiceItem(label: '拒签退款'),
            _EditVisaPackageServiceItem(label: '自定义', addStyle: true),
          ],
          showMaterials: false,
          materials: <_EditVisaPackageMaterialDraft>[],
          deletable: true,
        ),
      );
    });
  }

  void _handleDeleteTier(int index) {
    if (_tiers.length <= 1) {
      return;
    }
    final _EditVisaPackageTierDraft draft = _tiers.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EditVisaPackageHeader extends StatelessWidget {
  const _EditVisaPackageHeader({
    required this.topPadding,
    required this.onBackTap,
    required this.onSaveDraftTap,
  });

  final double topPadding;
  final VoidCallback onBackTap;
  final VoidCallback onSaveDraftTap;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = topPadding > 0 ? topPadding : 44;

    return Container(
      color: EditVisaPackageStyles.surface,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: statusBarHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Center(
                      child: Text(
                        '10:41',
                        style: TextStyle(
                          color: EditVisaPackageStyles.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 19 / 16,
                          fontFamilyFallback: <String>[
                            'SF Pro Text',
                            'PingFang SC',
                          ],
                        ),
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/visa_package_status_icons.svg',
                    width: 71,
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBackTap,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/visa_package_back.svg',
                            width: 12,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    '编辑/签证套餐',
                    style: EditVisaPackageStyles.headerTitle,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: TextButton(
                    onPressed: onSaveDraftTap,
                    style: TextButton.styleFrom(
                      foregroundColor: EditVisaPackageStyles.textPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '存草稿',
                      style: EditVisaPackageStyles.headerAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditVisaPackageSectionCard extends StatelessWidget {
  const EditVisaPackageSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        color: EditVisaPackageStyles.surface,
        borderRadius: EditVisaPackageStyles.cardRadius,
      ),
      child: child,
    );
  }
}

class EditVisaPackageSectionTitle extends StatelessWidget {
  const EditVisaPackageSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 3, height: 12, color: EditVisaPackageStyles.primary),
        const SizedBox(width: 8),
        Text(title, style: EditVisaPackageStyles.sectionTitle),
      ],
    );
  }
}

class EditVisaPackageTierHeader extends StatelessWidget {
  const EditVisaPackageTierHeader({
    super.key,
    required this.title,
    this.showDelete = false,
    this.onDeleteTap,
  });

  final String title;
  final bool showDelete;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 7, showDelete ? 8 : 12, 7),
      decoration: BoxDecoration(
        color: EditVisaPackageStyles.fieldBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/visa_package_tier_icon.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(title, style: EditVisaPackageStyles.fieldLabel),
          const Spacer(),
          if (showDelete)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDeleteTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: SvgPicture.asset(
                    'assets/images/visa_package_delete.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditVisaPackageLabeledField extends StatelessWidget {
  const EditVisaPackageLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: EditVisaPackageStyles.fieldLabel,
            children: <InlineSpan>[
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: '  *',
                  style: TextStyle(
                    color: EditVisaPackageStyles.required,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 20 / 10,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class EditVisaPackageInputField extends StatelessWidget {
  const EditVisaPackageInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.trailing,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? trailing;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: EditVisaPackageStyles.primary,
      style: EditVisaPackageStyles.fieldValue,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: EditVisaPackageStyles.fieldHint,
        filled: true,
        fillColor: EditVisaPackageStyles.fieldBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: trailing,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        border: EditVisaPackageStyles.inputBorder(Colors.transparent),
        enabledBorder: EditVisaPackageStyles.inputBorder(Colors.transparent),
        focusedBorder: EditVisaPackageStyles.inputBorder(
          EditVisaPackageStyles.primary,
        ),
      ),
    );
  }
}

class EditVisaPackageMultilineField extends StatelessWidget {
  const EditVisaPackageMultilineField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      minLines: 3,
      maxLines: 3,
      cursorColor: EditVisaPackageStyles.primary,
      style: EditVisaPackageStyles.fieldValue,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: EditVisaPackageStyles.fieldHint,
        counterStyle: EditVisaPackageStyles.helper.copyWith(
          color: EditVisaPackageStyles.textTertiary,
        ),
        filled: true,
        fillColor: EditVisaPackageStyles.fieldBackground,
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        border: EditVisaPackageStyles.inputBorder(Colors.transparent),
        enabledBorder: EditVisaPackageStyles.inputBorder(Colors.transparent),
        focusedBorder: EditVisaPackageStyles.inputBorder(
          EditVisaPackageStyles.primary,
        ),
      ),
    );
  }
}

class EditVisaPackageServiceChip extends StatelessWidget {
  const EditVisaPackageServiceChip({
    super.key,
    required this.label,
    this.selected = false,
    this.addStyle = false,
  });

  final String label;
  final bool selected;
  final bool addStyle;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = selected
        ? EditVisaPackageStyles.primarySoft
        : addStyle
        ? EditVisaPackageStyles.fieldBackground
        : EditVisaPackageStyles.white;

    final BorderSide? borderSide = selected
        ? null
        : BorderSide(
            color: addStyle
                ? EditVisaPackageStyles.border
                : EditVisaPackageStyles.borderMuted,
          );

    return Container(
      height: 34,
      padding: EdgeInsets.fromLTRB(
        addStyle ? 10 : 10,
        8,
        addStyle ? 10 : 10,
        8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: EditVisaPackageStyles.chipRadius,
        border: borderSide == null ? null : Border.fromBorderSide(borderSide),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (addStyle) ...<Widget>[
                SvgPicture.asset(
                  'assets/images/visa_package_add.svg',
                  width: 10,
                  height: 10,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: selected
                    ? EditVisaPackageStyles.selectedChip
                    : EditVisaPackageStyles.plainChip,
              ),
            ],
          ),
          if (selected)
            Positioned(
              right: -10,
              bottom: -8,
              child: Container(
                width: 15,
                height: 12,
                decoration: const BoxDecoration(
                  color: EditVisaPackageStyles.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 10,
                    color: EditVisaPackageStyles.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditVisaPackageRadioGroup extends StatelessWidget {
  const EditVisaPackageRadioGroup({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text('是否展示所需材料', style: EditVisaPackageStyles.fieldLabel),
        ),
        _EditVisaPackageRadioOption(
          label: '是',
          selected: value,
          selectedAsset: 'assets/images/visa_package_radio_selected_yes.svg',
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 32),
        _EditVisaPackageRadioOption(
          label: '否',
          selected: !value,
          selectedAsset: 'assets/images/visa_package_radio_selected_no.svg',
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _EditVisaPackageRadioOption extends StatelessWidget {
  const _EditVisaPackageRadioOption({
    required this.label,
    required this.selected,
    required this.selectedAsset,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String selectedAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: <Widget>[
              selected
                  ? SvgPicture.asset(selectedAsset, width: 20, height: 20)
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: EditVisaPackageStyles.textTertiary,
                          width: 2,
                        ),
                      ),
                    ),
              const SizedBox(width: 7),
              Text(label, style: EditVisaPackageStyles.fieldLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class EditVisaPackageSwitch extends StatelessWidget {
  const EditVisaPackageSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(17),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: EditVisaPackageStyles.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class EditVisaPackageAddMaterialButton extends StatelessWidget {
  const EditVisaPackageAddMaterialButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EditVisaPackageStyles.chipRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.fieldBackground,
            borderRadius: EditVisaPackageStyles.chipRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/visa_package_add.svg',
                width: 10,
                height: 10,
              ),
              const SizedBox(width: 6),
              Text(label, style: EditVisaPackageStyles.plainChip),
            ],
          ),
        ),
      ),
    );
  }
}

class EditVisaPackageSecondaryButton extends StatelessWidget {
  const EditVisaPackageSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.primarySoft,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: EditVisaPackageStyles.primaryBorder),
          ),
          alignment: Alignment.center,
          child: Text(label, style: EditVisaPackageStyles.secondaryButton),
        ),
      ),
    );
  }
}

class _EditVisaPackageBottomBar extends StatelessWidget {
  const _EditVisaPackageBottomBar({
    required this.width,
    required this.bottomPadding,
    required this.onTap,
  });

  final double width;
  final double bottomPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: EditVisaPackageStyles.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0AF0F0F0),
            offset: Offset(0, -1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: width,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              bottomPadding > 0 ? 8 : 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EditVisaPackageStyles.primary,
                      foregroundColor: EditVisaPackageStyles.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '立即发布',
                      style: EditVisaPackageStyles.primaryButton,
                    ),
                  ),
                ),
                SizedBox(height: bottomPadding > 0 ? 33 : 0),
                if (bottomPadding > 0)
                  Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: EditVisaPackageStyles.black,
                      borderRadius: BorderRadius.circular(100),
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

class _EditVisaPackageFieldArrow extends StatelessWidget {
  const _EditVisaPackageFieldArrow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/visa_package_arrow_down.png',
        width: 16,
        height: 16,
      ),
    );
  }
}

class _EditVisaPackageMaterialTrailingIcon extends StatelessWidget {
  const _EditVisaPackageMaterialTrailingIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Center(child: SvgPicture.asset(assetPath, width: 16, height: 16));
  }
}

class _EditVisaPackageTierDraft {
  _EditVisaPackageTierDraft({
    required this.nameController,
    required this.priceController,
    required this.descriptionController,
    required this.showMaterials,
    required this.serviceItems,
    required this.materials,
    required this.deletable,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  bool showMaterials;
  final List<_EditVisaPackageServiceItem> serviceItems;
  final List<_EditVisaPackageMaterialDraft> materials;
  final bool deletable;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    for (final _EditVisaPackageMaterialDraft material in materials) {
      material.dispose();
    }
  }
}

class _EditVisaPackageMaterialDraft {
  _EditVisaPackageMaterialDraft({
    required this.label,
    required this.requiredLabel,
    required this.enabled,
    required this.titleController,
    required this.descriptionController,
    required this.titleHint,
    required this.descriptionHint,
    this.trailingAsset,
  });

  final String label;
  String requiredLabel;
  bool enabled;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String titleHint;
  final String descriptionHint;
  final String? trailingAsset;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _EditVisaPackageServiceItem {
  const _EditVisaPackageServiceItem({
    required this.label,
    this.selected = false,
    this.addStyle = false,
  });

  final String label;
  final bool selected;
  final bool addStyle;
}
