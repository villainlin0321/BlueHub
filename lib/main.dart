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
import 'features/files/data/file_providers.dart';
import 'features/me/data/user_providers.dart';
import 'patrol_test/helpers/job_seeker_real_name_patrol_support.dart';

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
          try {
            // 关键点：Binding 初始化与 runApp 必须处于同一个 Zone，避免 Zone mismatch。
            WidgetsFlutterBinding.ensureInitialized();
            await EasyLocalization.ensureInitialized();
            await AppLogger.instance.init();
            final bootstrapErrorTracker = _BootstrapErrorTracker();
            AppFlowLog.bootstrapStart(
              context: <String, Object?>{
                'sessionId': sessionId,
                'phase': 'binding_initialized',
                'logFilePath': AppLogger.instance.currentLogFilePath,
              },
            );
            await PaymentLauncher.instance.initialize(
              config: PaymentChannelConfig.fromEnvironment(),
            );
            _registerGlobalErrorHandlers(
              bootstrapErrorTracker: bootstrapErrorTracker,
            );

            final prefs = await SharedPreferences.getInstance();
            final tokenStore = TokenStore.sharedPreferences(prefs);
            final patrolRealNameSupport = JobSeekerRealNamePatrolSupport.enabled
                ? JobSeekerRealNamePatrolSupport()
                : null;
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
                    if (patrolRealNameSupport != null)
                      jobSeekerRealNamePatrolSupportProvider.overrideWithValue(
                        patrolRealNameSupport,
                      ),
                    if (JobSeekerRealNamePatrolSupport.fakeFlowEnabled)
                      userServiceProvider.overrideWith(
                        (ref) => PatrolRealNameUserService(
                          apiClient: ref.watch(apiClientProvider),
                        ),
                      ),
                    if (JobSeekerRealNamePatrolSupport.fakeFlowEnabled)
                      fileServiceProvider.overrideWith(
                        (ref) => PatrolRealNameFileService(
                          apiClient: ref.watch(apiClientProvider),
                          support: patrolRealNameSupport!,
                        ),
                      ),
                  ],
                  child: const App(),
                ),
              ),
            );
            // 关键日志：只有首帧完成且启动阶段未记录全局异常时，才算真正启动成功。
            await _waitForFirstFrame();
            bootstrapErrorTracker.throwIfRecorded();
            AppFlowLog.bootstrapSuccess(
              context: <String, Object?>{
                'sessionId': sessionId,
                'phase': 'first_frame_rendered',
                'hasPersistedSession':
                    (tokenStore.accessToken ?? '').isNotEmpty,
                'hasPersistedRefreshCredential':
                    (tokenStore.refreshToken ?? '').isNotEmpty,
                'logFilePath': AppLogger.instance.currentLogFilePath,
              },
            );
          } catch (error, stackTrace) {
            AppFlowLog.bootstrapFail(
              error: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'sessionId': sessionId,
                'logFilePath': AppLogger.instance.currentLogFilePath,
              },
            );
            rethrow;
          }
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
void _registerGlobalErrorHandlers({
  _BootstrapErrorTracker? bootstrapErrorTracker,
}) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    bootstrapErrorTracker?.record(
      details.exception,
      details.stack ?? StackTrace.current,
    );
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
    bootstrapErrorTracker?.record(error, stackTrace);
    AppLogger.instance.fatal(
      'PLATFORM',
      'PlatformDispatcher 捕获到未处理异常',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

/// 等待应用首帧完成，确保启动成功日志不会早于真正可见的界面渲染。
Future<void> _waitForFirstFrame() {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  return completer.future;
}

/// 记录启动阶段捕获到的首个全局异常，并在首帧后决定是否阻断成功日志。
class _BootstrapErrorTracker {
  Object? _error;
  StackTrace? _stackTrace;

  /// 仅保留首个异常，避免同一次失败场景被后续连锁错误覆盖根因。
  void record(Object error, StackTrace stackTrace) {
    if (_error != null) {
      return;
    }
    _error = error;
    _stackTrace = stackTrace;
  }

  /// 在启动阶段发现全局异常时抛出，统一走 `main()` 的失败日志分支。
  void throwIfRecorded() {
    final recordedError = _error;
    if (recordedError == null) {
      return;
    }
    Error.throwWithStackTrace(recordedError, _stackTrace ?? StackTrace.current);
  }
}

/// 生成应用启动会话 ID，让同一次运行中的日志天然具备统一会话上下文。
String _buildAppSessionId() {
  return 'app_${DateTime.now().microsecondsSinceEpoch}';
}
