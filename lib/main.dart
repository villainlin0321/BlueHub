import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/auth/token_store.dart';
import 'shared/logging/app_logger.dart';
import 'shared/network/providers.dart';

/// 应用入口：初始化依赖、挂接全局异常处理，并启动 Riverpod 根节点。
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      // 关键点：Binding 初始化与 runApp 必须处于同一个 Zone，避免 Zone mismatch。
      WidgetsFlutterBinding.ensureInitialized();
      await AppLogger.instance.init();
      _registerGlobalErrorHandlers();

      final prefs = await SharedPreferences.getInstance();
      final tokenStore = TokenStore.sharedPreferences(prefs);
      AppLogger.instance.info(
        'APP',
        '应用启动',
        context: <String, Object?>{
          'hasPersistedToken': (tokenStore.accessToken ?? '').isNotEmpty,
          'logFilePath': AppLogger.instance.currentLogFilePath,
        },
      );

      runApp(
        ProviderScope(
          overrides: [tokenStoreProvider.overrideWithValue(tokenStore)],
          child: const App(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.instance.fatal(
        'APP',
        'runZonedGuarded 捕获到未处理异常',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

/// 注册 Flutter、平台层和异步 Zone 的全局异常日志。
void _registerGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.error(
      'FLUTTER',
      'FlutterError.onError 捕获到异常',
      error: details.exception,
      stackTrace: details.stack,
      context: <String, Object?>{
        'library': details.library ?? 'unknown',
        'context': details.context?.toDescription(),
      },
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppLogger.instance.fatal(
      'PLATFORM',
      'PlatformDispatcher 捕获到未处理异常',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}
