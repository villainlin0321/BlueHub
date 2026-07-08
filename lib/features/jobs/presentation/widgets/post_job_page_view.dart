import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:europepass/shared/ui/test_style.dart';

import '../../../../shared/widgets/field_trailing_selector.dart';
import '../../../config/data/config_models.dart';
import '../../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../post_job_page_styles.dart';
import 'post_job_form_widgets.dart';

class PostJobPageView extends StatelessWidget {
  const PostJobPageView({
    super.key,
    required this.title,
    required this.publishButtonLabel,
    required this.packageNameController,
    required this.countryController,
    required this.headcountController,
    required this.minSalaryController,
    required this.maxSalaryController,
    required this.customTagController,
    required this.descriptionController,
    required this.jobTypes,
    required this.salaryUnits,
    required this.selectedJobType,
    required this.selectedSalaryUnit,
    required this.selectedSalaryCurrencyLabel,
    required this.requirementTags,
    required this.selectedRequirementTagCodes,
    required this.customTags,
    required this.isLoadingRequirementTags,
    required this.requirementTagsError,
    required this.isPublishing,
    required this.onBack,
    required this.onSaveDraft,
    required this.onPublish,
    required this.onRetryLoadRequirementTags,
    required this.onJobTypeChanged,
    required this.onSalaryUnitChanged,
    required this.onSalaryCurrencyTap,
    required this.onRequirementTagTap,
    required this.onRemoveCustomTag,
    required this.onCustomTagSubmitted,
    required this.tagLabelBuilder,
  });

  final String title;
  final String publishButtonLabel;
  final TextEditingController packageNameController;
  final TextEditingController countryController;
  final TextEditingController headcountController;
  final TextEditingController minSalaryController;
  final TextEditingController maxSalaryController;
  final TextEditingController customTagController;
  final TextEditingController descriptionController;
  final List<String> jobTypes;
  final List<String> salaryUnits;
  final String selectedJobType;
  final String selectedSalaryUnit;
  final String selectedSalaryCurrencyLabel;
  final List<TagItemVO> requirementTags;
  final Set<String> selectedRequirementTagCodes;
  final List<String> customTags;
  final bool isLoadingRequirementTags;
  final String? requirementTagsError;
  final bool isPublishing;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;
  final VoidCallback onRetryLoadRequirementTags;
  final ValueChanged<String> onJobTypeChanged;
  final ValueChanged<String> onSalaryUnitChanged;
  final VoidCallback onSalaryCurrencyTap;
  final ValueChanged<String> onRequirementTagTap;
  final ValueChanged<String> onRemoveCustomTag;
  final ValueChanged<String> onCustomTagSubmitted;
  final String Function(TagItemVO) tagLabelBuilder;

  /// 将岗位类型 code 转成当前语言下的展示文案。
  String _jobTypeLabel(String value) {
    return switch (value) {
      'any' => '岗位发布.不限'.tr(),
      'full_time' => '岗位发布.全职'.tr(),
      'part_time' => '岗位发布.兼职'.tr(),
      _ => value,
    };
  }

