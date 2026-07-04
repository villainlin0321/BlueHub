import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';
import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
import 'package:europepass/features/me/data/user_models.dart';
import 'package:europepass/features/me/data/user_providers.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:europepass/shared/network/services/user_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证鉴权恢复与刷新链路会输出可回放日志，并继续遵守统一脱敏规则。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;

  /// 读取当前日志文件中的结构化日志，便于断言事件名和上下文字段。
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

  /// 读取日志原文，确保 token 等敏感值不会被明文写入文件。
  Future<String> readRawLogContent() async {
    return await AppLogger.instance.readCurrentLog() ?? '';
  }

  /// 等待异步日志刷盘，避免读取到中间状态导致断言抖动。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 从结构化日志中安全读取上下文字段。
  Map<String, Object?> readContext(Map<String, Object?> entry) {
    return Map<String, Object?>.from(entry['context']! as Map);
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_auth_session_logging_test_',
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

  test('restoreSession 会输出开始和成功事件', () async {
    final tokenStore = TokenStore.inMemory()
      ..setTokens(accessToken: 'token-1', refreshToken: 'refresh-token-1');
    final container = ProviderContainer(
      overrides: [
        userServiceProvider.overrideWithValue(_FakeUserService.success()),
        tokenStoreProvider.overrideWithValue(tokenStore),
      ],
    );
    addTearDown(container.dispose);

    await AppLogScope.run<Future<void>>(
      traceId: 'test-auth-restore-success',
      fields: const <String, Object?>{'testCase': 'restore_success'},
      action: () {
        return container.read(authSessionProvider.notifier).restoreSession();
      },
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries.where((
      Map<String, Object?> item,
    ) {
      final Map<String, Object?>? context =
          item['context'] as Map<String, Object?>?;
      return context?['traceId'] == 'test-auth-restore-success' &&
          (item['event'] == 'AUTH_RESTORE_START' ||
              item['event'] == 'AUTH_RESTORE_SUCCESS');
    }).toList();

    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'AUTH_RESTORE_START';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'AUTH_RESTORE_SUCCESS';
      }),
      isTrue,
    );

    final Map<String, Object?> successContext = readContext(
      matchedEntries.lastWhere(
        (Map<String, Object?> item) => item['event'] == 'AUTH_RESTORE_SUCCESS',
      ),
    );
    expect(successContext['from'], 'hydrating');
    expect(successContext['to'], 'authenticated_ready');
    expect(successContext['userId'], '42');
    expect(successContext['role'], 'worker');
    expect(successContext['needSelectRole'], 'false');
    expect(await readRawLogContent(), isNot(contains('token-1')));
    expect(await readRawLogContent(), isNot(contains('refresh-token-1')));
  });

  test('refreshCurrentUser 失败时会输出开始和失败事件，并回退到登录态快照', () async {
    final tokenStore = TokenStore.inMemory();
    final container = ProviderContainer(
      overrides: [
        userServiceProvider.overrideWithValue(_FakeUserService.failure()),
        tokenStoreProvider.overrideWithValue(tokenStore),
      ],
    );
    addTearDown(container.dispose);

    const fallbackUser = AuthUser(
      userId: 7,
      phone: '+8613800138000',
      countryCode: '86',
      email: 'fallback@example.com',
      nickname: 'Fallback User',
      avatarUrl: 'https://example.com/avatar.png',
      role: 'worker',
      gender: 'female',
      birthday: '1990-01-01',
      currentLocation: 'Shanghai',
      isVerified: true,
    );

    await AppLogScope.run<Future<void>>(
      traceId: 'test-auth-refresh-fail',
      fields: const <String, Object?>{'testCase': 'refresh_fail'},
      action: () {
        return container.read(authSessionProvider.notifier).refreshCurrentUser(
              fallbackUser: fallbackUser,
              preferredNeedSelectRole: false,
            );
      },
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries.where((
      Map<String, Object?> item,
    ) {
      final Map<String, Object?>? context =
          item['context'] as Map<String, Object?>?;
      return context?['traceId'] == 'test-auth-refresh-fail' &&
          (item['event'] == 'AUTH_REFRESH_START' ||
              item['event'] == 'AUTH_REFRESH_FAIL');
    }).toList();

    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'AUTH_REFRESH_START';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'AUTH_REFRESH_FAIL';
      }),
      isTrue,
    );

    expect(
      container.read(authSessionProvider),
      isA<AuthSessionState>()
          .having(
            (AuthSessionState state) => state.isAuthenticated,
            'isAuthenticated',
            isTrue,
          )
          .having(
            (AuthSessionState state) => state.isHydrating,
            'isHydrating',
            isFalse,
          )
          .having(
            (AuthSessionState state) => state.user?.userId,
            'user.userId',
            7,
          ),
    );
    final Map<String, Object?> refreshFailContext = readContext(
      matchedEntries.lastWhere(
        (Map<String, Object?> item) => item['event'] == 'AUTH_REFRESH_FAIL',
      ),
    );
    expect(refreshFailContext['from'], 'hydrating');
    expect(refreshFailContext['to'], 'authenticated_ready');
    expect(await readRawLogContent(), isNot(contains('fallback@example.com')));
    expect(await readRawLogContent(), isNot(contains('+8613800138000')));
  });
}

/// 提供可控的用户服务替身，避免测试依赖真实网络与复杂响应拼装。
class _FakeUserService extends UserService {
  _FakeUserService._({
    required this.profile,
    required this.error,
  }) : super(apiClient: ApiClient(Dio()));

  final UserVO? profile;
  final Object? error;

  /// 构造一个成功返回用户资料的服务替身。
  factory _FakeUserService.success() {
    return _FakeUserService._(
      profile: const UserVO(
        userId: 42,
        phone: '+8613900000000',
        email: 'worker@example.com',
        nickname: 'BlueHub Worker',
        avatarUrl: 'https://example.com/avatar.png',
        gender: 'male',
        birthday: '1990-01-01',
        role: 'worker',
        currentLocation: 'Shanghai',
        isVerified: true,
        blacklistCount: 0,
        createdAt: '2026-01-01T00:00:00Z',
      ),
      error: null,
    );
  }

  /// 构造一个固定抛错的服务替身，用于验证失败日志与状态回退。
  factory _FakeUserService.failure() {
    return _FakeUserService._(
      profile: null,
      error: StateError('refresh failed for test'),
    );
  }

  @override
  /// 按测试场景返回资料或抛出异常，模拟恢复/刷新链路的真实结果。
  Future<UserVO> getMe() async {
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return profile!;
  }
}
