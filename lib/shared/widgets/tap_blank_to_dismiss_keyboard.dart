import 'package:flutter/material.dart';

/// 点击空白区域时收起当前键盘。
class TapBlankToDismissKeyboard extends StatelessWidget {
  const TapBlankToDismissKeyboard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final FocusScopeNode focusScope = FocusScope.of(context);
        if (!focusScope.hasPrimaryFocus) {
          focusScope.unfocus();
        }
      },
      child: child,
    );
  }
}
