import 'dart:convert';

import 'package:dio/dio.dart';

import '../../auth/auth_session_expiry_provider.dart';
import '../../auth/token_store.dart';
import '../../logging/app_logger.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore, this._sessionExpiryNotifier);

  final TokenStore _tokenStore;
  final AuthSessionExpiryNotifier _sessionExpiryNotifier;
  bool _didDispatchSessionExpired = false;

  @override
  /// 在请求发出前补齐访问令牌，保证服务端能识别当前会话。
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.accessToken;
    if (_didDispatchSessionExpired &&
        token != null &&
        token.trim().isNotEmpty) {
      _didDispatchSessionExpired = false;
    }
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  /// 对成功响应补做业务码检查，兼容服务端以 2xx 返回“登录已过期”。
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_extractBizCode(response.data) == 10002) {
      _dispatchSessionExpired(
        reason: 'session_expired_code_10002',
        context: <String, Object?>{
          'uri': response.requestOptions.uri.toString(),
          'method': response.requestOptions.method,
          'statusCode': response.statusCode,
        },
      );
    }
    handler.next(response);
  }

  @override
  /// 统一记录会话过期场景，并派发登录态失效事件。
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final int? code = _extractBizCode(err.response?.data);
    if (status == 401 || code == 10002) {
      _dispatchSessionExpired(
        reason: status == 401
            ? 'session_expired_http_401'
            : 'session_expired_code_10002',
        context: <String, Object?>{
          'uri': err.requestOptions.uri.toString(),
          'method': err.requestOptions.method,
          'statusCode': status,
          'code': code,
        },
      );
    }
    handler.next(err);
  }

  int? _extractBizCode(dynamic raw) {
    final Map<String, dynamic>? json = switch (raw) {
      Map<String, dynamic> value => value,
      String value => _tryParseJsonMap(value),
      _ => null,
    };
    return (json?['code'] as num?)?.toInt();
  }

  Map<String, dynamic>? _tryParseJsonMap(String raw) {
    final String normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _dispatchSessionExpired({
    required String reason,
    required Map<String, Object?> context,
  }) {
    if (_didDispatchSessionExpired) {
      return;
    }
    _didDispatchSessionExpired = true;
    AppLogger.instance.warn('AUTH', '检测到登录态已过期', context: context);
    _sessionExpiryNotifier.notifyExpired(reason: reason);
  }
}
