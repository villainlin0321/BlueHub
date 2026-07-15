# Logging System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 BlueHub 建立可串联、可定位、可扩展的详细日志系统，并优先补齐启动、路由、鉴权、网络、核心业务控制器和页面交互日志。

**Architecture:** 在现有 `AppLogger` 之上增加结构化事件模型、作用域上下文和语义化日志门面，再通过路由观察器、Riverpod 观察器、页面生命周期助手和 HTTP 链路关联把自动采集补齐。最后将统一日志 API 接入启动、鉴权、岗位发布、消息、支付、黑名单、简历与订单等高频流程，确保单次用户操作可通过 `traceId` 全链路回放。

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Dio, logger, flutter_test

## Global Constraints

- 继续使用本地排障模式，日志输出仍为控制台 + 本地文件，不接远端日志平台。
- 发布版也保留尽量详细的日志，但必须继续执行脱敏、长度裁剪和必要频控。
- 优先覆盖启动、路由、鉴权、网络、核心 Controller、页面交互，再向其他模块扩展。
- 所有新增函数必须补函数级中文注释，关键代码必须补简洁中文注释。
- 不引入新第三方依赖，优先复用现有 `logger`、`dio`、`flutter_riverpod`、`go_router` 能力。
- 测试只补高价值用例，重点验证上下文串联、字段脱敏、关键链路事件是否可回放。

---

## File Structure

### 新增文件

- `lib/shared/logging/app_log_event.dart`
  - 定义结构化日志事件、日志层级、结果类型和序列化逻辑。
- `lib/shared/logging/app_log_scope.dart`
  - 管理 `sessionId`、`traceId`、`route`、`module`、`feature` 等作用域上下文。
- `lib/shared/logging/app_log_facade.dart`
  - 提供 `AppFlowLog`、`RouteLog`、`ActionLog`、`StateLog`、`HttpFlowLog` 等统一门面。
- `lib/shared/logging/app_route_tracker.dart`
  - 跟踪当前路由，给日志自动补充 `route`。
- `lib/shared/logging/app_provider_observer.dart`
  - 记录关键 Provider 的更新、异常和销毁。
- `lib/shared/logging/app_lifecycle_logger.dart`
  - 记录应用前后台切换、恢复与暂停。
- `test/shared/logging/app_log_scope_test.dart`
  - 验证作用域合并、上下文恢复、敏感字段脱敏。
- `test/shared/logging/app_route_tracker_test.dart`
  - 验证路由跟踪和页面生命周期日志。
- `test/shared/network/app_log_interceptor_test.dart`
  - 验证 HTTP 日志自动携带 `traceId`、`route`、业务动作。
- `test/features/auth/auth_session_logging_test.dart`
  - 验证鉴权恢复链路事件的前后顺序。
- `test/features/jobs/post_job_logging_test.dart`
  - 验证岗位发布关键交互和提交流程日志。
- `test/features/order/payment_flow_logging_test.dart`
  - 验证支付链路日志覆盖。

### 修改文件

- `lib/shared/logging/app_logger.dart`
  - 从“文本日志”扩展到“结构化事件 + 作用域上下文”。
- `lib/main.dart`
  - 初始化 `sessionId`、注册应用生命周期日志与全局错误日志。
- `lib/app/app.dart`
  - 挂接页面生命周期记录能力。
- `lib/app/router/app_router.dart`
  - 接入 `RouteLog` 和路由观察器，补齐页面进入、退出、重定向事件。
- `lib/shared/network/dio_factory.dart`
  - 为 Dio 接入新的 HTTP 日志门面。
- `lib/shared/network/api_client.dart`
  - 在请求入口与异常映射阶段补充业务动作和 `traceId` 串联。
- `lib/shared/network/interceptors/app_log_interceptor.dart`
  - 统一输出 `HTTP` 层结构化日志。
- `lib/shared/network/providers.dart`
  - 将 Provider 观察器或日志依赖接入全局容器。
- `lib/features/auth/application/auth_session_provider.dart`
  - 用新的语义化日志记录会话恢复、刷新、清理链路。
- `lib/features/jobs/application/post_job/post_job_controller.dart`
  - 记录岗位发布状态变化、校验、接口请求和错误路径。
- `lib/features/jobs/presentation/post_job_page.dart`
  - 记录页面进入、首帧、关键输入提交、发布点击。
- `lib/features/message/application/message_session/message_session_controller.dart`
  - 记录会话启动、刷新、SSE 事件处理、已读同步失败。
