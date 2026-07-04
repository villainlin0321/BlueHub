import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

import 'package:europepass/shared/ui/test_style.dart';

class AddWorkExperiencePage extends StatefulWidget {
  const AddWorkExperiencePage({super.key, this.args});

  final AddWorkExperiencePageArgs? args;

  @override
  State<AddWorkExperiencePage> createState() => _AddWorkExperiencePageState();
}

class _AddWorkExperiencePageState extends State<AddWorkExperiencePage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  AddWorkExperiencePageArgs get _resolvedArgs =>
      widget.args ?? const AddWorkExperiencePageArgs();

  EmploymentPeriodValue? _selectedPeriod;

  bool get _isEditMode => _resolvedArgs.initialValue != null;

  @override
  void initState() {
    super.initState();
    final WorkExperienceFormResult? initialValue = _resolvedArgs.initialValue;
    if (initialValue != null) {
      _companyController.text = initialValue.company;
      _jobTitleController.text = initialValue.jobTitle;
      _departmentController.text = initialValue.department;
      _contentController.text = initialValue.description;
      _selectedPeriod = initialValue.period;
    }
    _contentController.addListener(_handleContentChanged);
    _contentFocusNode.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _contentFocusNode
      ..removeListener(_handleContentChanged)
      ..dispose();
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    setState(() {});
  }

  Future<void> _openEmploymentPeriodSheet() async {
    final EmploymentPeriodValue? result = await showEmploymentPeriodBottomSheet(
      context: context,
      initialValue:
          _selectedPeriod ?? EmploymentPeriodValue.suggested(DateTime.now()),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedPeriod = result;
    });
  }

  void _handleSave() {
    final String company = _companyController.text.trim();
    final String jobTitle = _jobTitleController.text.trim();
    if (company.isEmpty) {
      _showMessage('我的.请输入公司名称'.tr());
      return;
    }
    if (_selectedPeriod == null) {
      _showMessage('我的.请选择在职时间'.tr());
      return;
    }
    if (jobTitle.isEmpty) {
      _showMessage('我的.请输入职位名称'.tr());
      return;
    }

    context.pop(
      WorkExperiencePageResult.saved(
        WorkExperienceFormResult(
          company: company,
          period: _selectedPeriod!,
          jobTitle: jobTitle,
          department: _departmentController.text.trim(),
          description: _contentController.text.trim(),
        ),
      ),
    );
  }

  void _handleDelete() {
    context.pop(const WorkExperiencePageResult.deleted());
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
          '我的.工作经历'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          TapBlankToDismissKeyboard(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 140),
                child: Column(
                  children: <Widget>[
                    _UnderlinedInputField(
                      label: '我的.公司名称'.tr(),
                      controller: _companyController,
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedSelectorField(
                      label: '我的.在职时间'.tr(),
                      value: _selectedPeriod?.displayText,
                      onTap: _openEmploymentPeriodSheet,
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedInputField(
                      label: '我的.职位名称'.tr(),
                      controller: _jobTitleController,
                    ),
                    const SizedBox(height: 16),
                    _UnderlinedInputField(
                      label: '我的.所在部门'.tr(),
                      controller: _departmentController,
                    ),
                    const SizedBox(height: 16),
                    _WorkContentField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      currentLength: _contentController.text.characters.length,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_contentFocusNode.hasFocus && bottomInset > 0)
            Positioned(
              right: 16,
              bottom: 8,
              child: SafeArea(
                top: false,
                child: TextButton(
                  onPressed: _contentFocusNode.unfocus,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF096DD9),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '完成',
                    style: TestStyle.pingFangMedium(fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
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
        ),
      ),
    );
  }
}

class AddWorkExperiencePageArgs {
  const AddWorkExperiencePageArgs({this.initialValue});

  final WorkExperienceFormResult? initialValue;
}

class WorkExperiencePageResult {
  const WorkExperiencePageResult.saved(this.value) : deleted = false;

  const WorkExperiencePageResult.deleted() : value = null, deleted = true;

  final WorkExperienceFormResult? value;
  final bool deleted;
}

class WorkExperienceFormResult {
  const WorkExperienceFormResult({
    required this.company,
    required this.period,
    required this.jobTitle,
    required this.department,
    required this.description,
  });

  final String company;
  final EmploymentPeriodValue period;
  final String jobTitle;
  final String department;
  final String description;

  String get displayRole {
    if (department.isEmpty) {
      return jobTitle;
    }
    return '$department·$jobTitle';
  }
}

class EmploymentPeriodValue {
  const EmploymentPeriodValue({
    required this.startYear,
    required this.startMonth,
    this.endYear,
    this.endMonth,
  });

  factory EmploymentPeriodValue.suggested(DateTime now) {
    final int suggestedYear = now.year - 8;
    return EmploymentPeriodValue(
      startYear: suggestedYear < 2000 ? 2000 : suggestedYear,
      startMonth: 3,
    );
  }

  final int startYear;
  final int startMonth;
  final int? endYear;
  final int? endMonth;

  bool get isCurrent => endYear == null;

  String get displayText {
    final String start =
        '${startYear.toString().padLeft(4, '0')}.${startMonth.toString().padLeft(2, '0')}';
    if (isCurrent) {
      return '$start - ${'我的.至今'.tr()}';
    }
    return '$start - ${endYear.toString().padLeft(4, '0')}.${endMonth.toString().padLeft(2, '0')}';
  }

  EmploymentPeriodValue normalized() {
    if (isCurrent) {
      return EmploymentPeriodValue(
        startYear: startYear,
        startMonth: startMonth,
      );
    }

    int normalizedEndYear = endYear!;
    int normalizedEndMonth = endMonth ?? 1;
    if (normalizedEndYear < startYear) {
      normalizedEndYear = startYear;
      normalizedEndMonth = startMonth;
    } else if (normalizedEndYear == startYear &&
        normalizedEndMonth < startMonth) {
      normalizedEndMonth = startMonth;
    }

    return EmploymentPeriodValue(
      startYear: startYear,
      startMonth: startMonth,
      endYear: normalizedEndYear,
      endMonth: normalizedEndMonth,
    );
  }
}

Future<EmploymentPeriodValue?> showEmploymentPeriodBottomSheet({
  required BuildContext context,
  required EmploymentPeriodValue initialValue,
}) {
  return showResumeTimePickerBottomSheet(
    context: context,
    type: ResumeTimePickerType.period,
    title: '我的.时间段'.tr(),
    initialValue: ResumeTimePickerValue(
      startYear: initialValue.startYear,
      startMonth: initialValue.startMonth,
      endYear: initialValue.endYear,
      endMonth: initialValue.endMonth,
    ),
  ).then((ResumeTimePickerValue? result) {
    if (result == null) {
      return null;
    }
    return EmploymentPeriodValue(
      startYear: result.startYear,
      startMonth: result.startMonth,
      endYear: result.endYear,
      endMonth: result.endMonth,
    ).normalized();
  });
}

class _EmploymentPeriodBottomSheet extends StatefulWidget {
  const _EmploymentPeriodBottomSheet({required this.initialValue});

  final EmploymentPeriodValue initialValue;

  @override
  State<_EmploymentPeriodBottomSheet> createState() =>
      _EmploymentPeriodBottomSheetState();
}

class _EmploymentPeriodBottomSheetState
    extends State<_EmploymentPeriodBottomSheet> {
  static const double _wheelHeight = 198;
  static const double _itemExtent = 36;
  static const double _selectionBandHeight = 49.5;

  late final List<int> _years = <int>[
    for (int year = DateTime.now().year; year >= 1980; year--) year,
  ];
  late final List<int?> _endYearOptions = <int?>[null, ..._years];
  late final List<int> _months = <int>[
    for (int month = 1; month <= 12; month++) month,
  ];

  late int _startYear = widget.initialValue.startYear;
  late int _startMonth = widget.initialValue.startMonth;
  late int? _endYear = widget.initialValue.endYear;
  late int _endMonth = widget.initialValue.endMonth ?? DateTime.now().month;

  late final FixedExtentScrollController _startYearController =
      FixedExtentScrollController(initialItem: _years.indexOf(_startYear));
  late final FixedExtentScrollController _startMonthController =
      FixedExtentScrollController(initialItem: _months.indexOf(_startMonth));
  late final FixedExtentScrollController _endYearController =
      FixedExtentScrollController(
        initialItem: _endYearOptions.indexOf(_endYear),
      );
  late final FixedExtentScrollController _endMonthController =
      FixedExtentScrollController(initialItem: _months.indexOf(_endMonth));

  @override
  void dispose() {
    _startYearController.dispose();
    _startMonthController.dispose();
    _endYearController.dispose();
    _endMonthController.dispose();
    super.dispose();
  }

  void _normalizeEndPeriod() {
    if (_endYear == null) {
      return;
    }

    if (_endYear! < _startYear) {
      _endYear = _startYear;
      _jumpToEndYear(_endYear!);
    }

    if (_endYear == _startYear && _endMonth < _startMonth) {
      _endMonth = _startMonth;
      _jumpToEndMonth(_endMonth);
    }
  }

  void _jumpToEndYear(int year) {
    final int index = _endYearOptions.indexOf(year);
    if (index >= 0) {
      _endYearController.jumpToItem(index);
    }
  }

  void _jumpToEndMonth(int month) {
    final int index = _months.indexOf(month);
    if (index >= 0) {
      _endMonthController.jumpToItem(index);
    }
  }

  void _handleConfirm() {
    Navigator.of(context).pop(
      EmploymentPeriodValue(
        startYear: _startYear,
        startMonth: _startMonth,
        endYear: _endYear,
        endMonth: _endYear == null ? null : _endMonth,
      ).normalized(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double selectionTop = (_wheelHeight - _selectionBandHeight) / 2;
    final double selectionBottom = selectionTop + _selectionBandHeight;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 356,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF171A1D),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '我的.时间段'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 17,
                      color: Color(0xFF171A1D),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    child: GestureDetector(
                      onTap: _handleConfirm,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          '通用.确定'.tr(),
                          style: TestStyle.pingFangRegular(
                            fontSize: 16,
                            color: Color(0xFF096DD9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: SizedBox(
                height: _wheelHeight,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: selectionTop,
                      child: const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: Color(0xFFD9D9D9),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: selectionBottom,
                      child: const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: Color(0xFFD9D9D9),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          width: 48,
                          child: _PickerWheel<int>(
                            values: _years,
                            controller: _startYearController,
                            selectedValue: _startYear,
                            itemExtent: _itemExtent,
                            labelBuilder: (int value) => '$value',
                            onSelected: (int value) {
                              setState(() {
                                _startYear = value;
                                _normalizeEndPeriod();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          child: _PickerWheel<int>(
                            values: _months,
                            controller: _startMonthController,
                            selectedValue: _startMonth,
                            itemExtent: _itemExtent,
                            labelBuilder: (int value) => '$value',
                            onSelected: (int value) {
                              setState(() {
                                _startMonth = value;
                                _normalizeEndPeriod();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 16,
                          child: Center(
                            child: Text(
                              '-',
                              style: TestStyle.regular(
                                fontSize: 17,
                                color: Color(0xFF8C8C8C),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: _PickerWheel<int?>(
                            values: _endYearOptions,
                            controller: _endYearController,
                            selectedValue: _endYear,
                            itemExtent: _itemExtent,
                            labelBuilder: (int? value) =>
                                value == null ? '我的.至今'.tr() : '$value',
                            onSelected: (int? value) {
                              setState(() {
                                _endYear = value;
                                if (_endYear != null) {
                                  _normalizeEndPeriod();
                                }
                              });
                            },
                          ),
                        ),
                        IgnorePointer(
                          ignoring: _endYear == null,
                          child: Opacity(
                            opacity: _endYear == null ? 0.4 : 1,
                            child: SizedBox(
                              width: 24,
                              child: _PickerWheel<int>(
                                values: _months,
                                controller: _endMonthController,
                                selectedValue: _endMonth,
                                itemExtent: _itemExtent,
                                labelBuilder: (int value) => '$value',
                                onSelected: (int value) {
                                  setState(() {
                                    _endMonth = value;
                                    _normalizeEndPeriod();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom > 0 ? 8 : 16,
              ),
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerWheel<T> extends StatelessWidget {
  const _PickerWheel({
    required this.values,
    required this.controller,
    required this.selectedValue,
    required this.itemExtent,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final FixedExtentScrollController controller;
  final T selectedValue;
  final double itemExtent;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = values.indexOf(selectedValue);

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      perspective: 0.004,
      diameterRatio: 1.7,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (int index) => onSelected(values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (BuildContext context, int index) {
          final int distance = (index - selectedIndex).abs();
          final TextStyle textStyle;
          if (distance == 0) {
            textStyle = TestStyle.medium(
              fontSize: 17,
              color: Color(0xFF171A1D),
            );
          } else if (distance == 1) {
            textStyle = TestStyle.regular(
              fontSize: 17,
              color: Color(0x99171A1D),
            );
          } else {
            textStyle = TestStyle.regular(
              fontSize: 14,
              color: Color(0x66171A1D),
            );
          }
          return Center(
            child: Text(
              labelBuilder(values[index]),
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}

class _UnderlinedInputField extends StatelessWidget {
  const _UnderlinedInputField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 0),
          Text(
            label,
            style: TestStyle.regular(fontSize: 14, color: Color(0xFF595959)),
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
                style: TestStyle.pingFangRegular(
                  fontSize: 16,
                  color: Color(0xFF171A1D),
                ),
                decoration: InputDecoration(
                  hintText: '通用.请输入'.tr(),
                  hintStyle: TestStyle.pingFangRegular(
                    fontSize: 16,
                    color: Color(0xFFBFBFBF),
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

class _UnderlinedSelectorField extends StatelessWidget {
  const _UnderlinedSelectorField({
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
                          style: TestStyle.pingFangRegular(
                            fontSize: 16,
                            color: value == null
                                ? const Color(0xFFBFBFBF)
                                : const Color(0xFF171A1D),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF8C8C8C),
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

class _WorkContentField extends StatelessWidget {
  const _WorkContentField({
    required this.controller,
    required this.focusNode,
    required this.currentLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int currentLength;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 289,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '我的.工作内容'.tr(),
            style: TestStyle.pingFangRegular(
              fontSize: 14,
              color: Color(0xFF595959),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 500,
              maxLines: null,
              minLines: 9,
              style: TestStyle.pingFangRegular(
                fontSize: 16,
                color: Color(0xFF171A1D),
              ),
              decoration: InputDecoration(
                hintText: '通用.请输入'.tr(),
                hintStyle: TestStyle.pingFangRegular(
                  fontSize: 16,
                  color: Color(0xFFBFBFBF),
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.only(top: 15),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentLength/500',
              style: TestStyle.regular(fontSize: 16, color: Color(0xFF8C8C8C)),
            ),
          ),
        ],
      ),
    );
  }
}
