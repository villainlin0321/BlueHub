import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/token_store.dart';
import 'app_config.dart';
import 'interceptors/app_log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

class DioFactory {
  DioFactory({required this.config, required this.tokenStore});

  final AppConfig config;
  final TokenStore tokenStore;

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

    dio.interceptors.add(AuthInterceptor(tokenStore));
    dio.interceptors.add(AppLogInterceptor(enabled: kDebugMode));

    return dio;
  }
}
