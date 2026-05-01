import 'package:flutter/material.dart';

import 'resume_time_picker_bottom_sheet.dart';

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
                      onTap: () {
                        Navigator.of(context).pop(
                          widget.options
                              .where(
                                (option) => _selected.contains(option.value),
                              )
                              .map((option) => option.value)
                              .toList(growable: false),
                        );
                      },
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
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(option.value);
                        } else if (widget.multiple) {
                          _selected.add(option.value);
                        } else {
                          _selected
                            ..clear()
                            ..add(option.value);
                        }
                      });
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
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? const Color(0xFF096DD9)
                  : const Color(0xFFBFBFBF),
            ),
            const SizedBox(width: 11),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 22 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
