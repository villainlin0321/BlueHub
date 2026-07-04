import 'dart:convert';

import 'package:dio/dio.dart';

import '../../logging/app_log_facade.dart';
import '../../logging/app_log_scope.dart';
import '../../logging/app_route_tracker.dart';

class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({required this.enabled});

  final bool enabled;
  static const String _requestIdKey = 'app_log_request_id';
  static const String _requestStartAtKey = 'app_log_request_start_at';
  static const String _traceIdKey = 'traceId';
  static const String _routeKey = 'route';
  static const String _logActionKey = 'logAction';

  @override
  /// 记录请求发起时间、基础参数和脱敏后的请求体。
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);

    final requestId = _buildRequestId(options);
    options.extra[_requestIdKey] = requestId;
    options.extra[_requestStartAtKey] = DateTime.now().millisecondsSinceEpoch;
    _attachScopeContext(options);

    HttpFlowLog.requestStart(
      requestId: requestId,
      method: options.method,
      uri: options.uri.toString(),
      context: _buildRequestLogContext(options),
    );
    handler.next(options);
  }

  @override
  /// 记录响应状态、耗时和返回摘要。
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);

    final requestOptions = response.requestOptions;
    HttpFlowLog.requestSuccess(
      requestId: _readRequestId(requestOptions),
      method: requestOptions.method,
      uri: requestOptions.uri.toString(),
      statusCode: response.statusCode,
      durationMs: _computeDurationMs(requestOptions),
      context: <String, Object?>{
        ..._buildChainContext(requestOptions),
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
    HttpFlowLog.requestFail(
      requestId: _readRequestId(requestOptions),
      method: requestOptions.method,
      uri: requestOptions.uri.toString(),
      error: err,
      stackTrace: err.stackTrace,
      errorType: err.type.name,
      statusCode: err.response?.statusCode,
      durationMs: _computeDurationMs(requestOptions),
      context: <String, Object?>{
        ..._buildChainContext(requestOptions),
        'statusCode': err.response?.statusCode,
        'message': err.message,
        'response': _safeJson(err.response?.data),
      },
    );
    handler.next(err);
  }
}

/// 将当前作用域与路由追踪器中的链路字段写入请求上下文，避免后续阶段断链。
void _attachScopeContext(RequestOptions options) {
  final scope = AppLogScope.current;
  final traceId = _firstNonEmptyString(
    options.extra[AppLogInterceptor._traceIdKey],
    scope[AppLogInterceptor._traceIdKey],
  );
  final route = _firstNonEmptyString(
    options.extra[AppLogInterceptor._routeKey],
    scope[AppLogInterceptor._routeKey],
    AppRouteTracker.instance.currentRoute,
  );
  final action = _firstNonEmptyString(
    options.extra[AppLogInterceptor._logActionKey],
    options.extra['action'],
    scope['action'],
  );

  // 关键逻辑：只在链路字段有效时写入 extra，避免空值污染请求上下文。
  if (traceId != null) {
    options.extra[AppLogInterceptor._traceIdKey] = traceId;
  }
  if (route != null) {
    options.extra[AppLogInterceptor._routeKey] = route;
  }
  if (action != null) {
    options.extra[AppLogInterceptor._logActionKey] = action;
  }
}

/// 构建请求开始日志的上下文，保留脱敏后的入参摘要与链路字段。
Map<String, Object?> _buildRequestLogContext(RequestOptions options) {
  final headers = Map<String, dynamic>.from(options.headers);
  if (headers.containsKey('Authorization')) {
    headers['Authorization'] = 'Bearer ***';
  }
  return <String, Object?>{
    ..._buildChainContext(options),
    'headers': headers,
    if (options.queryParameters.isNotEmpty) 'query': options.queryParameters,
    if (options.data != null) 'body': _safeJson(options.data),
    if (options.extra['httpPath'] != null) 'httpPath': options.extra['httpPath'],
  };
}

/// 读取请求沿途要复用的链路字段，确保 request/response/error 三段日志一致。
Map<String, Object?> _buildChainContext(RequestOptions options) {
  return <String, Object?>{
    if (_readExtraString(options, AppLogInterceptor._traceIdKey) != null)
      AppLogInterceptor._traceIdKey:
          _readExtraString(options, AppLogInterceptor._traceIdKey),
    if (_readExtraString(options, AppLogInterceptor._routeKey) != null)
      AppLogInterceptor._routeKey:
          _readExtraString(options, AppLogInterceptor._routeKey),
    if (_readExtraString(options, AppLogInterceptor._logActionKey) != null)
      'action':
          _readExtraString(options, AppLogInterceptor._logActionKey),
  };
}

/// 返回请求 ID，缺失时回退为空串，避免日志字段类型不稳定。
String _readRequestId(RequestOptions options) {
  return _readExtraString(options, AppLogInterceptor._requestIdKey) ?? '';
}

/// 从 `RequestOptions.extra` 中读取非空字符串字段。
String? _readExtraString(RequestOptions options, String key) {
  return _firstNonEmptyString(options.extra[key]);
}

/// 将请求体安全序列化为字符串，避免日志阶段再次抛异常。
String _safeJson(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return value?.toString() ?? 'null';
  }
}

/// 从多个候选值中选择第一个有效字符串，统一处理空白和空串。
String? _firstNonEmptyString(Object? first, [Object? second, Object? third]) {
  final values = <Object?>[first, second, third];
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
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
