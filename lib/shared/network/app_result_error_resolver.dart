import 'package:easy_localization/easy_localization.dart';

/// 统一解析 AppResult 业务失败的展示文案。
class AppResultErrorResolver {
  AppResultErrorResolver._();

  /// 优先透传后端自然语言 message，必要时再走前端兜底。
  static String resolve({required int code, required String message}) {
    final String normalizedMessage = message.trim();
    if (_isDisplayableMessage(normalizedMessage)) {
      return normalizedMessage;
    }
    final String? fallback = _fallbackMessageForCode(code);
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }
    return tr('通用.业务异常');
  }

  static bool _isDisplayableMessage(String message) {
    if (message.isEmpty) {
      return false;
    }
    return !_looksLikeI18nKey(message);
  }

  static bool _looksLikeI18nKey(String message) {
    return RegExp(r'^[a-z0-9]+(\.[a-z0-9_]+)+$').hasMatch(message);
  }

  static String? _fallbackMessageForCode(int code) {
    return switch (code) {
      70002 => 'AI 对话频次受限（每天/每分钟）',
      _ => null,
    };
  }
}
