import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class AddEducationExperiencePage extends ConsumerStatefulWidget {
  const AddEducationExperiencePage({super.key, this.args});

  final AddEducationExperiencePageArgs? args;

  @override
  ConsumerState<AddEducationExperiencePage> createState() =>
      _AddEducationExperiencePageState();
}

class _AddEducationExperiencePageState
    extends ConsumerState<AddEducationExperiencePage> {
  final TextEditingController _majorController = TextEditingController();

  AddEducationExperiencePageArgs get _resolvedArgs =>
      widget.args ?? const AddEducationExperiencePageArgs();

  String? _selectedSchool;
  String? _selectedDegree;
  ResumeTimePickerValue? _selectedPeriod;

  bool get _isEditMode => _resolvedArgs.initialValue != null;

  @override
  void initState() {
    super.initState();
    final EducationExperienceFormResult? initialValue =
        _resolvedArgs.initialValue;
    if (initialValue != null) {
      _selectedSchool = initialValue.school;
      _selectedDegree = initialValue.degree;
      _majorController.text = initialValue.major;
      _selectedPeriod = initialValue.period;
    }
  }

  @override
  void dispose() {
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _openSchoolPage() async {
    final String? result = await context.push<String>(
      RoutePaths.addEducationSchool,
      extra: _selectedSchool,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSchool = result;
    });
  }

  Future<List<SelectableSheetOption<String>>> _loadDegreeOptions() async {
    final List<TagItemVO> tags = await ref.read(
      tagDictionaryProvider(TagCategory.educationLevel).future,
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

  Future<void> _openDegreeSheet() async {
    final List<SelectableSheetOption<String>> degreeOptions;
    try {
      degreeOptions = await _loadDegreeOptions();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('我的.学历字典加载失败'.tr());
      return;
    }
    if (degreeOptions.isEmpty) {
      if (!mounted) {
        return;
      }
      _showMessage('我的.暂无可选学历'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '我的.学历'.tr(),
      options: degreeOptions,
      initialSelectedValues: _selectedDegree == null
          ? const <String>[]
          : <String>[_selectedDegree!],
      multiple: false,
    );

    if (result == null || result.isEmpty) {
      return;
    }

    setState(() {
      _selectedDegree = result.first;
    });
  }

  Future<void> _openPeriodSheet() async {
    final DateTime now = DateTime.now();
    final ResumeTimePickerValue? result = await showResumeTimePickerBottomSheet(
      context: context,
      type: ResumeTimePickerType.period,
      title: '我的.时间段'.tr(),
      initialValue:
          _selectedPeriod ??
          ResumeTimePickerValue(
            startYear: now.year - 4,
            startMonth: 9,
            endYear: now.year,
            endMonth: 6,
          ).normalizedFor(ResumeTimePickerType.period),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedPeriod = result;
    });
  }

  void _handleSave() {
    final String major = _majorController.text.trim();
    if ((_selectedSchool ?? '').isEmpty) {
      _showMessage('我的.请选择学校'.tr());
      return;
    }
    if ((_selectedDegree ?? '').isEmpty) {
      _showMessage('我的.请选择学历'.tr());
      return;
    }
    if (major.isEmpty) {
      _showMessage('我的.请输入专业'.tr());
      return;
    }
    if (_selectedPeriod == null) {
      _showMessage('我的.请选择时间段'.tr());
      return;
    }

    context.pop(
      EducationExperiencePageResult.saved(
        EducationExperienceFormResult(
          school: _selectedSchool!,
          degree: _selectedDegree!,
          major: major,
          period: _selectedPeriod!,
        ),
      ),
    );
  }

  void _handleDelete() {
    context.pop(const EducationExperiencePageResult.deleted());
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
          '我的.教育经历'.tr(),
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 140),
            child: Column(
              children: <Widget>[
                _EducationSelectorField(
                  label: '我的.学校'.tr(),
                  value: _selectedSchool,
                  onTap: _openSchoolPage,
                ),
                const SizedBox(height: 16),
                _EducationSelectorField(
                  label: '我的.学历'.tr(),
                  value: _selectedDegree,
                  onTap: _openDegreeSheet,
                ),
                const SizedBox(height: 16),
                _EducationInputField(
                  label: '我的.专业'.tr(),
                  controller: _majorController,
                ),
                const SizedBox(height: 16),
                _EducationSelectorField(
                  label: '我的.时间段'.tr(),
                  value: _selectedPeriod?.format(ResumeTimePickerType.period),
                  onTap: _openPeriodSheet,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
          ),
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset > 0 ? 12 : 16),
          child: Row(
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                        ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
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

class AddEducationExperiencePageArgs {
  const AddEducationExperiencePageArgs({this.initialValue});

  final EducationExperienceFormResult? initialValue;
}

class EducationExperiencePageResult {
  const EducationExperiencePageResult.saved(this.value) : deleted = false;

  const EducationExperiencePageResult.deleted() : value = null, deleted = true;

  final EducationExperienceFormResult? value;
  final bool deleted;
}

class EducationExperienceFormResult {
  const EducationExperienceFormResult({
    required this.school,
    required this.degree,
    required this.major,
    required this.period,
  });

  final String school;
  final String degree;
  final String major;
  final ResumeTimePickerValue period;

  String get displaySubtitle {
    return '$major · $degree';
  }

  String get displayPeriod {
    final String start = period.startYear.toString().padLeft(4, '0');
    if (period.endYear == null) {
      return '$start - ${'我的.至今'.tr()}';
    }
    return '$start - ${period.endYear.toString().padLeft(4, '0')}';
  }
}

class _EducationInputField extends StatelessWidget {
  const _EducationInputField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

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
          SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                ),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFF171A1D),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 22 / 16,
                ),
                decoration: InputDecoration(
                  hintText: '通用.请输入'.tr(),
                  hintStyle: TextStyle(
                    color: Color(0xFFBFBFBF),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 22 / 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 15, bottom: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationSelectorField extends StatelessWidget {
  const _EducationSelectorField({
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
          SizedBox(
            height: 52,
            child: InkWell(
              onTap: onTap,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          value ?? '通用.请选择'.tr(),
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
          ),
        ],
      ),
    );
  }
}
