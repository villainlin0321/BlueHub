# Task 2 Report

## 任务范围

- 严格按 `/.superpowers/sdd/task-2-brief.md` 执行。
- 仅实现统一日志门面、路由追踪、Provider 观察器、生命周期日志接入与必需测试。
- 未扩展到 Task 1/Task 3 及其他非 brief 指定内容。

## 变更概览

### 新增文件

- `lib/shared/logging/app_log_facade.dart`
- `lib/shared/logging/app_route_tracker.dart`
- `lib/shared/logging/app_provider_observer.dart`
- `lib/shared/logging/app_lifecycle_logger.dart`
- `test/shared/logging/app_route_tracker_test.dart`

### 修改文件

- `lib/main.dart`
- `lib/app/app.dart`
- `lib/app/router/app_router.dart`

## 实现说明

### 1. 统一日志门面

- 新增 `AppFlowLog`、`RouteLog`、`ActionLog`、`StateLog`、`HttpFlowLog` 五类轻门面。
- 统一复用现有 `AppLogger.logEvent()`、`AppLogEvent`、`AppLogScope` 能力。
- 在门面内部自动补齐当前路由上下文，继续沿用现有脱敏、文本裁剪和频控能力。
- 提供 `buildAppTraceId()` 与 `ActionLog.run()`，为后续 HTTP/鉴权/业务链路串联预留统一入口。

### 2. 路由追踪

- 新增 `AppRouteTracker`，提供 `currentRoute`、`previousRoute` 和轻量路由栈快照。
- 通过 `track()` / `didPush()` / `didPop()` / `didReplace()` 统一维护路由状态。
- 在 `app_router.dart` 中接入初始化同步和路由切换监听。
- 为路由进入、退出、重定向分别输出结构化日志。

### 3. Provider 观察器

- 新增 `AppProviderObserver` 并挂入 `ProviderScope.observers`。
- 只记录包含 `auth/session/controller/role/router/shell` 等高价值关键字的 Provider。
- 记录 Provider 创建、状态变化和失败事件。
- 对前后文本快照一致的更新做跳过，降低日志噪音。

### 4. 生命周期日志

- 新增 `AppLifecycleLogger` 作为包装层，不破坏现有 `MaterialApp.router` 结构。
- 记录观察器挂载、卸载与 `resumed/inactive/hidden/paused/detached` 等生命周期事件。
- 统一通过 `AppFlowLog.lifecycle()` 输出 APP 分层日志。

### 5. 启动接入

- 在 `main.dart` 中为本次运行生成 `sessionId`，并通过 `AppLogScope.run()` 注入根作用域。
- 启动日志改为走 `AppFlowLog`。
- `ProviderScope` 接入 `AppProviderObserver`，后续核心 Provider 可直接进入统一日志链路。

## 测试与验证

- 按 TDD 先新增 `test/shared/logging/app_route_tracker_test.dart`。
- 失败验证：`flutter test test/shared/logging/app_route_tracker_test.dart`
  - 初次失败原因为 `app_route_tracker.dart` 不存在，符合预期。
- 通过验证：`flutter test test/shared/logging/app_route_tracker_test.dart`
  - 结果：通过。
- 回归验证：`flutter test test/shared/logging`
  - 结果：通过。
- 静态检查：`flutter analyze lib/main.dart lib/app/app.dart lib/app/router/app_router.dart lib/shared/logging`
  - 结果：`No issues found!`

## 约束符合性

- 继续使用本地排障模式，未引入远端日志平台。
- 未新增任何第三方依赖。
- 新增函数均补充了函数级中文注释。
- 关键状态维护与接入点已补中文注释。
- 仅补了高价值测试，未扩展低价值用例。

## 顾虑

- `AppProviderObserver` 当前采用关键字过滤高价值 Provider，能控制噪音，但后续若要覆盖更多业务链路，建议在 Task 3 之后按模块再精调白名单。
- 当前路由切换日志以 `go_router` 地址变化为准，已满足统一追踪要求；若后续需要更细粒度的页面实例级生命周期，可在不改变现有门面的前提下追加 `NavigatorObserver` 细节采集。

## 提交说明

- 预期提交信息：`feat(logging): add route and provider log observers`
