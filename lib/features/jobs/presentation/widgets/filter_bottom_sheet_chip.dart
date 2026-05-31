import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/widgets/app_svg_icon.dart';

class FilterBottomSheetOption {
  const FilterBottomSheetOption({required this.value, required this.label});

  final String value;
  final String label;
}

class FilterBottomSheetChip extends StatelessWidget {
  const FilterBottomSheetChip({
    super.key,
    this.width = 88,
    required this.title,
    required this.value,
    required this.options,
    required this.enabled,
    this.onChanged,
  });

  final double width;
  final String title;
  final String value;
  final List<FilterBottomSheetOption> options;
  final bool enabled;
  final ValueChanged<String?>? onChanged;

  Future<void> _handleTap(BuildContext context, String effectiveValue) async {
    if (!enabled || onChanged == null) {
      return;
    }
    final String? result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FilterOptionsBottomSheet(
          title: title,
          options: options,
          currentValue: effectiveValue,
        );
      },
    );
    if (result == null || result == effectiveValue) {
      return;
    }
    onChanged!(result);
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveValue = options.any(
          (FilterBottomSheetOption option) => option.value == value,
        )
        ? value
        : options.first.value;
    final FilterBottomSheetOption selectedOption = options.firstWhere(
      (FilterBottomSheetOption option) => option.value == effectiveValue,
    );
    final bool highlighted = effectiveValue != options.first.value;
    final Color borderColor = highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return SizedBox(
      width: width,
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && onChanged != null
              ? () => _handleTap(context, effectiveValue)
              : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    selectedOption.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
                      height: 18 / 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AppSvgIcon(
                  assetPath: 'assets/images/icon_arrow_down.svg',
                  fallback: Icons.arrow_drop_down,
                  size: 12,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterOptionsBottomSheet extends StatelessWidget {
  const _FilterOptionsBottomSheet({
    required this.title,
    required this.options,
    required this.currentValue,
  });

  final String title;
  final List<FilterBottomSheetOption> options;
  final String currentValue;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 52,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF171A1D),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 25 / 17,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF171A1D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    bottomPadding > 0 ? bottomPadding + 24 : 24,
                  ),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      const double spacing = 12;
                      final double itemWidth =
                          (constraints.maxWidth - spacing * 2) / 3;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: 18,
                        children: options
                            .map(
                              (FilterBottomSheetOption option) => _FilterOptionTile(
                                width: itemWidth,
                                label: option.label,
                                selected: option.value == currentValue,
                                onTap: () =>
                                    Navigator.of(context).pop(option.value),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
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

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? const Color(0xFF91C3FF)
        : const Color(0xFFBFBFBF);
    final Color backgroundColor = selected
        ? const Color(0xFFEDF4FF)
        : Colors.white;
    final Color textColor = selected
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            height: 18 / 14,
          ),
        ),
      ),
    );
  }
}

Future<T?> showFilterActionBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  required VoidCallback onReset,
  required VoidCallback onConfirm,
  String? resetText,
  String? confirmText,
  bool isConfirmEnabled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _FilterActionBottomSheet(
        title: title,
        onReset: onReset,
        onConfirm: onConfirm,
        resetText: resetText ?? '重置'.tr(),
        confirmText: confirmText ?? '确定'.tr(),
        isConfirmEnabled: isConfirmEnabled,
        child: child,
      );
    },
  );
}

class _FilterActionBottomSheet extends StatelessWidget {
  const _FilterActionBottomSheet({
    required this.title,
    required this.child,
    required this.onReset,
    required this.onConfirm,
    required this.resetText,
    required this.confirmText,
    required this.isConfirmEnabled,
  });

  final String title;
  final Widget child;
  final VoidCallback onReset;
  final VoidCallback onConfirm;
  final String resetText;
  final String confirmText;
  final bool isConfirmEnabled;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 52,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF171A1D),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 25 / 17,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF171A1D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: child,
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  12,
                  32,
                  12,
                  bottomPadding > 0 ? bottomPadding + 12 : 16,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReset,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: const BorderSide(color: Color(0xFFD9D9D9)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          resetText,
                          style: const TextStyle(
                            color: Color(0xFF262626),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 22 / 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isConfirmEnabled ? onConfirm : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFBFBFBF),
                          backgroundColor: const Color(0xFF096DD9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 22 / 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
