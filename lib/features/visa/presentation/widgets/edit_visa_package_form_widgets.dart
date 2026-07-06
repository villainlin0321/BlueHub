import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/ui/test_keys.dart';
import '../../../config/data/config_models.dart';
import '../../../../utils/upload_picker_utils.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../edit_visa_package_styles.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 收起当前页面输入焦点，避免切换到其他交互后键盘继续占用页面。
void dismissEditVisaPackageKeyboard(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
}

/// 先收起键盘，再执行后续点击回调。
VoidCallback dismissKeyboardThen(BuildContext context, VoidCallback onTap) {
  return () {
    dismissEditVisaPackageKeyboard(context);
    onTap();
  };
}

class EditVisaPackageTierViewDraft {
  EditVisaPackageTierViewDraft({
    required this.tierId,
    required this.nameController,
    required this.priceController,
    required this.descriptionController,
    required this.showMaterials,
    required this.selectedServiceTagCodes,
    required this.customServices,
    required this.materials,
    required this.deletable,
  });

  final int tierId;
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
    this.exampleFiles = const <PickedUploadFile>[],
    this.existingExampleFileIds = const <int>[],
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  bool isRequired;
  List<PickedUploadFile> exampleFiles;
  List<int> existingExampleFileIds;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

/// 弹出自定义服务输入框，并返回用户输入的服务名。
Future<String?> showEditVisaPackageCustomServiceDialog(
  BuildContext context,
) async {
  return showAppDialog<String>(
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
    return AppDialog(
      title: '签证编辑.添加自定义服务'.tr(),
      content: TextField(
        controller: _controller,
        onTapOutside: (_) => dismissEditVisaPackageKeyboard(context),
        maxLines: 1,
        maxLength: 12,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(12),
        ],
        cursorColor: EditVisaPackageStyles.primary,
        decoration: InputDecoration(
          hintText: '签证编辑.请输入自定义服务'.tr(),
          hintStyle: EditVisaPackageStyles.fieldHint,
          counterText: '',
          filled: true,
          fillColor: EditVisaPackageStyles.fieldBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: EditVisaPackageStyles.inputBorder(Colors.transparent),
          enabledBorder: EditVisaPackageStyles.inputBorder(Colors.transparent),
          focusedBorder: EditVisaPackageStyles.inputBorder(
            EditVisaPackageStyles.primary,
          ),
        ),
      ),
      actions: <AppDialogAction>[
        AppDialogAction.secondary(
          label: '通用.取消'.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction.primary(
          label: '通用.确定'.tr(),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}

class EditVisaPackageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const EditVisaPackageHeader({
    super.key,
    required this.onBackTap,
    required this.onSaveDraftTap,
    required this.isSavingDraft,
    required this.actionsEnabled,
  });

  final VoidCallback onBackTap;
  final VoidCallback onSaveDraftTap;
  final bool isSavingDraft;
  final bool actionsEnabled;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EditVisaPackageStyles.surface,
      surfaceTintColor: EditVisaPackageStyles.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 44,
      leading: Material(
        color: Colors.transparent,
        child: InkWell(
          key: AppTestKeys.actionEditVisaPackageBack,
          onTap: dismissKeyboardThen(context, onBackTap),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/visa_package_back.svg',
              width: 12,
              height: 24,
            ),
          ),
        ),
      ),
      title: Text('签证编辑.编辑签证套餐'.tr(), style: EditVisaPackageStyles.headerTitle),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton(
            key: AppTestKeys.actionEditVisaPackageSaveDraft,
            onPressed: actionsEnabled
                ? dismissKeyboardThen(context, onSaveDraftTap)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: EditVisaPackageStyles.textPrimary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isSavingDraft ? '签证编辑.保存中'.tr() : '签证编辑.存草稿'.tr(),
              style: EditVisaPackageStyles.headerAction,
            ),
          ),
        ),
      ],
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
  const EditVisaPackageSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final bool showAction =
        actionLabel != null &&
        actionLabel!.trim().isNotEmpty &&
        onActionTap != null;

    return Row(
      children: <Widget>[
        Container(width: 3, height: 12, color: EditVisaPackageStyles.primary),
        const SizedBox(width: 8),
        Text(title, style: EditVisaPackageStyles.sectionTitle),
        const Spacer(),
        if (showAction)
          TextButton(
            onPressed: onActionTap == null
                ? null
                : dismissKeyboardThen(context, onActionTap!),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF096DD9),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class EditVisaPackageCoverPreview extends StatelessWidget {
  const EditVisaPackageCoverPreview({
    super.key,
    required this.file,
    required this.onUploadTap,
    this.onPreviewTap,
    this.onDeleteTap,
  });

  final PickedUploadFile? file;
  final VoidCallback onUploadTap;
  final VoidCallback? onPreviewTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return InkWell(
        onTap: dismissKeyboardThen(context, onUploadTap),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: 148,
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.fieldBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/order_upload_add_inline.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(height: 8),
              Text(
                '签证编辑.上传封面'.tr(),
                style: TestStyle.pingFangMedium(
                  fontSize: 14,
                  color: const Color(0xFF171A1D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '签证编辑.封面图提示'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 12,
                  color: const Color(0xFF8C8C8C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EditVisaPackageStyles.fieldBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreviewTap == null
                    ? null
                    : dismissKeyboardThen(context, onPreviewTap!),
                child: SizedBox(
                  height: 148,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _CoverPreviewImage(file: file!),
                      if (file!.state == UploadItemState.uploading)
                        _CoverPreviewOverlay(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: file!.progress > 0
                                      ? file!.progress
                                      : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '签证编辑.封面上传中'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      if (file!.state == UploadItemState.failure)
                        _CoverPreviewOverlay(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '签证编辑.封面上传失败'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: dismissKeyboardThen(
                                  context,
                                  onUploadTap,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('签证编辑.重新上传封面'.tr()),
                              ),
                            ],
                          ),
                        ),
                      if (onDeleteTap != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: dismissKeyboardThen(context, onDeleteTap!),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/order_upload_remove.svg',
                                width: 8,
                                height: 8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    file!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.medium(
                      fontSize: 14,
                      color: const Color(0xFF171A1D),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: dismissKeyboardThen(context, onUploadTap),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF096DD9),
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('签证编辑.重新上传封面'.tr()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPreviewImage extends StatelessWidget {
  const _CoverPreviewImage({required this.file});

  final PickedUploadFile file;

  @override
  Widget build(BuildContext context) {
    final String remoteUrl = (file.uploadedFileUrl ?? '').trim();
    final bool useRemoteImage = remoteUrl.isNotEmpty;
    final String path = file.path.trim();

    if (useRemoteImage) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverPreviewImageFallback(),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverPreviewImageFallback(),
      );
    }
    final File localFile = File(path);
    if (localFile.existsSync()) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverPreviewImageFallback(),
      );
    }
    return const _CoverPreviewImageFallback();
  }
}

class _CoverPreviewOverlay extends StatelessWidget {
  const _CoverPreviewOverlay({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(child: child),
    );
  }
}

class _CoverPreviewImageFallback extends StatelessWidget {
  const _CoverPreviewImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/order_upload_sheet_gallery.svg',
          width: 28,
          height: 28,
        ),
      ),
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
                onTap: onDeleteTap == null
                    ? null
                    : dismissKeyboardThen(context, onDeleteTap!),
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
    this.trailing,
  });

  final String label;
  final bool required;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: EditVisaPackageStyles.fieldLabel,
                  children: <InlineSpan>[
                    TextSpan(text: label),
                    if (required)
                      TextSpan(
                        text: '  *',
                        style: TestStyle.semibold(
                          fontSize: 10,
                          color: EditVisaPackageStyles.required,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
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
    this.fieldKey,
    this.trailing,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final Key? fieldKey;
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onTapOutside: (_) => dismissEditVisaPackageKeyboard(context),
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
    this.buttonKey,
  });

  final String? text;
  final String hintText;
  final VoidCallback onTap;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = text != null && text!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        onTap: dismissKeyboardThen(context, onTap),
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
      onTapOutside: (_) => dismissEditVisaPackageKeyboard(context),
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
              child: Text('通用.重试'.tr()),
            ),
          ],
        )
      else if (serviceTags.isEmpty)
        Text('签证编辑.暂无包含服务标签'.tr(), style: EditVisaPackageStyles.fieldHint)
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
        onTap: onTap == null ? null : dismissKeyboardThen(context, onTap!),
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
                    style: TestStyle.regular(fontSize: 14, color: textColor),
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
        color: EditVisaPackageStyles.primarySoft,
        borderRadius: EditVisaPackageStyles.chipRadius,
        border: Border.all(color: EditVisaPackageStyles.primary, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: EditVisaPackageStyles.selectedChip),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismissKeyboardThen(context, onRemove),
            child: const Icon(
              Icons.close,
              size: 16,
              color: EditVisaPackageStyles.primary,
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
        onTap: dismissKeyboardThen(context, onTap),
        borderRadius: EditVisaPackageStyles.chipRadius,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: EditVisaPackageStyles.fieldBackground,
            borderRadius: EditVisaPackageStyles.chipRadius,
            border: Border.all(color: EditVisaPackageStyles.border),
          ),
          child: Text('签证编辑.自定义'.tr(), style: EditVisaPackageStyles.plainChip),
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
        Expanded(
          child: Text(
            '签证编辑.是否展示所需材料'.tr(),
            style: EditVisaPackageStyles.fieldLabel,
          ),
        ),
        EditVisaPackageRadioOption(
          label: '签证编辑.是'.tr(),
          selected: value,
          selectedAsset: 'assets/images/visa_package_radio_selected_yes.svg',
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 32),
        EditVisaPackageRadioOption(
          label: '签证编辑.否'.tr(),
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
        onTap: dismissKeyboardThen(context, onTap),
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
      onTap: () {
        // 开关切换前先收起键盘，避免输入框在 rebuild 后重新抢焦点。
        dismissEditVisaPackageKeyboard(context);
        onChanged(!value);
      },
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
        onTap: dismissKeyboardThen(context, onTap),
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
        onTap: dismissKeyboardThen(context, onTap),
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
                    key: AppTestKeys.actionEditVisaPackagePublish,
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
                        : Text(
                            '签证编辑.立即发布'.tr(),
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
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(4)),
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
