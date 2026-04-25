import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_result.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _unwrap<T>(res.data, decode: decode);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _unwrap<T>(res.data, decode: decode);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  T _unwrap<T>(
    dynamic raw, {
    required T Function(dynamic data) decode,
  }) {
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

  ApiException _mapDioException(DioException e) {
    if (e.response != null) {
      return ApiException.http(
        statusCode: e.response?.statusCode,
        message: e.response?.statusMessage ?? 'HTTP 请求失败',
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
}
