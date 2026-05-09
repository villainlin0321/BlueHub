import 'dart:convert';

import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({required this.enabled});

  final bool enabled;
  static const String _requestIdKey = 'app_log_request_id';
  static const String _requestStartAtKey = 'app_log_request_start_at';

  @override
  /// 记录请求发起时间、基础参数和脱敏后的请求体。
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }

    final requestId = _buildRequestId(options);
    options.extra[_requestIdKey] = requestId;
    options.extra[_requestStartAtKey] = DateTime.now().millisecondsSinceEpoch;

    AppLogger.instance.info(
      'HTTP',
      '发起请求',
      context: <String, Object?>{
        'requestId': requestId,
        'method': options.method,
        'uri': options.uri.toString(),
        'headers': headers,
        if (options.queryParameters.isNotEmpty)
          'query': options.queryParameters,
        if (options.data != null) 'body': _safeJson(options.data),
      },
    );
    handler.next(options);
  }

  @override
  /// 记录响应状态、耗时和返回摘要。
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);

    final requestOptions = response.requestOptions;
    AppLogger.instance.info(
      'HTTP',
      '请求成功',
      context: <String, Object?>{
        'requestId': requestOptions.extra[_requestIdKey]?.toString() ?? '',
        'method': requestOptions.method,
        'uri': requestOptions.uri.toString(),
        'statusCode': response.statusCode,
        'durationMs': _computeDurationMs(requestOptions),
        'data': _safeJson(response.data),
      },
    );
    handler.next(response);
  }

  @override
  /// 记录网络失败、HTTP 异常和 Dio 抛出的错误信息。
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);

    final requestOptions = err.requestOptions;
    AppLogger.instance.error(
      'HTTP',
      '请求失败',
      error: err,
      stackTrace: err.stackTrace,
      context: <String, Object?>{
        'requestId': requestOptions.extra[_requestIdKey]?.toString() ?? '',
        'method': requestOptions.method,
        'uri': requestOptions.uri.toString(),
        'type': err.type.name,
        'statusCode': err.response?.statusCode,
        'durationMs': _computeDurationMs(requestOptions),
        'message': err.message,
        'response': _safeJson(err.response?.data),
      },
    );
    handler.next(err);
  }
}

/// 将请求体安全序列化为字符串，避免日志阶段再次抛异常。
String _safeJson(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return value?.toString() ?? 'null';
  }
}

/// 生成单次请求标识，方便串联 request/response/error 三段日志。
String _buildRequestId(RequestOptions options) {
  return '${DateTime.now().microsecondsSinceEpoch}_${options.hashCode}';
}

/// 计算请求耗时，便于快速判断慢请求问题。
int? _computeDurationMs(RequestOptions options) {
  final startAt = options.extra[AppLogInterceptor._requestStartAtKey];
  if (startAt is! int) {
    return null;
  }
  return DateTime.now().millisecondsSinceEpoch - startAt;
}