- `lib/features/order/application/payment/payment_flow_coordinator.dart`
  - 记录支付创建、拉起、轮询、结果确认链路。
- `lib/shared/payment/payment_launcher.dart`
  - 记录支付 SDK 初始化、拉起、回调结果。
- `lib/features/me/presentation/blacklist_page.dart`
  - 记录滚动触底、刷新、移除黑名单用户。
- `lib/features/me/presentation/my_resume_editor_page.dart`
  - 记录简历编辑页关键交互和提交动作。
- `lib/features/order/presentation/order_detail_page.dart`
  - 记录订单详情页关键操作入口。
- `lib/features/order/presentation/order_payment_bottom_sheet.dart`
  - 记录支付弹层打开、确认、取消与方式切换。

### 不在本轮修改

- `docs/api/**`
- `docs/prd/**`
- 原生日志平台或远端上报相关代码

### Task 1: 结构化日志底座

**Files:**
- Create: `lib/shared/logging/app_log_event.dart`
- Create: `lib/shared/logging/app_log_scope.dart`
- Test: `test/shared/logging/app_log_scope_test.dart`
- Modify: `lib/shared/logging/app_logger.dart`

**Interfaces:**
- Consumes: `AppLogger.instance`
- Produces: `AppLogEvent`, `AppLogLayer`, `AppLogResult`, `AppLogScope.run<T>()`, `AppLogger.logEvent(AppLogEvent event)`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';

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
            final scope = AppLogScope.current;
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
    final event = AppLogEvent(
      level: AppLogLevel.info,
      layer: AppLogLayer.http,
      event: 'AUTH_LOGIN_REQUEST',
      message: '登录请求开始',
      context: const <String, Object?>{
        'token': 'abc',
        'phone': '13800000000',
        'module': 'auth',
      },
    );

    final json = event.toJson();
    expect(json['layer'], 'HTTP');
    expect((json['context'] as Map<String, Object?>)['token'], '***');
    expect((json['context'] as Map<String, Object?>)['module'], 'auth');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/shared/logging/app_log_scope_test.dart`
Expected: FAIL，提示 `AppLogEvent`、`AppLogScope` 或 `toJson` 未定义

- [ ] **Step 3: 写最小实现**

```dart
// lib/shared/logging/app_log_event.dart
enum AppLogLayer { app, route, action, state, http }

enum AppLogResult { success, fail, skip, cancel, pending }

