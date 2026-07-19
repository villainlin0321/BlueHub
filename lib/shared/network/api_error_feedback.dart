import 'api_exception.dart';

/// 提供页面层/控制器层统一的错误提示判断，避免重复 Toast。
class ApiErrorFeedback {
  ApiErrorFeedback._();

  static String? toastMessage(Object error) {
    return resolveMessageOrNull(error);
  }

  static String? resolveMessageOrNull(Object error) {
    if (error is ApiException) {
      final String message = error.message.trim();
      return message.isEmpty ? null : message;
    }
    final String message = normalizeMessageText(error.toString());
    return message.isEmpty ? null : message;
  }

  static String resolveMessage(Object error, {required String fallback}) {
    return resolveMessageOrNull(error) ?? fallback;
  }

  static String normalizeMessageText(String message) {
    final String normalized = message.trim();
    if (normalized.startsWith('Exception: ')) {
      return normalized.substring('Exception: '.length).trim();
    }
    return normalized.trim();
  }
}
