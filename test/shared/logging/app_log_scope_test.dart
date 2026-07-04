import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证结构化日志事件与作用域上下文的基础行为。
void main() {
  test('AppLogScope 会合并父子上下文并在退出后恢复父作用域', () {
    AppLogScope.run(
      sessionId: 'session-1',
      fields: const <String, Object?>{'route': '/login'},
      action: () {
        AppLogScope.run(
          traceId: 'trace-1',
          fields: const <String, Object?>{'module': 'auth'},
          action: () {
            final Map<String, Object?> scope = AppLogScope.current;
            expect(scope['sessionId'], 'session-1');
            expect(scope['traceId'], 'trace-1');
            expect(scope['route'], '/login');
            expect(scope['module'], 'auth');
          },
        );

        expect(AppLogScope.current['traceId'], isNull);
        expect(AppLogScope.current['route'], '/login');
      },
    );
  });

  test('AppLogEvent.toJson 会保留结构化字段并脱敏敏感键', () {
    const AppLogEvent event = AppLogEvent(
      level: AppLogLevel.info,
      layer: AppLogLayer.http,
      event: 'AUTH_LOGIN_REQUEST',
      message: '登录请求开始',
      context: <String, Object?>{
        'token': 'abc',
        'phone': '13800000000',
        'email': 'debugger@example.com',
        'module': 'auth',
      },
    );

    final Map<String, Object?> json = event.toJson();
    final Map<String, Object?> context =
        json['context']! as Map<String, Object?>;
    expect(json['layer'], 'HTTP');
    expect(context['token'], '***');
    expect(context['phone'], '***');
    expect(context['email'], '***');
    expect(context['module'], 'auth');
  });

  test('AppLogScope 会在异步边界内继续保留当前链路上下文', () async {
    await AppLogScope.run<Future<void>>(
      sessionId: 'session-async',
      traceId: 'trace-async',
      fields: const <String, Object?>{'route': '/message'},
      action: () async {
        await Future<void>.delayed(Duration.zero);
        final Map<String, Object?> scope = AppLogScope.current;
        expect(scope['sessionId'], 'session-async');
        expect(scope['traceId'], 'trace-async');
        expect(scope['route'], '/message');
      },
    );
  });
}