class AppLogEvent {
  const AppLogEvent({
    required this.level,
    required this.layer,
    required this.event,
    required this.message,
    this.result,
    this.context,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final AppLogLayer layer;
  final String event;
  final String message;
  final AppLogResult? result;
  final Map<String, Object?>? context;
  final Object? error;
  final StackTrace? stackTrace;

  /// 将结构化事件序列化为统一 JSON，便于控制台与文件端复用。
  Map<String, Object?> toJson() {
    final mergedContext = AppLogScope.merge(context);
    return <String, Object?>{
      'time': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'layer': layer.name.toUpperCase(),
      'event': event,
      'message': message,
      if (result != null) 'result': result!.name,
      if (mergedContext.isNotEmpty) 'context': mergedContext,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}

// lib/shared/logging/app_log_scope.dart
typedef AppLogFields = Map<String, Object?>;

class AppLogScope {
  static final List<AppLogFields> _stack = <AppLogFields>[];

  /// 返回当前作用域展平后的字段集合。
  static AppLogFields get current => merge(const <String, Object?>{});

  /// 在指定上下文中执行动作，让同一链路自动继承 sessionId、traceId 等字段。
  static T run<T>({
    String? sessionId,
    String? traceId,
    AppLogFields fields = const <String, Object?>{},
    required T Function() action,
  }) {
    final next = <String, Object?>{
      if (sessionId != null) 'sessionId': sessionId,
      if (traceId != null) 'traceId': traceId,
      ...fields,
    };
    _stack.add(next);
    try {
      return action();
    } finally {
      _stack.removeLast();
    }
  }

  /// 合并所有上层作用域和本次日志上下文，后者优先级更高。
  static AppLogFields merge(AppLogFields fields) {
    final merged = <String, Object?>{};
    for (final scope in _stack) {
      merged.addAll(scope);
    }
    merged.addAll(fields);
    return merged;
  }
}

// lib/shared/logging/app_logger.dart
void logEvent(AppLogEvent event) {
  final payload = event.toJson();
  _log(
    event.level,
    payload['layer']?.toString() ?? 'APP',
    event.message,
    context: payload,
    error: event.error,
    stackTrace: event.stackTrace,
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/shared/logging/app_log_scope_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/shared/logging/app_log_event.dart lib/shared/logging/app_log_scope.dart lib/shared/logging/app_logger.dart test/shared/logging/app_log_scope_test.dart
git commit -m "feat(logging): add structured log event and scope"
```

### Task 2: 日志门面与自动观察器

**Files:**
- Create: `lib/shared/logging/app_log_facade.dart`
- Create: `lib/shared/logging/app_route_tracker.dart`
- Create: `lib/shared/logging/app_provider_observer.dart`
- Create: `lib/shared/logging/app_lifecycle_logger.dart`
- Test: `test/shared/logging/app_route_tracker_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/router/app_router.dart`

**Interfaces:**
- Consumes: `AppLogger.logEvent(AppLogEvent event)`, `AppLogScope.run<T>()`
- Produces: `AppFlowLog`, `RouteLog`, `ActionLog`, `StateLog`, `HttpFlowLog`, `AppRouteTracker.instance.currentRoute`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/shared/logging/app_route_tracker.dart';

void main() {
  test('AppRouteTracker 会记录当前路由并支持前后页面切换', () {
    final tracker = AppRouteTracker();

    tracker.didPush('/login');
    expect(tracker.currentRoute, '/login');

    tracker.didPush('/jobs/post');
    expect(tracker.previousRoute, '/login');
    expect(tracker.currentRoute, '/jobs/post');

    tracker.didPop('/login');
    expect(tracker.currentRoute, '/login');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/shared/logging/app_route_tracker_test.dart`
Expected: FAIL，提示 `AppRouteTracker` 或路由方法不存在

- [ ] **Step 3: 写最小实现**

```dart
// lib/shared/logging/app_route_tracker.dart
class AppRouteTracker {
  String? previousRoute;
  String? currentRoute;

  /// 记录页面压栈后的前后路由，用于补齐 route/from/to 字段。
  void didPush(String route) {
    previousRoute = currentRoute;
    currentRoute = route;
  }

  /// 记录页面出栈后的当前路由，保证日志上下文与界面一致。
  void didPop(String? fallbackRoute) {
    currentRoute = fallbackRoute;
  }
}

// lib/shared/logging/app_log_facade.dart
class RouteLog {
  const RouteLog(this._logger);

  final AppLogger _logger;

  /// 记录页面进入事件，并自动补齐 from/to/route 字段。
  void pageEnter({required String route, String? from}) {
    _logger.logEvent(
      AppLogEvent(
        level: AppLogLevel.info,
        layer: AppLogLayer.route,
        event: 'PAGE_ENTER',
        message: '页面进入',
        context: <String, Object?>{'route': route, if (from != null) 'from': from},
      ),
    );
  }
}

// lib/shared/logging/app_provider_observer.dart
class AppProviderObserver extends ProviderObserver {
  AppProviderObserver(this._logger);

  final AppLogger _logger;

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    _logger.logEvent(
      AppLogEvent(
        level: AppLogLevel.debug,
        layer: AppLogLayer.state,
        event: 'PROVIDER_UPDATED',
        message: 'Provider 状态发生变化',
        context: <String, Object?>{
          'provider': context.provider.name ?? context.provider.runtimeType.toString(),
          'previous': previousValue?.toString(),
          'next': newValue?.toString(),
        },
      ),
    );
  }
}

// lib/shared/logging/app_lifecycle_logger.dart
class AppLifecycleLogger with WidgetsBindingObserver {
  AppLifecycleLogger(this._logger);

  final AppLogger _logger;

  /// 记录应用进入前后台，便于区分问题发生时的生命周期场景。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.logEvent(
      AppLogEvent(
        level: AppLogLevel.info,
        layer: AppLogLayer.app,
        event: 'APP_LIFECYCLE_CHANGED',
        message: '应用生命周期变化',
        context: <String, Object?>{'state': state.name},
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过，并手工验证路由 wiring**

Run: `flutter test test/shared/logging/app_route_tracker_test.dart`
Expected: PASS

Run: `flutter analyze lib/main.dart lib/app/app.dart lib/app/router/app_router.dart lib/shared/logging`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/shared/logging/app_log_facade.dart lib/shared/logging/app_route_tracker.dart lib/shared/logging/app_provider_observer.dart lib/shared/logging/app_lifecycle_logger.dart lib/main.dart lib/app/app.dart lib/app/router/app_router.dart test/shared/logging/app_route_tracker_test.dart
git commit -m "feat(logging): add route and provider log observers"
```

### Task 3: HTTP 链路关联与业务动作透传

**Files:**
- Modify: `lib/shared/network/interceptors/app_log_interceptor.dart`
- Modify: `lib/shared/network/api_client.dart`
- Modify: `lib/shared/network/dio_factory.dart`
- Modify: `lib/shared/network/providers.dart`
- Test: `test/shared/network/app_log_interceptor_test.dart`

**Interfaces:**
- Consumes: `HttpFlowLog.requestStart()`, `HttpFlowLog.requestSuccess()`, `HttpFlowLog.requestFail()`, `AppRouteTracker.currentRoute`
- Produces: `RequestOptions.extra['traceId']`, `RequestOptions.extra['logAction']`, `RequestOptions.extra['route']`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/network/interceptors/app_log_interceptor.dart';

void main() {
  test('AppLogInterceptor 会把 traceId、route 和业务动作写入请求上下文', () {
    final options = RequestOptions(path: '/jobs');

    AppLogScope.run(
      traceId: 'trace-post-job',
      fields: const <String, Object?>{'route': '/jobs/post', 'action': 'POST_JOB_SUBMIT_TAP'},
      action: () {
        final interceptor = AppLogInterceptor(enabled: true);
        interceptor.onRequest(options, RequestInterceptorHandler());
      },
    );

    expect(options.extra['traceId'], 'trace-post-job');
    expect(options.extra['route'], '/jobs/post');
    expect(options.extra['logAction'], 'POST_JOB_SUBMIT_TAP');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/shared/network/app_log_interceptor_test.dart`
Expected: FAIL，提示 `traceId`、`route`、`logAction` 未写入 `extra`

- [ ] **Step 3: 写最小实现**

```dart
// lib/shared/network/interceptors/app_log_interceptor.dart
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  if (!enabled) return handler.next(options);

  final scope = AppLogScope.current;
  final traceId = scope['traceId']?.toString();
  final route = scope['route']?.toString();
  final action = scope['action']?.toString();

  if (traceId != null && traceId.isNotEmpty) {
    options.extra['traceId'] = traceId;
  }
  if (route != null && route.isNotEmpty) {
    options.extra['route'] = route;
  }
  if (action != null && action.isNotEmpty) {
    options.extra['logAction'] = action;
  }

  HttpFlowLog(AppLogger.instance).requestStart(
    requestId: _buildRequestId(options),
    method: options.method,
    uri: options.uri.toString(),
    context: <String, Object?>{
      'traceId': traceId,
      'route': route,
      'action': action,
    },
  );
  handler.next(options);
}

// lib/shared/network/api_client.dart
Future<T> post<T>(String path, {Object? data, ...}) {
  return AppLogScope.run(
    fields: <String, Object?>{'httpPath': path},
    action: () => _request<T>(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      decode: decode,
      options: options,
    ),
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/shared/network/app_log_interceptor_test.dart`
Expected: PASS

Run: `flutter analyze lib/shared/network/interceptors/app_log_interceptor.dart lib/shared/network/api_client.dart lib/shared/network/dio_factory.dart`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/shared/network/interceptors/app_log_interceptor.dart lib/shared/network/api_client.dart lib/shared/network/dio_factory.dart lib/shared/network/providers.dart test/shared/network/app_log_interceptor_test.dart
git commit -m "feat(logging): correlate http logs with route trace"
```

### Task 4: 启动、路由与鉴权链路日志

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/auth/application/auth_session_provider.dart`
- Test: `test/features/auth/auth_session_logging_test.dart`

**Interfaces:**
- Consumes: `AppFlowLog.bootstrapStart()`, `AppFlowLog.bootstrapSuccess()`, `RouteLog.redirectApplied()`, `StateLog.transition()`
- Produces: `AUTH_RESTORE_START/SUCCESS/FAIL`, `AUTH_REFRESH_START/SUCCESS/FAIL`, `ROUTE_REDIRECT_APPLIED`, `APP_BOOTSTRAP_START/SUCCESS`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';

void main() {
  test('restoreSession 会输出开始和成功事件', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        userServiceProvider.overrideWithValue(FakeUserService.success()),
        tokenStoreProvider.overrideWithValue(FakeTokenStore.withAccessToken('token-1')),
        fakeLogRecorderProvider.overrideWithValue(FakeLogRecorder()),
      ],
    );

    await container.read(authSessionProvider.notifier).restoreSession();

    final events = container.read(fakeLogRecorderProvider);
    expect(events.any((e) => e.event == 'AUTH_RESTORE_START'), isTrue);
    expect(events.any((e) => e.event == 'AUTH_RESTORE_SUCCESS'), isTrue);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/auth/auth_session_logging_test.dart`
Expected: FAIL，提示缺少日志记录器注入或事件未输出

- [ ] **Step 3: 写最小实现**

```dart
// lib/main.dart
Future<void> main() async {
  final sessionId = 'session_${DateTime.now().microsecondsSinceEpoch}';

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      await AppLogger.instance.init();
      await PaymentLauncher.instance.initialize(
        config: PaymentChannelConfig.fromEnvironment(),
      );
      _registerGlobalErrorHandlers();

      AppLogScope.run(
        sessionId: sessionId,
        fields: const <String, Object?>{'module': 'app', 'feature': 'bootstrap'},
        action: () {
          AppFlowLog(AppLogger.instance).bootstrapStart();
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final tokenStore = TokenStore.sharedPreferences(prefs);
      await _runNativeHttpProbe();

      runApp(
        ProviderScope(
          observers: <ProviderObserver>[AppProviderObserver(AppLogger.instance)],
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStoreProvider.overrideWithValue(tokenStore),
          ],
          child: const App(),
        ),
      );

      AppFlowLog(AppLogger.instance).bootstrapSuccess(
        context: <String, Object?>{
          'hasPersistedToken': (tokenStore.accessToken ?? '').isNotEmpty,
          'logFilePath': AppLogger.instance.currentLogFilePath,
        },
      );
    },
    (Object error, StackTrace stackTrace) {
      AppFlowLog(AppLogger.instance).bootstrapFail(error, stackTrace);
    },
  );
}

// lib/features/auth/application/auth_session_provider.dart
Future<void> restoreSession() async {
  final traceId = 'auth_restore_${DateTime.now().microsecondsSinceEpoch}';
  await AppLogScope.run(
    traceId: traceId,
    fields: const <String, Object?>{
      'module': 'auth',
      'feature': 'session',
      'method': 'restoreSession',
    },
    action: () async {
      StateLog(AppLogger.instance).step(
        event: 'AUTH_RESTORE_START',
        message: '开始恢复会话',
      );
      try {
        final profile = await ref.read(userServiceProvider).getMe();
        // 原状态更新逻辑
        StateLog(AppLogger.instance).step(
          event: 'AUTH_RESTORE_SUCCESS',
          message: '恢复会话成功',
          result: AppLogResult.success,
          context: <String, Object?>{'userId': user.userId, 'role': user.role},
        );
      } catch (error, stackTrace) {
        StateLog(AppLogger.instance).error(
          event: 'AUTH_RESTORE_FAIL',
          message: '恢复会话失败',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    },
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/auth/auth_session_logging_test.dart`
Expected: PASS

Run: `flutter analyze lib/main.dart lib/app/router/app_router.dart lib/features/auth/application/auth_session_provider.dart`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/main.dart lib/app/router/app_router.dart lib/features/auth/application/auth_session_provider.dart test/features/auth/auth_session_logging_test.dart
git commit -m "feat(logging): cover bootstrap route and auth flows"
```

### Task 5: 岗位发布页面与控制器详细日志

**Files:**
- Modify: `lib/features/jobs/application/post_job/post_job_controller.dart`
- Modify: `lib/features/jobs/presentation/post_job_page.dart`
- Test: `test/features/jobs/post_job_logging_test.dart`

**Interfaces:**
- Consumes: `ActionLog.tap()`, `ActionLog.inputCommit()`, `StateLog.step()`, `AppLogScope.run<T>()`
- Produces: `POST_JOB_PAGE_ENTER`, `POST_JOB_FIRST_FRAME`, `POST_JOB_SUBMIT_TAP`, `POST_JOB_VALIDATE_FAIL`, `POST_JOB_SUBMIT_REQUEST_START`, `POST_JOB_SUBMIT_REQUEST_FAIL`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/features/jobs/application/post_job/post_job_controller.dart';

void main() {
  test('publish 会按顺序输出点击、校验、请求和反馈日志', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        jobServiceProvider.overrideWithValue(FakeJobService.publishSuccess()),
        fakeLogRecorderProvider.overrideWithValue(FakeLogRecorder()),
      ],
    );

    final controller = container.read(postJobControllerProvider.notifier);
    await controller.publish(
      const PostJobFormDraft(
        title: '焊工',
        countryOrCity: '德国',
        headcount: '5',
        minSalary: '1000',
        maxSalary: '2000',
        description: '测试描述',
      ),
    );

    final events = container.read(fakeLogRecorderProvider).map((e) => e.event);
    expect(events, contains('POST_JOB_SUBMIT_TAP'));
    expect(events, contains('POST_JOB_SUBMIT_REQUEST_START'));
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/jobs/post_job_logging_test.dart`
Expected: FAIL，提示关键事件未记录

- [ ] **Step 3: 写最小实现**

```dart
// lib/features/jobs/presentation/post_job_page.dart
@override
void initState() {
  super.initState();
  ActionLog(AppLogger.instance).pageEnter(
    event: 'POST_JOB_PAGE_ENTER',
    route: RoutePaths.postJob,
    context: <String, Object?>{'mode': widget.args.mode.name},
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ActionLog(AppLogger.instance).pageFirstFrame(
      event: 'POST_JOB_FIRST_FRAME',
      route: RoutePaths.postJob,
    );
    _bootstrapPage();
  });
}

Future<void> _handlePublish() async {
  FocusScope.of(context).unfocus();
  _submitCustomTag();
  await AppLogScope.run(
    traceId: 'post_job_submit_${DateTime.now().microsecondsSinceEpoch}',
    fields: <String, Object?>{
      'route': RoutePaths.postJob,
      'module': 'jobs',
      'feature': 'post_job',
      'action': 'POST_JOB_SUBMIT_TAP',
    },
    action: () async {
      ActionLog(AppLogger.instance).tap(
        event: 'POST_JOB_SUBMIT_TAP',
        message: '用户点击发布岗位',
      );
      await ref.read(postJobControllerProvider.notifier).publish(
        _buildFormDraft(),
        editingJobId: widget.args.jobId,
      );
    },
  );
}

// lib/features/jobs/application/post_job/post_job_controller.dart
Future<void> publish(PostJobFormDraft draft, {int? editingJobId}) async {
  StateLog(AppLogger.instance).step(
    event: 'POST_JOB_VALIDATE_START',
    message: '开始校验岗位表单',
    step: 'validate',
  );
  final validationError = _validateDraft(draft);
  if (validationError != null) {
    StateLog(AppLogger.instance).step(
      event: 'POST_JOB_VALIDATE_FAIL',
      message: '岗位表单校验失败',
      step: 'validate',
      result: AppLogResult.fail,
      context: <String, Object?>{'reason': validationError},
    );
    _emitFeedback(validationError, isError: true);
    return;
  }
  StateLog(AppLogger.instance).step(
    event: 'POST_JOB_SUBMIT_REQUEST_START',
    message: '开始请求岗位发布接口',
    step: 'request',
    context: <String, Object?>{'editingJobId': editingJobId},
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/jobs/post_job_logging_test.dart`
Expected: PASS

Run: `flutter analyze lib/features/jobs/application/post_job/post_job_controller.dart lib/features/jobs/presentation/post_job_page.dart`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/features/jobs/application/post_job/post_job_controller.dart lib/features/jobs/presentation/post_job_page.dart test/features/jobs/post_job_logging_test.dart
git commit -m "feat(logging): add detailed logs for post job flow"
```

### Task 6: 消息与支付链路日志

**Files:**
- Modify: `lib/features/message/application/message_session/message_session_controller.dart`
- Modify: `lib/features/order/application/payment/payment_flow_coordinator.dart`
- Modify: `lib/shared/payment/payment_launcher.dart`
- Test: `test/features/order/payment_flow_logging_test.dart`

**Interfaces:**
- Consumes: `StateLog.step()`, `ActionLog.tap()`, `HttpFlowLog.requestStart()`
- Produces: `MESSAGE_SESSION_START`, `MESSAGE_REFRESH_FAIL`, `PAYMENT_CREATE_START`, `PAYMENT_LAUNCH_SUCCESS`, `PAYMENT_STATUS_POLL_PENDING`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/features/order/application/payment/payment_flow_coordinator.dart';

void main() {
  test('startPayment 会记录创建、拉起和轮询结果日志', () async {
    final coordinator = PaymentFlowCoordinator(
      paymentService: FakePaymentService.success(),
      paymentLauncher: FakePaymentLauncher.success(),
    );

    final result = await coordinator.startPayment(
      orderId: 1001,
      method: AppPaymentMethod.alipay,
    );

    expect(result.status, PaymentFlowStatus.success);
    expect(fakeLogRecorder.events.any((e) => e.event == 'PAYMENT_CREATE_START'), isTrue);
    expect(fakeLogRecorder.events.any((e) => e.event == 'PAYMENT_LAUNCH_SUCCESS'), isTrue);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/order/payment_flow_logging_test.dart`
Expected: FAIL，提示支付事件未输出

- [ ] **Step 3: 写最小实现**

```dart
// lib/features/order/application/payment/payment_flow_coordinator.dart
Future<PaymentFlowResult> startPayment({
  required int orderId,
  required AppPaymentMethod method,
}) async {
  return AppLogScope.run(
    traceId: 'payment_$orderId_${DateTime.now().microsecondsSinceEpoch}',
    fields: <String, Object?>{
      'module': 'order',
      'feature': 'payment',
      'method': 'startPayment',
      'orderId': orderId,
      'paymentMethod': method.apiValue,
    },
    action: () async {
      StateLog(AppLogger.instance).step(
        event: 'PAYMENT_CREATE_START',
        message: '开始创建支付单',
      );
      final payment = await _paymentService.createPayment(
        request: CreatePaymentBO(orderId: orderId, paymentMethod: method.apiValue),
      );
      StateLog(AppLogger.instance).step(
        event: 'PAYMENT_CREATE_SUCCESS',
        message: '支付单创建成功',
        context: <String, Object?>{'paymentId': payment.paymentId},
      );
      final launchResult = switch (method) {
        AppPaymentMethod.alipay => await _paymentLauncher.payWithAlipay(payment),
        AppPaymentMethod.wechat => await _paymentLauncher.payWithWeChat(payment),
      };
      switch (launchResult.status) {
        case AppPaymentLaunchStatus.success:
          StateLog(AppLogger.instance).step(
            event: 'PAYMENT_LAUNCH_SUCCESS',
            message: '支付 SDK 返回成功',
            result: AppLogResult.success,
          );
          return _queryFinalStatus(orderId: orderId);
        case AppPaymentLaunchStatus.cancel:
          StateLog(AppLogger.instance).step(
            event: 'PAYMENT_LAUNCH_CANCEL',
            message: '用户取消支付',
            result: AppLogResult.cancel,
          );
          return PaymentFlowResult(
            status: PaymentFlowStatus.cancel,
            message: launchResult.message,
          );
        case AppPaymentLaunchStatus.pending:
          StateLog(AppLogger.instance).step(
            event: 'PAYMENT_LAUNCH_PENDING',
            message: '支付结果待确认',
            result: AppLogResult.pending,
          );
          return PaymentFlowResult(
            status: PaymentFlowStatus.pending,
            message: launchResult.message,
          );
        case AppPaymentLaunchStatus.failed:
        case AppPaymentLaunchStatus.unknown:
          StateLog(AppLogger.instance).step(
            event: 'PAYMENT_LAUNCH_FAIL',
            message: '支付 SDK 返回失败',
            result: AppLogResult.fail,
            context: <String, Object?>{'raw': launchResult.raw?.toString()},
          );
          return PaymentFlowResult(
            status: PaymentFlowStatus.failed,
            message: launchResult.message,
          );
      }
    },
  );
}

// lib/features/message/application/message_session/message_session_controller.dart
Future<void> refreshConversations() async {
  StateLog(AppLogger.instance).step(
    event: 'MESSAGE_REFRESH_START',
    message: '开始刷新会话列表',
    context: <String, Object?>{'pageSize': _pageSize},
  );
  try {
    // 原请求逻辑
    StateLog(AppLogger.instance).step(
      event: 'MESSAGE_REFRESH_SUCCESS',
      message: '刷新会话列表成功',
      result: AppLogResult.success,
      context: <String, Object?>{'conversationCount': response.list.length},
    );
  } catch (error, stackTrace) {
    StateLog(AppLogger.instance).error(
      event: 'MESSAGE_REFRESH_FAIL',
      message: '刷新会话列表失败',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/order/payment_flow_logging_test.dart`
Expected: PASS

Run: `flutter analyze lib/features/message/application/message_session/message_session_controller.dart lib/features/order/application/payment/payment_flow_coordinator.dart lib/shared/payment/payment_launcher.dart`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/features/message/application/message_session/message_session_controller.dart lib/features/order/application/payment/payment_flow_coordinator.dart lib/shared/payment/payment_launcher.dart test/features/order/payment_flow_logging_test.dart
git commit -m "feat(logging): cover message and payment flows"
```

### Task 7: 黑名单、简历和订单高频交互日志

**Files:**
- Modify: `lib/features/me/presentation/blacklist_page.dart`
- Modify: `lib/features/me/presentation/my_resume_editor_page.dart`
- Modify: `lib/features/order/presentation/order_detail_page.dart`
- Modify: `lib/features/order/presentation/order_payment_bottom_sheet.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `ActionLog.tap()`, `ActionLog.sheetOpen()`, `ActionLog.scrollReachEnd()`, `StateLog.step()`
- Produces: `BLACKLIST_PAGE_ENTER`, `BLACKLIST_SCROLL_REACH_END`, `RESUME_SAVE_TAP`, `ORDER_PAYMENT_SHEET_OPEN`, `ORDER_PAYMENT_CONFIRM_TAP`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('支付弹层打开和确认支付会输出关键交互日志', (tester) async {
    final recorder = FakeLogRecorder();
    await tester.pumpWidget(
      TestOrderPaymentHost(
        logRecorder: recorder,
        orderId: 9001,
      ),
    );
    await tester.tap(find.text('立即支付'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认支付'));
    await tester.pumpAndSettle();
    expect(recorder.events.any((e) => e.event == 'ORDER_PAYMENT_SHEET_OPEN'), isTrue);
    expect(recorder.events.any((e) => e.event == 'ORDER_PAYMENT_CONFIRM_TAP'), isTrue);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/widget_test.dart`
Expected: FAIL，提示订单支付交互事件缺失

- [ ] **Step 3: 写最小实现**

```dart
// lib/features/me/presentation/blacklist_page.dart
@override
void initState() {
  super.initState();
  ActionLog(AppLogger.instance).pageEnter(
    event: 'BLACKLIST_PAGE_ENTER',
    route: 'blacklist',
  );
  _scrollController.addListener(_handleScroll);
}

void _handleScroll() {
  if (_scrollController.position.pixels <
      _scrollController.position.maxScrollExtent - 120) {
    return;
  }
  ActionLog(AppLogger.instance).scrollReachEnd(
    event: 'BLACKLIST_SCROLL_REACH_END',
    message: '黑名单列表滚动到底部，准备加载更多',
  );
  ref.read(blacklistControllerProvider.notifier).loadMore();
}

// lib/features/order/presentation/order_payment_bottom_sheet.dart
void _handleConfirmPay(AppPaymentMethod method) {
  ActionLog(AppLogger.instance).tap(
    event: 'ORDER_PAYMENT_CONFIRM_TAP',
    message: '用户确认支付',
    context: <String, Object?>{'paymentMethod': method.name},
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/widget_test.dart`
Expected: PASS

Run: `flutter analyze lib/features/me/presentation/blacklist_page.dart lib/features/me/presentation/my_resume_editor_page.dart lib/features/order/presentation/order_detail_page.dart lib/features/order/presentation/order_payment_bottom_sheet.dart`
Expected: No issues found

- [ ] **Step 5: 提交**

```bash
git add lib/features/me/presentation/blacklist_page.dart lib/features/me/presentation/my_resume_editor_page.dart lib/features/order/presentation/order_detail_page.dart lib/features/order/presentation/order_payment_bottom_sheet.dart test/widget_test.dart
git commit -m "feat(logging): add logs for high-frequency page interactions"
```

## Self-Review

- **Spec coverage:** 结构化字段、作用域上下文、5 层模型、自动采集、HTTP 串联、启动/路由/鉴权、岗位发布、消息、支付、黑名单与页面交互都已映射到任务；远端日志平台明确未纳入本轮。
- **Placeholder scan:** 计划中没有残留占位描述；每个任务都给出了明确文件、命令、测试和提交点。
- **Type consistency:** 统一使用 `AppLogEvent`、`AppLogScope.run<T>()`、`ActionLog`、`StateLog`、`RouteLog`、`HttpFlowLog` 作为核心接口，全部任务沿用同一命名。

Plan complete and saved to `docs/superpowers/plans/2026-07-04-logging-system-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