  /// 将薪资周期 code 转成当前语言下的展示文案。
  String _salaryUnitLabel(String value) {
    return switch (value) {
      'month' => '岗位发布.月薪'.tr(),
      'week' => '岗位发布.周薪'.tr(),
      'day' => '岗位发布.日薪'.tr(),
      'hour' => '岗位发布.时薪'.tr(),
      _ => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: PostJobPageStyles.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: onBack,
          icon: SvgPicture.asset(
            'assets/images/service_detail_back.svg',
            width: 12,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xE6000000),
              BlendMode.srcIn,
            ),
          ),
        ),
        title: Text(title, style: PostJobPageStyles.navTitle),
        // actions: <Widget>[
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16),
        //     child: TextButton(
        //       onPressed: onSaveDraft,
        //       style: TextButton.styleFrom(
        //         minimumSize: const Size(44, 32),
        //         foregroundColor: PostJobPageStyles.titleText,
        //         textStyle: PostJobPageStyles.navAction,
        //       ),
        //       child: Text('岗位发布.存草稿'.tr()),
        //     ),
        //   ),
        // ],
      ),
      body: TapBlankToDismissKeyboard(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth.clamp(0, 560);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: Column(
                    children: <Widget>[
                      PostJobSectionCard(
                        title: '岗位发布.基础信息'.tr(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            PostJobFieldGroup(
                              label: '岗位发布.套餐名称'.tr(),
                              child: PostJobInputField(
                                controller: packageNameController,
                                hintText: '岗位发布.套餐名称示例'.tr(),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '岗位发布.服务国家'.tr(),
                              child: PostJobInputField(
                                controller: countryController,
                                hintText: '岗位发布.服务国家示例'.tr(),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '岗位发布.招聘类型'.tr(),
                              child: Wrap(
                                spacing: 0,
                                runSpacing: 12,
                                children: jobTypes
                                    .map(
                                      (String item) => PostJobRadioOption(
                                        label: _jobTypeLabel(item),
                                        selected: item == selectedJobType,
                                        onTap: () => onJobTypeChanged(item),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 20),
                            PostJobFieldGroup(
                              label: '岗位发布.招聘人数'.tr(),
                              child: PostJobInputField(
                                controller: headcountController,
                                hintText: '岗位发布.请输入数字'.tr(),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '岗位发布.薪资范围'.tr(),
                              trailing: FieldTrailingSelector(
                                label: selectedSalaryCurrencyLabel,
                                onTap: onSalaryCurrencyTap,
                                textStyle: PostJobPageStyles.optionText.copyWith(
                                  color: PostJobPageStyles.secondaryText,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Wrap(
                                    spacing: 0,
                                    runSpacing: 12,
                                    children: salaryUnits
                                        .map(
                                          (String item) => PostJobRadioOption(
                                            label: _salaryUnitLabel(item),
                                            selected:
                                                item == selectedSalaryUnit,
                                            onTap: () =>
                                                onSalaryUnitChanged(item),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: PostJobInputField(
                                          controller: minSalaryController,
                                          hintText: '岗位发布.最低薪资'.tr(),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          centerText: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '岗位发布.至'.tr(),
                                        style: PostJobPageStyles.fieldLabel,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: PostJobInputField(
                                          controller: maxSalaryController,
                                          hintText: '岗位发布.最高薪资'.tr(),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          centerText: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PostJobSectionCard(
                        title: '岗位发布.任职要求'.tr(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _RequirementTagContent(
                              requirementTags: requirementTags,
                              selectedRequirementTagCodes:
                                  selectedRequirementTagCodes,
                              isLoadingRequirementTags:
                                  isLoadingRequirementTags,
                              requirementTagsError: requirementTagsError,
                              onRetryLoadRequirementTags:
                                  onRetryLoadRequirementTags,
                              onRequirementTagTap: onRequirementTagTap,
                              tagLabelBuilder: tagLabelBuilder,
                            ),
                            if (customTags.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 12,
                                children: customTags
                                    .map(
                                      (String tag) => _CustomTagChip(
                                        tag: tag,
                                        onRemove: () => onRemoveCustomTag(tag),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                            const SizedBox(height: 12),
                            PostJobInputField(
                              controller: customTagController,
                              hintText: '岗位发布.自定义标签提示'.tr(),
                              maxLength: 8,
                              textInputAction: TextInputAction.done,
                              onSubmitted: onCustomTagSubmitted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PostJobSectionCard(
                        title: '岗位发布.工作描述'.tr(),
                        trailing: Text(
                          '通用.选填'.tr(),
                          style: PostJobPageStyles.optional,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: PostJobPageStyles.inputFill,
                            borderRadius: BorderRadius.circular(
                              PostJobPageStyles.fieldRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Column(
                              children: <Widget>[
                                TextField(
                                  controller: descriptionController,
                                  maxLength: 200,
                                  maxLines: 5,
                                  minLines: 5,
                                  textInputAction: TextInputAction.done,
                                  buildCounter:
                                      (
                                        BuildContext context, {
                                        required int currentLength,
                                        required bool isFocused,
                                        required int? maxLength,
                                      }) {
                                        return const SizedBox.shrink();
                                      },
                                  style: PostJobPageStyles.optionText,
                                  decoration: InputDecoration(
                                    hintText: '岗位发布.详细描述提示'.tr(),
                                    hintStyle: PostJobPageStyles.placeholder,
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: descriptionController,
                                  builder:
                                      (
                                        BuildContext context,
                                        TextEditingValue value,
                                        Widget? child,
                                      ) {
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${value.text.characters.length}/200',
                                            style: PostJobPageStyles.counter,
                                          ),
                                        );
                                      },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 + bottomInset),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: PostJobPageStyles.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: isPublishing ? null : onPublish,
                      style: FilledButton.styleFrom(
                        backgroundColor: PostJobPageStyles.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            PostJobPageStyles.buttonRadius,
                          ),
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
                              publishButtonLabel,
                              style: PostJobPageStyles.buttonText,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementTagContent extends StatelessWidget {
  const _RequirementTagContent({
    required this.requirementTags,
    required this.selectedRequirementTagCodes,
    required this.isLoadingRequirementTags,
    required this.requirementTagsError,
    required this.onRetryLoadRequirementTags,
    required this.onRequirementTagTap,
    required this.tagLabelBuilder,
  });

  final List<TagItemVO> requirementTags;
  final Set<String> selectedRequirementTagCodes;
  final bool isLoadingRequirementTags;
  final String? requirementTagsError;
  final VoidCallback onRetryLoadRequirementTags;
  final ValueChanged<String> onRequirementTagTap;
  final String Function(TagItemVO) tagLabelBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoadingRequirementTags) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (requirementTagsError != null) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              requirementTagsError!,
              style: PostJobPageStyles.placeholder,
            ),
          ),
          TextButton(
            onPressed: onRetryLoadRequirementTags,
            child: Text('通用.重试'.tr()),
          ),
        ],
      );
    }

    if (requirementTags.isEmpty) {
      return Text('岗位发布.暂无任职要求标签'.tr(), style: PostJobPageStyles.placeholder);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requirementTags.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 104 / PostJobPageStyles.chipHeight,
      ),
      itemBuilder: (BuildContext context, int index) {
        final TagItemVO tag = requirementTags[index];
        return PostJobSelectableChip(
          label: tagLabelBuilder(tag),
          selected: selectedRequirementTagCodes.contains(tag.tagCode),
          onTap: () => onRequirementTagTap(tag.tagCode),
        );
      },
    );
  }
}

class _CustomTagChip extends StatelessWidget {
  const _CustomTagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PostJobPageStyles.chipHeight,
      decoration: BoxDecoration(
        color: PostJobPageStyles.chipSelectedBackground,
        borderRadius: BorderRadius.circular(PostJobPageStyles.chipRadius),
        border: Border.all(
          color: PostJobPageStyles.chipSelectedBorder,
          width: 0.5,
        ),
      ),
      child: Padding(
        // 与上方系统标签保持一致的字号节奏，并收紧删除按钮两侧留白。
        padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              tag,
              style: TestStyle.regular(
                fontSize: 14,
                color: PostJobPageStyles.chipSelectedText,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: PostJobPageStyles.chipSelectedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
