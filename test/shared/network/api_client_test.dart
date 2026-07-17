import 'package:dio/dio.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTTP 错误时优先展示响应体中的业务 message', () async {
    final Dio dio = Dio()
      ..httpClientAdapter = _FakeHttpClientAdapter(
        handler: (RequestOptions options) async {
          return ResponseBody.fromString(
            '{"code":10006,"message":"访问过于频繁，请稍候再试","data":null}',
            429,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
            statusMessage: 'Too Many Requests',
          );
        },
      );
    final ApiClient apiClient = ApiClient(dio);

    await expectLater(
      () => apiClient.post<Map<String, int>>(
        '/auth/email/send',
        data: <String, dynamic>{'email': 'foo@example.com', 'scene': 'login'},
        decode: (dynamic data) => <String, int>{},
      ),
      throwsA(
        isA<ApiException>()
            .having(
              (ApiException error) => error.type,
              'type',
              ApiExceptionType.http,
            )
            .having(
              (ApiException error) => error.message,
              'message',
              '访问过于频繁，请稍候再试',
            )
            .having(
              (ApiException error) => error.statusCode,
              'statusCode',
              429,
            ),
      ),
    );
  });
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this.handler});

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<void> close({bool force = false}) async {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}
