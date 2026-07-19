import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_log_scope.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';
import 'api_result.dart';
import 'app_result_error_resolver.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;
  static const MethodChannel _nativeDebugChannel = MethodChannel(
    'bluehub/app_icon',
  );

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    return _request<T>(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      decode: decode,
      options: options,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    return _request<T>(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      decode: decode,
      options: options,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    return _request<T>(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      decode: decode,
      options: options,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    return _request<T>(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      decode: decode,
      options: options,
    );
  }

  Future<void> getVoid(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestVoid(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> postVoid(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestVoid(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> putVoid(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestVoid(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> deleteVoid(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _requestVoid(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<T> _request<T>({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    try {
      final requestOptions = _buildRequestOptions(
        method: method,
        path: path,
        options: options,
      );
      final res = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      return _unwrap<T>(res.data, decode: decode);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ApiException {
      // 关键保护：已完成分类的业务异常/解析异常直接透传，不再包成 unknown。
      rethrow;
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  Future<void> _requestVoid({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final requestOptions = _buildRequestOptions(
        method: method,
        path: path,
        options: options,
      );
      final res = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      _unwrapVoid(res.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on ApiException {
      // 关键保护：已完成分类的业务异常/解析异常直接透传，不再包成 unknown。
      rethrow;
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  T _unwrap<T>(dynamic raw, {required T Function(dynamic data) decode}) {
    if (raw is! Map<String, dynamic>) {
      throw ApiException.parse(raw ?? 'null');
    }

    final result = ApiResult.fromJson<T>(raw, decode: decode);
    if (!result.isSuccess) {
      throw _buildBizException(result);
    }

    final data = result.data;
    if (data == null) {
      throw ApiException.parse('data is null');
    }
    return data;
  }

  void _unwrapVoid(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw ApiException.parse(raw ?? 'null');
    }

    final result = ApiResult.fromJson<void>(raw, decode: (_) {});
    if (!result.isSuccess) {
      throw _buildBizException(result);
    }
  }

  ApiException _buildBizException(ApiResult<dynamic> result) {
    final String message = AppResultErrorResolver.resolve(
      code: result.code,
      message: result.message,
    );
    return ApiException.biz(
      code: result.code,
      message: message,
      requestId: result.requestId,
    );
  }

  ApiException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      // #region debug-point B:native-probe-for-failed-url
      unawaited(_runNativeProbeForFailedUrl(e.requestOptions.uri.toString()));
      // #endregion
    }
    if (e.response != null) {
      final String? responseMessage = _extractResponseErrorMessage(
        e.response?.data,
      );
      return ApiException.http(
        statusCode: e.response?.statusCode,
        message:
            responseMessage ?? e.response?.statusMessage ?? tr('通用.HTTP请求失败'),
        original: e,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException.network(e);
    }
    return ApiException.unknown(e);
  }

  String? _extractResponseErrorMessage(dynamic responseData) {
    final Map<String, dynamic>? json = switch (responseData) {
      Map<String, dynamic> value => value,
      String value => _tryParseJsonMap(value),
      _ => null,
    };
    if (json == null) {
      return null;
    }
    final int code = (json['code'] as num?)?.toInt() ?? -1;
    final String message = (json['message'] as String?) ?? '';
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty && code != 70002) {
      return null;
    }
    if (_looksLikeI18nKey(normalizedMessage) && code != 70002) {
      return null;
    }
    final String resolvedMessage = AppResultErrorResolver.resolve(
      code: code,
      message: message,
    );
    return resolvedMessage.trim().isEmpty ? null : resolvedMessage;
  }

  Map<String, dynamic>? _tryParseJsonMap(String value) {
    final String normalized = value.trim();
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

  bool _looksLikeI18nKey(String message) {
    return RegExp(r'^[a-z0-9]+(\.[a-z0-9_]+)+$').hasMatch(message);
  }

  /// 构建带链路透传信息的请求配置，避免只有拦截器层知道当前请求入口。
  Options _buildRequestOptions({
    required String method,
    required String path,
    Options? options,
  }) {
    final extra = _buildRequestExtra(options?.extra, path: path);
    return (options ?? Options()).copyWith(method: method, extra: extra);
  }

  /// 合并调用方 extra 与当前作用域字段，只透传最小必要上下文。
  Map<String, dynamic> _buildRequestExtra(
    Map<String, dynamic>? extra, {
    required String path,
  }) {
    final mergedExtra = <String, dynamic>{...?extra};
    final scope = AppLogScope.current;

    // 关键逻辑：公共请求入口先补齐路径和链路字段，保证后续拦截器与异常映射可复用。
    mergedExtra.putIfAbsent('httpPath', () => path);
    _putIfAbsentAndNotEmpty(mergedExtra, 'traceId', scope['traceId']);
    _putIfAbsentAndNotEmpty(mergedExtra, 'route', scope['route']);
    _putIfAbsentAndNotEmpty(mergedExtra, 'logAction', scope['action']);
    return mergedExtra;
  }

  /// 仅在目标字段缺失且候选值有效时写入 extra，避免覆盖业务层显式传值。
  void _putIfAbsentAndNotEmpty(
    Map<String, dynamic> extra,
    String key,
    Object? value,
  ) {
    if (extra.containsKey(key)) {
      return;
    }
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return;
    }
    extra[key] = text;
  }

  /// 当 Dart 网络栈连接失败时，使用 iOS 原生 URLSession 对同一 URL 再探测一次。
  Future<void> _runNativeProbeForFailedUrl(String url) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      final Map<Object?, Object?>? result = await _nativeDebugChannel
          .invokeMapMethod<Object?, Object?>('probeHttp', <String, Object?>{
            'url': url,
          });
      AppLogger.instance.info(
        'NATIVE_HTTP',
        'Dio 失败后 iOS 原生同 URL 探针完成',
        context: <String, Object?>{
          'target': url,
          'result':
              result?.map(
                (Object? key, Object? value) => MapEntry(key.toString(), value),
              ) ??
              <String, Object?>{},
        },
      );
    } on PlatformException catch (error, stackTrace) {
      AppLogger.instance.error(
        'NATIVE_HTTP',
        'Dio 失败后原生同 URL 探针调用失败',
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{'target': url},
      );
    }
  }
}
