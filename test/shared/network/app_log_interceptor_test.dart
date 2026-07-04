import 'package:dio/dio.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/network/interceptors/app_log_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLogInterceptor 会把 traceId、route 和业务动作写入请求上下文', () {
    final options = RequestOptions(path: '/jobs');

    AppLogScope.run(
      traceId: 'trace-post-job',
      fields: const <String, Object?>{
        'route': '/jobs/post',
        'action': 'POST_JOB_SUBMIT_TAP',
      },
      action: () {
        final interceptor = AppLogInterceptor(enabled: true);
        interceptor.onRequest(options, RequestInterceptorHandler());
      },
    );

    expect(options.extra['traceId'], 'trace-post-job');
    expect(options.extra['route'], '/jobs/post');
    expect(options.extra['logAction'], 'POST_JOB_SUBMIT_TAP');
  });
}
