import 'dart:convert';
import 'dart:io';

import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/logging/app_provider_observer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证 Provider 观察器既不会吞掉关键状态更新，也会输出可回放的字段快照。
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

  test('AppProviderObserver 会为 AuthSessionState 输出可回放的结构化快照', () async {
    final container = ProviderContainer(
      observers: const <ProviderObserver>[AppProviderObserver()],
    );
    addTearDown(container.dispose);

    final listener = container.listen<AuthSessionState>(
      authSessionObserverTestProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(listener.close);

    final nextState = AuthSessionState(
      user: const AuthUser(
        userId: 42,
        phone: '+8613800138000',
        countryCode: '86',
        email: 'debugger@example.com',
        nickname: 'BlueHub Tester',
        avatarUrl: 'https://example.com/avatar.png',
        role: 'worker',
        gender: 'female',
        birthday: '1990-01-01',
        currentLocation: 'Shanghai',
        isVerified: true,
      ),
      isAuthenticated: true,
      isHydrating: false,
      needSelectRole: true,
    );
    container.read(authSessionObserverTestProvider.notifier).state = nextState;
    container
        .read(authSessionObserverTestProvider.notifier)
        .state = AuthSessionState(
      user: nextState.user,
      isAuthenticated: nextState.isAuthenticated,
      isHydrating: nextState.isHydrating,
      needSelectRole: nextState.needSelectRole,
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
    final Map<String, Object?> context = Map<String, Object?>.from(
      matchedEntries.single['context']! as Map,
    );
    final Map<String, Object?> previousSnapshot = Map<String, Object?>.from(
      context['previous']! as Map,
    );
    final Map<String, Object?> nextSnapshot = Map<String, Object?>.from(
      context['next']! as Map,
    );
    final Map<String, Object?> nextUserSnapshot = Map<String, Object?>.from(
      nextSnapshot['user']! as Map,
    );

    expect(previousSnapshot['isAuthenticated'], 'false');
    expect(previousSnapshot['isHydrating'], 'true');
    expect(previousSnapshot['needSelectRole'], 'false');
    expect(previousSnapshot['user'], isNull);
    expect(nextSnapshot['isAuthenticated'], 'true');
    expect(nextSnapshot['isHydrating'], 'false');
    expect(nextSnapshot['needSelectRole'], 'true');
    expect(nextUserSnapshot['userId'], '42');
    expect(nextUserSnapshot['phone'], '+8613800138000');
    expect(nextUserSnapshot['email'], 'debugger@example.com');
    expect(nextUserSnapshot['role'], 'worker');
  });
}

final authSessionObserverTestProvider =
    NotifierProvider<_AuthSessionNotifier, AuthSessionState>(
      _AuthSessionNotifier.new,
      name: 'authSessionObserverTestProvider',
    );

/// 提供真实 `AuthSessionState` 的可控更新入口，便于稳定验证日志快照内容。
class _AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  /// 构建一份初始登录态，模拟应用启动时的会话恢复中场景。
  AuthSessionState build() {
    return const AuthSessionState(isHydrating: true);
  }
}
