import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';
class AuthLanguageSwitch extends StatelessWidget {
  const AuthLanguageSwitch({
    super.key,
    required this.isChineseSelected,
    required this.onChanged,
  });

  final bool isChineseSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LanguageOption(
            label: '语言.中文简称'.tr(),
            selected: isChineseSelected,
            onTap: () => onChanged(true),
          ),
          _LanguageOption(
            label: '语言.英文简称'.tr(),
            selected: !isChineseSelected,
            onTap: () => onChanged(false),
            horizontalPadding: 8,
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.horizontalPadding = 6,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1890FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TestStyle.semibold(fontSize: 12, color: selected ? Colors.white : const Color(0xFF262626)),
        ),
      ),
    );
  }
}
