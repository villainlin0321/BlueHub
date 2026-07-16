import 'api_exception.dart';

/// 提供页面层/控制器层统一的错误提示判断，避免重复 Toast。
class ApiErrorFeedback {
  ApiErrorFeedback._();

  static bool hasAutoToast(Object error) {
    return error is ApiException && error.hasShownToast;
  }

  static String? toastMessage(Object error) {
    if (error is ApiException && error.shouldShowToast) {
      return error.message;
    }
    return null;
  }

  static String resolveMessage(Object error, {required String fallback}) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }
}
