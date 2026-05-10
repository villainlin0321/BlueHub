import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/data/config_models.dart';
import '../edit_visa_package_styles.dart';

class EditVisaPackageTierViewDraft {
  EditVisaPackageTierViewDraft({
    required this.nameController,
    required this.priceController,
    required this.descriptionController,
    required this.showMaterials,
    required this.selectedServiceTagCodes,
    required this.customServices,
    required this.materials,
    required this.deletable,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  bool showMaterials;
  final Set<String> selectedServiceTagCodes;
  final List<String> customServices;
  final List<EditVisaPackageMaterialViewDraft> materials;
  final bool deletable;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    for (final EditVisaPackageMaterialViewDraft material in materials) {
      material.dispose();
    }
  }
}

class EditVisaPackageMaterialViewDraft {
  EditVisaPackageMaterialViewDraft({
    required this.titleController,
    required this.descriptionController,
    required this.isRequired,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  bool isRequired;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

Future<String?> showEditVisaPackageCustomServiceDialog(
  BuildContext context,
) async {
  return showDialog<String>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return const _EditVisaPackageCustomServiceDialog();
    },
  );
}

class _EditVisaPackageCustomServiceDialog extends StatefulWidget {
  const _EditVisaPackageCustomServiceDialog();

  @override
  State<_EditVisaPackageCustomServiceDialog> createState() =>
      _EditVisaPackageCustomServiceDialogState();
}

class _EditVisaPackageCustomServiceDialogState
    extends State<_EditVisaPackageCustomServiceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '添加自定义服务',
              style: TextStyle(
                color: EditVisaPackageStyles.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 1,
              maxLength: 12,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(12),
              ],
              cursorColor: EditVisaPackageStyles.primary,
              decoration: InputDecoration(
                hintText: '请输入自定义服务',
                hintStyle: EditVisaPackageStyles.fieldHint,
                counterText: '',
                filled: true,
                fillColor: EditVisaPackageStyles.fieldBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: EditVisaPackageStyles.inputBorder(Colors.transparent),
                enabledBorder: EditVisaPackageStyles.inputBorder(
                  Colors.transparent,
                ),
                focusedBorder: EditVisaPackageStyles.inputBorder(
                  EditVisaPackageStyles.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EditVisaPackageStyles.primary,
                  foregroundColor: EditVisaPackageStyles.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '确定',
                  style: EditVisaPackageStyles.primaryButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditVisaPackageHeader extends StatelessWidget {
  const EditVisaPackageHeader({
    super.key,
    required this.topPadding,
    required this.onBackTap,
    required this.onSaveDraftTap,
    required this.isSavingDraft,
    required this.actionsEnabled,
  });

  final double topPadding;
  final VoidCallback onBackTap;
  final VoidCallback onSaveDraftTap;
  final bool isSavingDraft;
  final bool actionsEnabled;

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
                    onPressed: actionsEnabled ? onSaveDraftTap : null,
                    style: TextButton.styleFrom(
                      foregroundColor: EditVisaPackageStyles.textPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isSavingDraft ? '保存中...' : '存草稿',
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
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
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

class EditVisaPackageSelectorField extends StatelessWidget {
  const EditVisaPackageSelectorField({
    super.key,
    required this.text,
    required this.hintText,
    required this.onTap,
  });

  final String? text;
  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = text != null && text!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EditVisaPackageStyles.fieldRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.fieldBackground,
            borderRadius: EditVisaPackageStyles.fieldRadius,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  hasValue ? text! : hintText,
                  style: hasValue
                      ? EditVisaPackageStyles.fieldValue
                      : EditVisaPackageStyles.fieldHint,
                ),
              ),
              const SizedBox(width: 8),
              const EditVisaPackageFieldArrow(),
            ],
          ),
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

class EditVisaPackageServiceTagContent extends StatelessWidget {
  const EditVisaPackageServiceTagContent({
    super.key,
    required this.serviceTags,
    required this.selectedServiceTagCodes,
    required this.isLoadingServiceTags,
    required this.serviceTagsError,
    required this.onRetryLoadServiceTags,
    required this.onServiceTagTap,
    required this.tagLabelBuilder,
    required this.customServices,
    required this.onAddCustomService,
    required this.onRemoveCustomService,
  });

  final List<TagItemVO> serviceTags;
  final Set<String> selectedServiceTagCodes;
  final bool isLoadingServiceTags;
  final String? serviceTagsError;
  final VoidCallback onRetryLoadServiceTags;
  final ValueChanged<String> onServiceTagTap;
  final String Function(TagItemVO) tagLabelBuilder;
  final List<String> customServices;
  final VoidCallback onAddCustomService;
  final ValueChanged<String> onRemoveCustomService;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      if (isLoadingServiceTags)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (serviceTagsError != null)
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                serviceTagsError!,
                style: EditVisaPackageStyles.fieldHint,
              ),
            ),
            TextButton(
              onPressed: onRetryLoadServiceTags,
              child: const Text('重试'),
            ),
          ],
        )
      else if (serviceTags.isEmpty)
        const Text('暂无包含服务标签', style: EditVisaPackageStyles.fieldHint)
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: serviceTags.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 80 / 34,
          ),
          itemBuilder: (BuildContext context, int index) {
            final TagItemVO tag = serviceTags[index];
            return EditVisaPackageServiceChip(
              label: tagLabelBuilder(tag),
              selected: selectedServiceTagCodes.contains(tag.tagCode),
              onTap: () => onServiceTagTap(tag.tagCode),
            );
          },
        ),
    ];

    if (customServices.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: customServices
              .map(
                (String tag) => EditVisaPackageCustomTagChip(
                  label: tag,
                  onRemove: () => onRemoveCustomService(tag),
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    children.add(const SizedBox(height: 12));
    children.add(
      EditVisaPackageAddCustomServiceChip(onTap: onAddCustomService),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class EditVisaPackageServiceChip extends StatelessWidget {
  const EditVisaPackageServiceChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? EditVisaPackageStyles.primary
        : EditVisaPackageStyles.borderMuted;
    final Color backgroundColor = selected
        ? EditVisaPackageStyles.primarySoft
        : EditVisaPackageStyles.white;
    final Color textColor = selected
        ? EditVisaPackageStyles.primary
        : EditVisaPackageStyles.textStrong;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EditVisaPackageStyles.chipRadius,
        hoverColor: selected
            ? EditVisaPackageStyles.primarySoft.withValues(alpha: 0.8)
            : EditVisaPackageStyles.fieldBackground,
        focusColor: selected
            ? EditVisaPackageStyles.primarySoft.withValues(alpha: 0.9)
            : EditVisaPackageStyles.fieldBackground,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: EditVisaPackageStyles.chipRadius,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned.fill(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 18 / 14,
                    ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: _EditVisaPackageChipCheckIcon(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditVisaPackageCustomTagChip extends StatelessWidget {
  const EditVisaPackageCustomTagChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditVisaPackageStyles.fieldBackground,
        borderRadius: EditVisaPackageStyles.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: EditVisaPackageStyles.fieldLabel),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: EditVisaPackageStyles.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class EditVisaPackageAddCustomServiceChip extends StatelessWidget {
  const EditVisaPackageAddCustomServiceChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EditVisaPackageStyles.chipRadius,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.fieldBackground,
            borderRadius: EditVisaPackageStyles.chipRadius,
            border: Border.all(color: EditVisaPackageStyles.border),
          ),
          child: const Text('+ 自定义', style: EditVisaPackageStyles.plainChip),
        ),
      ),
    );
  }
}

class EditVisaPackageRadioGroup extends StatelessWidget {
  const EditVisaPackageRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text('是否展示所需材料', style: EditVisaPackageStyles.fieldLabel),
        ),
        EditVisaPackageRadioOption(
          label: '是',
          selected: value,
          selectedAsset: 'assets/images/visa_package_radio_selected_yes.svg',
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 32),
        EditVisaPackageRadioOption(
          label: '否',
          selected: !value,
          selectedAsset: 'assets/images/visa_package_radio_selected_no.svg',
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class EditVisaPackageRadioOption extends StatelessWidget {
  const EditVisaPackageRadioOption({
    super.key,
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

class EditVisaPackageBottomBar extends StatelessWidget {
  const EditVisaPackageBottomBar({
    super.key,
    required this.width,
    required this.bottomPadding,
    required this.onTap,
    required this.isPublishing,
    required this.enabled,
  });

  final double width;
  final double bottomPadding;
  final VoidCallback onTap;
  final bool isPublishing;
  final bool enabled;

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
                    onPressed: enabled ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EditVisaPackageStyles.primary,
                      foregroundColor: EditVisaPackageStyles.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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

class EditVisaPackageFieldArrow extends StatelessWidget {
  const EditVisaPackageFieldArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.keyboard_arrow_right,
      size: 14,
      color: EditVisaPackageStyles.black,
    );
  }
}

class _EditVisaPackageChipCheckIcon extends StatelessWidget {
  const _EditVisaPackageChipCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 12,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(4),
        ),
        child: CustomPaint(painter: _EditVisaPackageChipCheckIconPainter()),
      ),
    );
  }
}

class _EditVisaPackageChipCheckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = EditVisaPackageStyles.primary
      ..style = PaintingStyle.fill;

    final Path cornerPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(cornerPath, fillPaint);

    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path iconPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.65, size.height * 0.8)
      ..lineTo(size.width * 0.85, size.height * 0.55);
    canvas.drawPath(iconPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EditVisaPackageMaterialTrailingIcon extends StatelessWidget {
  const EditVisaPackageMaterialTrailingIcon({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.arrow_forward_ios, size: 14, color: color);
  }
}
