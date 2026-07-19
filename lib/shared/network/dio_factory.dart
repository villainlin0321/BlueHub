import 'package:dio/dio.dart';

import '../auth/auth_session_expiry_provider.dart';
import '../auth/token_store.dart';
import '../localization/app_language_store.dart';
import '../logging/app_logger.dart';
import 'app_config.dart';
import 'interceptors/app_log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/language_interceptor.dart';

class DioFactory {
  DioFactory({
    required this.config,
    required this.tokenStore,
    required this.sessionExpiryNotifier,
    required this.languageStore,
  });

  final AppConfig config;
  final TokenStore tokenStore;
  final AuthSessionExpiryNotifier sessionExpiryNotifier;
  final AppLanguageStore languageStore;

  /// 创建全局共享的 Dio 实例，并挂接鉴权与日志拦截器。
  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(tokenStore, sessionExpiryNotifier));
    dio.interceptors.add(LanguageInterceptor(languageStore));
    dio.interceptors.add(AppLogInterceptor(enabled: true));
    AppLogger.instance.info(
      'HTTP',
      'Dio 客户端初始化完成',
      context: <String, Object?>{'baseUrl': config.baseUrl},
    );

    return dio;
  }
}
