import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/localization/app_locales.dart';
import 'shared/auth/token_store.dart';
import 'shared/logging/app_log_facade.dart';
import 'shared/logging/app_logger.dart';
import 'shared/logging/app_log_scope.dart';
import 'shared/logging/app_provider_observer.dart';
import 'shared/network/providers.dart';
import 'shared/payment/payment_channel_config.dart';
import 'shared/payment/payment_launcher.dart';

const MethodChannel _nativeDebugChannel = MethodChannel('bluehub/app_icon');
const String _nativeProbeUrl = 'http://39.101.190.245:8090';

/// 应用入口：初始化依赖、挂接全局异常处理，并启动 Riverpod 根节点。
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      final sessionId = _buildAppSessionId();
      await AppLogScope.run<Future<void>>(
        sessionId: sessionId,
        fields: const <String, Object?>{'module': 'app'},
        action: () async {
          // 关键点：Binding 初始化与 runApp 必须处于同一个 Zone，避免 Zone mismatch。
          WidgetsFlutterBinding.ensureInitialized();
          await EasyLocalization.ensureInitialized();
          await AppLogger.instance.init();
          await PaymentLauncher.instance.initialize(
            config: PaymentChannelConfig.fromEnvironment(),
          );
          _registerGlobalErrorHandlers();

          final prefs = await SharedPreferences.getInstance();
          final tokenStore = TokenStore.sharedPreferences(prefs);
          AppFlowLog.log(
            event: 'APP_BOOTSTRAP',
            message: '应用启动',
            context: <String, Object?>{
              'sessionId': sessionId,
              'hasPersistedToken': (tokenStore.accessToken ?? '').isNotEmpty,
              'logFilePath': AppLogger.instance.currentLogFilePath,
            },
          );
          await _runNativeHttpProbe();

          runApp(
            EasyLocalization(
              supportedLocales: AppLocales.supported,
              path: 'assets/translations',
              fallbackLocale: AppLocales.english,
              saveLocale: true,
              useOnlyLangCode: true,
              child: ProviderScope(
                observers: const <ProviderObserver>[AppProviderObserver()],
                overrides: [
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  tokenStoreProvider.overrideWithValue(tokenStore),
                ],
                child: const App(),
              ),
            ),
          );
        },
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

/// 调用 iOS 原生 URLSession 探针，并把结果打进统一日志，便于与 Dio 请求结果直接对比。
Future<void> _runNativeHttpProbe() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  try {
    // #region debug-point B:native-probe-via-channel
    final Map<Object?, Object?>? result =
        await _nativeDebugChannel.invokeMapMethod<Object?, Object?>(
          'probeHttp',
          <String, Object?>{'url': _nativeProbeUrl},
        );
    AppLogger.instance.info(
      'NATIVE_HTTP',
      'iOS 原生 URLSession 探针完成',
      context: <String, Object?>{
        'target': _nativeProbeUrl,
        'result': result?.map(
              (Object? key, Object? value) =>
                  MapEntry(key.toString(), value),
            ) ??
            <String, Object?>{},
      },
    );
    // #endregion
  } on PlatformException catch (error, stackTrace) {
    // #region debug-point B:native-probe-channel-error
    AppLogger.instance.error(
      'NATIVE_HTTP',
      'iOS 原生 URLSession 探针调用失败',
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{'target': _nativeProbeUrl},
    );
    // #endregion
  }
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

/// 生成应用启动会话 ID，让同一次运行中的日志天然具备统一会话上下文。
String _buildAppSessionId() {
  return 'app_${DateTime.now().microsecondsSinceEpoch}';
}
