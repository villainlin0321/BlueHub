import 'dart:io';

import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证日志文件按天归档，避免同一天内多次启动生成过多零散文件。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('bluehub_app_logger_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory.path;
          }
          return tempDirectory.path;
        });
  });

  tearDownAll(() async {
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('AppLogger 当前会话日志文件名按天归档', () async {
    await AppLogger.instance.init();

    final String? currentLogFilePath = AppLogger.instance.currentLogFilePath;

    expect(currentLogFilePath, isNotNull);
    expect(
      currentLogFilePath!,
      matches(RegExp(r'bluehub_\d{8}\.log$')),
    );
  });

  test('AppLogger 普通日志按文本行格式落盘', () async {
    await AppLogger.instance.init();

    AppLogger.instance.info(
      'HTTP',
      'Dio 客户端初始化完成',
      context: <String, Object?>{'baseUrl': 'http://example.com'},
    );

    final String? logText = await AppLogger.instance.readCurrentLog();

    expect(logText, isNotNull);
    expect(
      logText,
      contains(
        RegExp(
          r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]\[info\] \[HTTP\] Dio 客户端初始化完成 baseUrl=http://example\.com',
        ),
      ),
    );
  });

  test('AppLogger 结构化事件按文本行格式落盘', () async {
    await AppLogger.instance.init();

    AppLogger.instance.logEvent(
      const AppLogEvent(
        level: AppLogLevel.info,
        layer: AppLogLayer.state,
        event: 'PROVIDER_UPDATED',
        message: 'Provider 状态已变化',
        result: AppLogResult.pending,
        context: <String, Object?>{
          'provider': 'loginFormProvider',
          'route': '/login',
        },
      ),
    );

    final String? logText = await AppLogger.instance.readCurrentLog();

    expect(logText, isNotNull);
    expect(
      logText,
      contains(
        RegExp(
          r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]\[info\] \[STATE\]\[PROVIDER_UPDATED\] Provider 状态已变化 result=pending provider=loginFormProvider route=/login',
        ),
      ),
    );
  });

  test('AppLogger HTTP 请求日志按多行块格式落盘', () async {
    await AppLogger.instance.init();

    AppLogger.instance.logEvent(
      const AppLogEvent(
        level: AppLogLevel.info,
        layer: AppLogLayer.http,
        event: 'HTTP_REQUEST_START',
        message: '发起请求',
        result: AppLogResult.pending,
        context: <String, Object?>{
          'method': 'GET',
          'uri': 'http://example.com/orders?page=1',
          'headers': <String, Object?>{
            'Accept': 'application/json',
            'Authorization': 'Bearer ***',
          },
          'query': <String, Object?>{'page': '1'},
          'httpPath': '/orders',
        },
      ),
    );

    final String? logText = await AppLogger.instance.readCurrentLog();

    expect(logText, isNotNull);
    expect(
      logText,
      contains(
        RegExp(
          r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]\[info\] \[http-request\] \[GET\] http://example\.com/orders\?page=1\n'
          r'Headers: \{\n'
          r'  "Accept": "application/json",\n'
          r'  "Authorization": "\*\*\*"\n'
          r'\}\n'
          r'Query: \{\n'
          r'  "page": "1"\n'
          r'\}',
          multiLine: true,
        ),
      ),
    );
  });

  test('AppLogger HTTP 响应日志按多行块格式落盘', () async {
    await AppLogger.instance.init();

    AppLogger.instance.logEvent(
      const AppLogEvent(
        level: AppLogLevel.info,
        layer: AppLogLayer.http,
        event: 'HTTP_REQUEST_SUCCESS',
        message: '请求成功',
        result: AppLogResult.success,
        context: <String, Object?>{
          'method': 'GET',
          'uri': 'http://example.com/orders?page=1',
          'statusCode': 200,
          'durationMs': 228,
          'data': <String, Object?>{
            'code': 0,
            'message': 'success',
            'data': <String, Object?>{'list': <Object?>[]},
          },
        },
      ),
    );

    final String? logText = await AppLogger.instance.readCurrentLog();

    expect(logText, isNotNull);
    expect(
      logText,
      contains(
        RegExp(
          r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]\[info\] \[http-response\] \[GET\] http://example\.com/orders\?page=1\n'
          r'Status: 200\n'
          r'Time: 228 ms\n'
          r'Message: success\n'
          r'Data: \{\n'
          r'  "code": 0,\n'
          r'  "message": "success",\n'
          r'  "data": \{\n'
          r'    "list": \[\]\n'
          r'  \}\n'
          r'\}',
          multiLine: true,
        ),
      ),
    );
  });
}
