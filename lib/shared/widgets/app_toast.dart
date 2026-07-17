import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../network/api_error_feedback.dart';

/// Toast 显示位置，仅封装当前项目实际使用到的顶部与居中两种场景。
enum AppToastPosition { top, center }

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
  static const Duration _networkErrorWindow = Duration(milliseconds: 1800);
  static const Duration _duplicateToastWindow = Duration(milliseconds: 1800);
  static const AppToastPosition _defaultPosition = AppToastPosition.center;
  static DateTime? _lastNetworkErrorShownAt;
  static DateTime? _lastToastShownAt;
  static String? _lastToastMessage;

  /// 将项目内部位置枚举映射为 EasyLoading 的原生位置枚举。
  static EasyLoadingToastPosition _mapToastPosition(AppToastPosition position) {
    return switch (position) {
      AppToastPosition.center => EasyLoadingToastPosition.center,
      AppToastPosition.top => EasyLoadingToastPosition.top,
    };
  }

  /// 初始化 EasyLoading 的全局 Toast 样式。
  static void configure() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..maskType = EasyLoadingMaskType.none
      ..userInteractions = true
      ..dismissOnTap = false
      ..displayDuration = _displayDuration
      ..toastPosition = _mapToastPosition(_defaultPosition)
      ..backgroundColor = _backgroundColor
      ..textColor = _textColor
      ..indicatorColor = _textColor
      ..maskColor = Colors.transparent
      ..boxShadow = const <BoxShadow>[]
      ..radius = _radius
      ..fontSize = _fontSize
      ..contentPadding = _contentPadding;
  }

  /// 展示统一样式的文本 Toast，可按需指定显示位置。
  static Future<void> show(
    String message, {
    AppToastPosition position = _defaultPosition,
  }) async {
    if (ApiErrorFeedback.isAutoToastMessageText(message)) {
      return;
    }
    final String normalizedMessage = ApiErrorFeedback.normalizeMessageText(
      message,
    );
    if (normalizedMessage.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? lastShownAt = _lastToastShownAt;
    if (lastShownAt != null &&
        _lastToastMessage == normalizedMessage &&
        now.difference(lastShownAt) < _duplicateToastWindow) {
      return;
    }
    _lastToastShownAt = now;
    _lastToastMessage = normalizedMessage;
    await EasyLoading.dismiss(animation: false);
    await EasyLoading.showToast(
      normalizedMessage,
      duration: _displayDuration,
      toastPosition: _mapToastPosition(position),
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.none,
    );
  }

  static Future<void> dismiss() {
    return EasyLoading.dismiss();
  }

  /// 网络层业务错误提示专用入口：时间窗口内只放行首条失败提示。
  static Future<void> showFirstPriorityError(
    String message, {
    AppToastPosition position = _defaultPosition,
  }) async {
    final String trimmedMessage = ApiErrorFeedback.normalizeMessageText(message);
    if (trimmedMessage.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? lastShownAt = _lastNetworkErrorShownAt;
    if (lastShownAt != null &&
        now.difference(lastShownAt) < _networkErrorWindow) {
      return;
    }
    _lastNetworkErrorShownAt = now;
    await show(trimmedMessage, position: position);
  }

  /// 语义别名，当前与普通 Toast 使用同一视觉样式。
  static Future<void> showError(
    String message, {
    AppToastPosition position = _defaultPosition,
  }) {
    return show(message, position: position);
  }

  /// 语义别名，当前与普通 Toast 使用同一视觉样式。
  static Future<void> showSuccess(
    String message, {
    AppToastPosition position = _defaultPosition,
  }) {
    return show(message, position: position);
  }
}
