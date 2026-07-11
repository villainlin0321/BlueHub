import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'resume_time_picker_bottom_sheet.dart';

import 'package:europepass/shared/ui/test_style.dart';

class SelectableSheetOption<T> {
  const SelectableSheetOption({required this.value, required this.label});

  final T value;
  final String label;
}

Future<List<T>?> showSelectableOptionsBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectableSheetOption<T>> options,
  Iterable<T> initialSelectedValues = const [],
  bool multiple = true,
}) {
  return showResumeBottomSheet<List<T>>(
    context: context,
    builder: (BuildContext context) {
      return _SelectableOptionsBottomSheet<T>(
        title: title,
        options: options,
        initialSelectedValues: initialSelectedValues.toList(growable: false),
        multiple: multiple,
      );
    },
  );
}

class _SelectableOptionsBottomSheet<T> extends StatefulWidget {
  const _SelectableOptionsBottomSheet({
    required this.title,
    required this.options,
    required this.initialSelectedValues,
    required this.multiple,
  });

  final String title;
  final List<SelectableSheetOption<T>> options;
  final List<T> initialSelectedValues;
  final bool multiple;

  @override
  State<_SelectableOptionsBottomSheet<T>> createState() =>
      _SelectableOptionsBottomSheetState<T>();
}

class _SelectableOptionsBottomSheetState<T>
    extends State<_SelectableOptionsBottomSheet<T>> {
  late final Set<T> _selected = widget.initialSelectedValues.toSet();

  List<T> _buildSelectionResult() {
    return widget.options
        .where((option) => _selected.contains(option.value))
        .map((option) => option.value)
        .toList(growable: false);
  }

  /// 构建可复用的选项列表弹层，并根据单选/多选模式展示对应控件。
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 424,
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
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: widget.multiple
                          ? GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              behavior: HitTestBehavior.opaque,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF171A1D),
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: TestStyle.regular(
                            fontSize: 17,
                            color: Color(0xFF171A1D),
                          ),
                        ),
                      ),
                    ),
                    widget.multiple
                        ? GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pop(_buildSelectionResult());
                            },
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
                          )
                        : GestureDetector(
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.options.length,
                itemBuilder: (BuildContext context, int index) {
                  final SelectableSheetOption<T> option = widget.options[index];
                  final bool selected = _selected.contains(option.value);
                  return _SelectableOptionTile(
                    label: option.label,
                    selected: selected,
                    multiple: widget.multiple,
                    onTap: () {
                      if (widget.multiple) {
                        setState(() {
                          if (selected) {
                            _selected.remove(option.value);
                          } else {
                            _selected.add(option.value);
                          }
                        });
                        return;
                      }

                      _selected
                        ..clear()
                        ..add(option.value);
                      Navigator.of(context).pop(_buildSelectionResult());
                    },
                  );
                },
              ),
            ),
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

class _SelectableOptionTile extends StatelessWidget {
  const _SelectableOptionTile({
    required this.label,
    required this.selected,
    required this.multiple,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;

  /// 根据选择模式切换图标语义，避免多选和单选都显示为同一种控件。
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 15),
            Icon(
              multiple
                  ? (selected ? Icons.check_circle : Icons.panorama_fish_eye)
                  : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
              size: 20,
              // 多选场景统一使用品牌蓝，保证全局勾选态视觉一致。
              color: selected
                  ? const Color(0xFF096DD9)
                  : const Color(0xFFBFBFBF),
            ),
            const SizedBox(width: 11),
            Text(
              label,
              style: TestStyle.regular(fontSize: 16, color: Color(0xFF171A1D)),
            ),
          ],
        ),
      ),
    );
  }
}
