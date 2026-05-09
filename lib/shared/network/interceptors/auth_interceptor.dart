import 'package:dio/dio.dart';

import '../../auth/token_store.dart';
import '../../logging/app_logger.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  /// 在请求发出前补齐访问令牌，保证服务端能识别当前会话。
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.accessToken;
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  /// 统一记录 401 场景，并清理本地过期令牌。
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401) {
      AppLogger.instance.warn(
        'AUTH',
        '收到 401，准备清理本地登录态',
        context: <String, Object?>{
          'uri': err.requestOptions.uri.toString(),
          'method': err.requestOptions.method,
        },
      );
      _tokenStore.clear();
    }
    handler.next(err);
  }
}
