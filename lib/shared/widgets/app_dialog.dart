import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';
const double _kAppDialogMaxWidth = 276;
const double _kAppDialogRadius = 8;
const double _kAppDialogActionRadius = 6;
const Color _kAppDialogBarrierColor = Color(0x66000000);
const Color _kAppDialogTitleColor = Color(0xFF262626);
const Color _kAppDialogMessageColor = Color(0xFF8C8C8C);
const Color _kAppDialogPrimaryColor = Color(0xFF096DD9);
const Color _kAppDialogDangerColor = Color(0xFFD9363E);
const Color _kAppDialogBorderColor = Color(0xFFD9D9D9);

/// 统一承载全局通用 Dialog 的展示入口，避免业务侧继续依赖系统样式容器。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color barrierColor = _kAppDialogBarrierColor,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          final double bottomInset = MediaQuery.viewInsetsOf(
            dialogContext,
          ).bottom;
          return themes.wrap(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible
                  ? () => Navigator.of(
                      dialogContext,
                      rootNavigator: useRootNavigator,
                    ).maybePop()
                  : null,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(20, 20, 20, min(80, bottomInset)),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {},
                              child: Builder(builder: builder),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
    transitionBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.96,
                end: 1,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
  );
}

/// 通用确认弹窗，按全局样式统一标题、正文和双按钮布局。
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final bool? result = await showAppDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext dialogContext) {
      return AppDialog(
        title: title,
        message: message,
        actions: <AppDialogAction>[
          AppDialogAction.secondary(
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction.primary(
            label: confirmLabel,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// 删除确认弹窗，统一承载危险操作的红色主按钮样式。
Future<bool> showAppDeleteConfirmDialog({
  required BuildContext context,
  required String message,
  String? title,
  String? cancelLabel,
  String? confirmLabel,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final bool? result = await showAppDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext dialogContext) {
      return AppDialog(
        title: title ?? '通用.确认删除'.tr(),
        message: message,
        actions: <AppDialogAction>[
          AppDialogAction.secondary(
            label: cancelLabel ?? '通用.取消'.tr(),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction.danger(
            label: confirmLabel ?? '通用.删除'.tr(),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

enum AppDialogActionVariant { primary, secondary, danger }

/// Dialog 操作按钮配置，统一收口主次按钮的文本和点击行为。
class AppDialogAction {
  const AppDialogAction.primary({required this.label, required this.onPressed})
    : variant = AppDialogActionVariant.primary;

  const AppDialogAction.secondary({
    required this.label,
    required this.onPressed,
  }) : variant = AppDialogActionVariant.secondary;

  const AppDialogAction.danger({required this.label, required this.onPressed})
    : variant = AppDialogActionVariant.danger;

  final String label;
  final VoidCallback onPressed;
  final AppDialogActionVariant variant;
}

/// 全局通用 Dialog 容器，支持标准文案和自定义内容区。
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const <AppDialogAction>[],
    this.titleTextAlign = TextAlign.center,
    this.messageTextAlign = TextAlign.center,
  }) : assert(message == null || content == null, 'message 与 content 只能提供一个');

  final String title;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;
  final TextAlign titleTextAlign;
  final TextAlign messageTextAlign;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kAppDialogMaxWidth),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kAppDialogRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                textAlign: titleTextAlign,
                style: TestStyle.medium(fontSize: 16, color: _kAppDialogTitleColor),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: messageTextAlign,
                  style: TestStyle.regular(fontSize: 14, color: _kAppDialogMessageColor),
                ),
              ],
              if (content != null) ...<Widget>[
                const SizedBox(height: 8),
                content!,
              ],
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < actions.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _AppDialogActionButton(action: actions[index]),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDialogActionButton extends StatelessWidget {
  const _AppDialogActionButton({required this.action});

  final AppDialogAction action;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = action.variant == AppDialogActionVariant.primary;
    final bool isDanger = action.variant == AppDialogActionVariant.danger;
    final Color backgroundColor = isPrimary
        ? _kAppDialogPrimaryColor
        : isDanger
        ? _kAppDialogDangerColor
        : Colors.white;
    final Color borderColor = isPrimary
        ? _kAppDialogPrimaryColor
        : isDanger
        ? _kAppDialogDangerColor
        : _kAppDialogBorderColor;
    final Color textColor = isPrimary || isDanger
        ? Colors.white
        : _kAppDialogTitleColor;
    return SizedBox(
      height: 36,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kAppDialogActionRadius),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(_kAppDialogActionRadius),
          child: Center(
            child: Text(
              action.label,
              style: TestStyle.regular(fontSize: 14, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
