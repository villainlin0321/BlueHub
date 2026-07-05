import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// 展示未保存内容退出确认弹窗，统一收口文案与按钮行为。
Future<bool> showUnsavedChangesExitDialog(BuildContext context) {
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppDialog(
        title: '现在退出，内容将不会保存',
        actions: <AppDialogAction>[
          AppDialogAction.secondary(
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction.primary(
            label: '确定',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  ).then((bool? value) => value ?? false);
}

/// 根据当前页面是否存在未保存改动，决定是否允许离开页面。
Future<bool> confirmDiscardChangesIfNeeded({
  required BuildContext context,
  required bool hasUnsavedChanges,
}) {
  // 无未保存改动时直接放行，避免出现多余的确认弹窗。
  if (!hasUnsavedChanges) {
    return Future<bool>.value(true);
  }

  return showUnsavedChangesExitDialog(context);
}
