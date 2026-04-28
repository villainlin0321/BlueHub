import 'package:flutter/material.dart';

enum ResumeTimePickerType { period, singleMonth }

class ResumeTimePickerValue {
  const ResumeTimePickerValue({
    required this.startYear,
    required this.startMonth,
    this.endYear,
    this.endMonth,
  });

  factory ResumeTimePickerValue.suggestedPeriod(DateTime now) {
    final int suggestedYear = now.year - 8;
    return ResumeTimePickerValue(
      startYear: suggestedYear < 2000 ? 2000 : suggestedYear,
      startMonth: 3,
    );
  }

  factory ResumeTimePickerValue.suggestedSingleMonth(DateTime now) {
    return ResumeTimePickerValue(startYear: now.year, startMonth: now.month);
  }

  final int startYear;
  final int startMonth;
  final int? endYear;
  final int? endMonth;

  bool get isCurrent => endYear == null;

  String format(ResumeTimePickerType type) {
    final String start =
        '${startYear.toString().padLeft(4, '0')}.${startMonth.toString().padLeft(2, '0')}';
    if (type == ResumeTimePickerType.singleMonth) {
      return start;
    }
    if (isCurrent) {
      return '$start - 至今';
    }
    return '$start - ${endYear.toString().padLeft(4, '0')}.${endMonth.toString().padLeft(2, '0')}';
  }

  ResumeTimePickerValue normalizedFor(ResumeTimePickerType type) {
    if (type == ResumeTimePickerType.singleMonth) {
      return ResumeTimePickerValue(
        startYear: startYear,
        startMonth: startMonth,
      );
    }

    if (isCurrent) {
      return ResumeTimePickerValue(
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

    return ResumeTimePickerValue(
      startYear: startYear,
      startMonth: startMonth,
      endYear: normalizedEndYear,
      endMonth: normalizedEndMonth,
    );
  }
}

Future<ResumeTimePickerValue?> showResumeTimePickerBottomSheet({
  required BuildContext context,
  required ResumeTimePickerType type,
  required ResumeTimePickerValue initialValue,
  String title = '时间段',
}) {
  return showModalBottomSheet<ResumeTimePickerValue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _ResumeTimePickerBottomSheet(
        type: type,
        title: title,
        initialValue: initialValue.normalizedFor(type),
      );
    },
  );
}

class _ResumeTimePickerBottomSheet extends StatefulWidget {
  const _ResumeTimePickerBottomSheet({
    required this.type,
    required this.title,
    required this.initialValue,
  });

  final ResumeTimePickerType type;
  final String title;
  final ResumeTimePickerValue initialValue;

  @override
  State<_ResumeTimePickerBottomSheet> createState() =>
      _ResumeTimePickerBottomSheetState();
}

class _ResumeTimePickerBottomSheetState
    extends State<_ResumeTimePickerBottomSheet> {
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
    if (widget.type != ResumeTimePickerType.period || _endYear == null) {
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
      ResumeTimePickerValue(
        startYear: _startYear,
        startMonth: _startMonth,
        endYear: widget.type == ResumeTimePickerType.singleMonth
            ? null
            : _endYear,
        endMonth: widget.type == ResumeTimePickerType.singleMonth
            ? null
            : (_endYear == null ? null : _endMonth),
      ).normalizedFor(widget.type),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
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
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Color(0xFF171A1D),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            height: 25 / 17,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
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
                  ],
                ),
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
                    widget.type == ResumeTimePickerType.singleMonth
                        ? _buildSingleMonthWheels()
                        : _buildPeriodWheels(),
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

  Widget _buildSingleMonthWheels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
              });
            },
          ),
        ),
        const SizedBox(width: 52),
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
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodWheels() {
    return Row(
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
            labelBuilder: (int? value) => value == null ? '至今' : '$value',
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
