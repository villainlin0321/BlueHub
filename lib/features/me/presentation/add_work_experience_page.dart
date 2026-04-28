import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class AddWorkExperiencePage extends StatefulWidget {
  const AddWorkExperiencePage({super.key});

  @override
  State<AddWorkExperiencePage> createState() => _AddWorkExperiencePageState();
}

class _AddWorkExperiencePageState extends State<AddWorkExperiencePage> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  EmploymentPeriodValue? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleContentChanged);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
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
      _showMessage('请输入公司名称');
      return;
    }
    if (_selectedPeriod == null) {
      _showMessage('请选择在职时间');
      return;
    }
    if (jobTitle.isEmpty) {
      _showMessage('请输入职位名称');
      return;
    }

    context.pop(
      WorkExperienceFormResult(
        company: company,
        period: _selectedPeriod!,
        jobTitle: jobTitle,
        department: _departmentController.text.trim(),
        description: _contentController.text.trim(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text(
          '添加工作经历',
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
                _UnderlinedInputField(
                  label: '公司名称',
                  controller: _companyController,
                ),
                const SizedBox(height: 16),
                _UnderlinedSelectorField(
                  label: '在职时间',
                  value: _selectedPeriod?.displayText,
                  onTap: _openEmploymentPeriodSheet,
                ),
                const SizedBox(height: 16),
                _UnderlinedInputField(
                  label: '职位名称',
                  controller: _jobTitleController,
                ),
                const SizedBox(height: 16),
                _UnderlinedInputField(
                  label: '所在部门',
                  controller: _departmentController,
                ),
                const SizedBox(height: 16),
                _WorkContentField(
                  controller: _contentController,
                  currentLength: _contentController.text.characters.length,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset > 0 ? 12 : 16),
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
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 22 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      return '$start - 至今';
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
    title: '时间段',
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
                  const Text(
                    '时间段',
                    style: TextStyle(
                      color: Color(0xFF171A1D),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 25 / 17,
                    ),
                  ),
                  Positioned(
                    right: 16,
                    child: GestureDetector(
                      onTap: _handleConfirm,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          '确定',
                          style: TextStyle(
                            color: Color(0xFF096DD9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 25 / 16,
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
                        const SizedBox(
                          width: 16,
                          child: Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Color(0xFF8C8C8C),
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                height: 22 / 17,
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
                                value == null ? '至今' : '$value',
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
            textStyle = const TextStyle(
              color: Color(0xFF171A1D),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 22 / 17,
            );
          } else if (distance == 1) {
            textStyle = const TextStyle(
              color: Color(0x99171A1D),
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 22 / 17,
            );
          } else {
            textStyle = const TextStyle(
              color: Color(0x66171A1D),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 22 / 14,
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
                decoration: const InputDecoration(
                  hintText: '请输入',
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
                          value ?? '请选择',
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
    required this.currentLength,
  });

  final TextEditingController controller;
  final int currentLength;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 289,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '工作内容',
            style: TextStyle(
              color: Color(0xFF595959),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 500,
              maxLines: null,
              minLines: 9,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
              ),
              decoration: const InputDecoration(
                hintText: '请输入',
                hintStyle: TextStyle(
                  color: Color(0xFFBFBFBF),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
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
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 22 / 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
