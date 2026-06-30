import 'package:flutter/material.dart';

import '../ui/app_colors.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
/// 列表分区标题（含“更多”）。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
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
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TestStyle.numberBold(fontSize: 16, color: AppColors.textPrimary),
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                actionLabel!,
                style: TestStyle.semibold(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
