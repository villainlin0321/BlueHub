import 'package:flutter/material.dart';

/// 点击空白区域时收起当前键盘。
class TapBlankToDismissKeyboard extends StatelessWidget {
  const TapBlankToDismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      // 在指针落下阶段就先收起焦点，避免子组件自己消费点击事件后父层收不到 onTap。
      onPointerDown: (_) {
        final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus?.hasFocus ?? false) {
          primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}
