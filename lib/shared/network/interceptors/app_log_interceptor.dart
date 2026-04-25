import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({required this.enabled});

  final bool enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) return handler.next(options);

    final headers = Map<String, dynamic>.from(options.headers);
    if (headers.containsKey('Authorization')) {
      headers['Authorization'] = 'Bearer ***';
    }

    debugPrint('[HTTP] --> ${options.method} ${options.uri}');
    debugPrint('[HTTP] headers: ${jsonEncode(headers)}');
    if (options.data != null) {
      debugPrint('[HTTP] body: ${_safeJson(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);

    debugPrint('[HTTP] <-- ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('[HTTP] data: ${_safeJson(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) return handler.next(err);

    debugPrint('[HTTP] xx  ${err.type} ${err.requestOptions.uri}');
    debugPrint('[HTTP] status: ${err.response?.statusCode}');
    debugPrint('[HTTP] message: ${err.message}');
    handler.next(err);
  }
}

String _safeJson(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return value?.toString() ?? 'null';
  }
}

