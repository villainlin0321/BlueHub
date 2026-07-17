import 'api_exception.dart';

/// 提供页面层/控制器层统一的错误提示判断，避免重复 Toast。
class ApiErrorFeedback {
  ApiErrorFeedback._();

  static final RegExp _stringifiedApiExceptionPattern = RegExp(
    r'^ApiException\(type=.*?, statusCode=.*?, code=.*?, requestId=.*?, hasShownToast=(true|false), message=(.*)\)$',
    dotAll: true,
  );

  static bool hasAutoToast(Object error) {
    return error is ApiException && error.hasShownToast;
  }

  static String? toastMessage(Object error) {
    if (error is ApiException && error.shouldShowToast) {
      final String message = error.message.trim();
      return message.isEmpty ? null : message;
    }
    return null;
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
    final _ParsedApiExceptionText? parsed = _parseStringifiedApiException(
      message,
    );
    final String normalized = parsed?.message ?? message.trim();
    if (normalized.startsWith('Exception: ')) {
      return normalized.substring('Exception: '.length).trim();
    }
    return normalized.trim();
  }

  static bool isAutoToastMessageText(String message) {
    return _parseStringifiedApiException(message)?.hasShownToast ?? false;
  }

  static _ParsedApiExceptionText? _parseStringifiedApiException(String message) {
    final RegExpMatch? match = _stringifiedApiExceptionPattern.firstMatch(
      message.trim(),
    );
    if (match == null) {
      return null;
    }
    return _ParsedApiExceptionText(
      hasShownToast: match.group(1) == 'true',
      message: match.group(2)?.trim() ?? '',
    );
  }
}

class _ParsedApiExceptionText {
  const _ParsedApiExceptionText({
    required this.hasShownToast,
    required this.message,
  });

  final bool hasShownToast;
  final String message;
}
