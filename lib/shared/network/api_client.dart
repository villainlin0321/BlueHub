import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';
import 'api_exception.dart';
import 'api_result.dart';

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
      final res = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
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
      final res = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
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
      throw ApiException.biz(
        code: result.code,
        message: result.message,
        requestId: result.requestId,
      );
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
      throw ApiException.biz(
        code: result.code,
        message: result.message,
        requestId: result.requestId,
      );
    }
  }

  ApiException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      // #region debug-point B:native-probe-for-failed-url
      unawaited(_runNativeProbeForFailedUrl(e.requestOptions.uri.toString()));
      // #endregion
    }
    if (e.response != null) {
      return ApiException.http(
        statusCode: e.response?.statusCode,
        message: e.response?.statusMessage ?? tr('通用.HTTP请求失败'),
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

  /// 当 Dart 网络栈连接失败时，使用 iOS 原生 URLSession 对同一 URL 再探测一次。
  Future<void> _runNativeProbeForFailedUrl(String url) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      final Map<Object?, Object?>? result =
          await _nativeDebugChannel.invokeMapMethod<Object?, Object?>(
            'probeHttp',
            <String, Object?>{'url': url},
          );
      AppLogger.instance.info(
        'NATIVE_HTTP',
        'Dio 失败后 iOS 原生同 URL 探针完成',
        context: <String, Object?>{
          'target': url,
          'result': result?.map(
                (Object? key, Object? value) =>
                    MapEntry(key.toString(), value),
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
