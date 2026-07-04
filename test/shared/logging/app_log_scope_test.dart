import 'dart:convert';
import 'dart:io';

import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证结构化日志事件与作用域上下文的基础行为。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;

  /// 读取当前日志文件中的 JSON 行，便于针对真实落盘结果做断言。
  Future<List<Map<String, Object?>>> readJsonLogEntries() async {
    final String? content = await AppLogger.instance.readCurrentLog();
    if (content == null || content.trim().isEmpty) {
      return <Map<String, Object?>>[];
    }

    return content
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .map((String line) {
          final Object? decoded = jsonDecode(line);
          return Map<String, Object?>.from(decoded! as Map<dynamic, dynamic>);
        })
        .toList();
  }

  /// 等待异步文件写入完成，避免刚写完就读取导致断言不稳定。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('bluehub_logger_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory.path;
          }
          return tempDirectory.path;
        });
    await AppLogger.instance.init();
    await waitForLogFlush();
  });

  tearDownAll(() async {
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

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
        'module': 'auth',
      },
    );

    final Map<String, Object?> json = event.toJson();
    expect(json['layer'], 'HTTP');
    expect((json['context']! as Map<String, Object?>)['token'], '***');
    expect((json['context']! as Map<String, Object?>)['module'], 'auth');
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

  test('AppLogger.logEvent 会把合并后的作用域和脱敏后的上下文写入日志文件', () async {
    final String eventName =
        'AUTH_LOGIN_RESULT_${DateTime.now().microsecondsSinceEpoch}';

    await AppLogScope.run<Future<void>>(
      sessionId: 'session-file',
      traceId: 'trace-file',
      fields: const <String, Object?>{'route': '/login'},
      action: () async {
        AppLogger.instance.logEvent(
          AppLogEvent(
            level: AppLogLevel.info,
            layer: AppLogLayer.http,
            event: eventName,
            message: '登录请求完成',
            result: AppLogResult.success,
            context: const <String, Object?>{
              'module': 'auth',
              'token': 'secret-token',
            },
          ),
        );
        await waitForLogFlush();
      },
    );

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final Map<String, Object?> entry = entries.lastWhere(
      (Map<String, Object?> item) => item['event'] == eventName,
    );
    final Map<String, Object?> context =
        Map<String, Object?>.from(entry['context']! as Map<dynamic, dynamic>);

    expect(entry['layer'], 'HTTP');
    expect(entry['event'], eventName);
    expect(entry['result'], 'success');
    expect(context['sessionId'], 'session-file');
    expect(context['traceId'], 'trace-file');
    expect(context['route'], '/login');
    expect(context['module'], 'auth');
    expect(context['token'], '***');
  });

  test('AppLogger.logEvent 会对高频重复结构化事件做窗口去重', () async {
    final String eventName =
        'AUTH_DUPLICATE_${DateTime.now().microsecondsSinceEpoch}';

    for (int index = 0; index < 5; index++) {
      AppLogger.instance.logEvent(
        AppLogEvent(
          level: AppLogLevel.info,
          layer: AppLogLayer.state,
          event: eventName,
          message: '重复状态变更',
          result: AppLogResult.pending,
          context: const <String, Object?>{
            'module': 'auth',
            'status': 'polling',
          },
        ),
      );
    }
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries
        .where((Map<String, Object?> item) => item['event'] == eventName)
        .toList();

    expect(matchedEntries, hasLength(3));
  });
}
