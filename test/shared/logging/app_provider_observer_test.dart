import 'dart:convert';
import 'dart:io';

import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/logging/app_provider_observer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证 Provider 观察器不会因为相同的 `toString()` 文本而吞掉关键状态更新。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;

  /// 读取当前日志文件中的结构化日志，便于直接断言观察器真实输出。
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

  /// 等待异步日志写入落盘，避免读取过早导致断言抖动。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_provider_observer_test_',
    );
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

  test('AppProviderObserver 不会把同文本快照的鉴权状态更新当成噪音丢弃', () async {
    final container = ProviderContainer(
      observers: const <ProviderObserver>[AppProviderObserver()],
    );
    addTearDown(container.dispose);

    final listener = container.listen<_FakeAuthSessionState>(
      authSessionObserverTestProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(listener.close);

    container.read(authSessionObserverTestProvider.notifier).state =
        const _FakeAuthSessionState(
          isAuthenticated: true,
          isHydrating: false,
        );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries
        .where(
          (Map<String, Object?> item) =>
              item['event'] == 'PROVIDER_UPDATED' &&
              (item['context'] as Map<String, Object?>?)?['provider']
                      ?.toString()
                      .contains('authSessionObserverTestProvider') ==
                  true,
        )
        .toList();

    expect(matchedEntries, hasLength(1));
  });
}

final authSessionObserverTestProvider =
    NotifierProvider<_FakeAuthSessionNotifier, _FakeAuthSessionState>(
      _FakeAuthSessionNotifier.new,
      name: 'authSessionObserverTestProvider',
    );

/// 构造一个与 `AuthSessionState` 一样缺少自定义 `toString()` 的状态对象，用于复现误吞日志问题。
class _FakeAuthSessionState {
  const _FakeAuthSessionState({
    this.isAuthenticated = false,
    this.isHydrating = false,
  });

  final bool isAuthenticated;
  final bool isHydrating;
}

/// 提供可控状态更新入口，便于在测试里稳定复现观察器回调。
class _FakeAuthSessionNotifier extends Notifier<_FakeAuthSessionState> {
  @override
  /// 构建一份初始登录态，模拟应用启动时的会话恢复中场景。
  _FakeAuthSessionState build() {
    return const _FakeAuthSessionState(isHydrating: true);
  }
}
