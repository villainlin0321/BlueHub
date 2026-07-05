import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 全局 Toast 工具，统一对接 EasyLoading 并收口项目内文本提示样式。
class AppToast {
  AppToast._();

  static const Color _backgroundColor = Color(0xFF45484A);
  static const Color _textColor = Colors.white;
  static const double _radius = 8;
  static const double _fontSize = 14;
  static const EdgeInsets _contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const Duration _displayDuration = Duration(milliseconds: 2000);

  /// 初始化 EasyLoading 的全局 Toast 样式。
  static void configure() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..maskType = EasyLoadingMaskType.none
      ..userInteractions = true
      ..dismissOnTap = false
      ..displayDuration = _displayDuration
      ..toastPosition = EasyLoadingToastPosition.top
      ..backgroundColor = _backgroundColor
      ..textColor = _textColor
      ..indicatorColor = _textColor
      ..maskColor = Colors.transparent
      ..boxShadow = const <BoxShadow>[]
      ..radius = _radius
      ..fontSize = _fontSize
      ..contentPadding = _contentPadding;
  }

  /// 展示统一样式的文本 Toast。
  static Future<void> show(String message) async {
    final String trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }
    await EasyLoading.dismiss(animation: false);
    await EasyLoading.showToast(
      trimmedMessage,
      duration: _displayDuration,
      toastPosition: EasyLoadingToastPosition.top,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.none,
    );
  }

  static Future<void> dismiss() {
    return EasyLoading.dismiss();
  }

  /// 语义别名，当前与普通 Toast 使用同一视觉样式。
  static Future<void> showError(String message) {
    return show(message);
  }

  /// 语义别名，当前与普通 Toast 使用同一视觉样式。
  static Future<void> showSuccess(String message) {
    return show(message);
  }
}
