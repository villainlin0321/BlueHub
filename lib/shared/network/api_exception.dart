import 'package:easy_localization/easy_localization.dart';

enum ApiExceptionType { network, http, biz, parse, unknown }

class ApiException implements Exception {
  ApiException(
    this.type, {
    required this.message,
    this.statusCode,
    this.code,
    this.requestId,
    this.hasShownToast = false,
    this.original,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final int? code;
  final String? requestId;
  final bool hasShownToast;
  final Object? original;

  @override
  String toString() {
    return 'ApiException(type=$type, statusCode=$statusCode, code=$code, requestId=$requestId, hasShownToast=$hasShownToast, message=$message)';
  }

  static ApiException network(Object error) => ApiException(
    ApiExceptionType.network,
    message: tr('通用.网络异常'),
    original: error,
  );

  static ApiException http({
    required int? statusCode,
    required String message,
    Object? original,
  }) => ApiException(
    ApiExceptionType.http,
    message: message,
    statusCode: statusCode,
    original: original,
  );

  static ApiException biz({
    required int code,
    required String message,
    String? requestId,
    bool hasShownToast = false,
  }) => ApiException(
    ApiExceptionType.biz,
    message: message.isEmpty ? tr('通用.业务异常') : message,
    code: code,
    requestId: requestId,
    hasShownToast: hasShownToast,
  );

  static ApiException parse(Object error) => ApiException(
    ApiExceptionType.parse,
    message: tr('通用.数据解析失败'),
    original: error,
  );

  static ApiException unknown(Object error) => ApiException(
    ApiExceptionType.unknown,
    message: tr('通用.未知错误'),
    original: error,
  );

  bool get shouldShowToast => !hasShownToast && message.trim().isNotEmpty;
}
