import 'dart:io';

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
}
