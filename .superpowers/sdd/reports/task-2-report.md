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

## 审查修复记录（2026-07-04）

### 修复范围

- 仅修复本轮审查指定的两个阻塞问题。
- `Patrol` 相关改动按人类决策保留，不作为本轮修复项。

### 修复项 1：Provider 观察器不再误吞关键状态变化

- 问题根因：原实现基于 `toString()` 文本快照去噪，像 `AuthSessionState` 这类未自定义 `toString()` 的对象，前后都会表现为 `Instance of 'Xxx'`，导致真实状态变化被误判为重复噪音。
- 修复策略：仅对基础类型、集合、`DateTime`、`Uri` 等可稳定比较的值生成可比较快照；复杂对象若缺少稳定快照，则保留更新日志，不再基于 `toString()` 误判跳过。
- 去噪保留：对于基础类型、集合等可判等值，仍继续执行去噪，避免高频简单状态写入刷屏。
- 验证方式：新增并通过 `test/shared/logging/app_provider_observer_test.dart`，用一个与 `AuthSessionState` 一样缺少自定义 `toString()` 的假状态对象复现并验证日志不会被吞掉。

### 修复项 2：启动阶段首条路由日志只在真实首屏解析后记录

- 问题根因：`app_router.dart` 之前在 `GoRouter` 创建后立即用回退值读取当前路由，并直接记录首条 `ROUTE_ENTER`，当首轮匹配尚未完成时，会伪造一条 `/login` 进入事件。
- 修复策略：新增 `RouteLogCoordinator`，在路由尚未解析出真实地址时返回空事件；只有拿到真实首屏后才输出第一条进入日志，后续切页统一产出“先退出旧页、再进入新页”的回放顺序。
- 追踪同步：路由追踪器改为跟随协调器输出的真实事件更新，避免日志与 `AppRouteTracker` 状态不一致。
- 验证方式：新增并通过 `test/app/router/app_router_test.dart`，覆盖“未完成匹配不记日志”和“真实切页先 exit 后 enter”两个关键场景。

### 本轮验证

- 失败验证：`flutter test test/shared/logging/app_provider_observer_test.dart test/app/router/app_router_test.dart`
  - 初始失败点为 `RouteLogCoordinator` 与 `RouteLogTransitionType` 尚未实现，符合预期。
- 通过验证：`flutter test test/shared/logging/app_provider_observer_test.dart test/app/router/app_router_test.dart`
  - 结果：通过。
- 回归验证：`flutter test test/shared/logging test/app/router`
  - 结果：通过。
- 静态检查：`flutter analyze lib/main.dart lib/app/app.dart lib/app/router/app_router.dart lib/shared/logging test/shared/logging/app_provider_observer_test.dart test/app/router/app_router_test.dart`
  - 结果：`No issues found!`

### 本轮顾虑

- `AppProviderObserver` 现在采取“可稳定比较的简单值继续去噪，复杂对象默认保留更新”的策略，已经避免误吞关键状态变化；代价是复杂对象更新日志会偏保守一些，但这比漏掉关键会话切换更安全。
- `RouteLogCoordinator` 解决了首条伪造进入事件问题；如果后续需要记录更细粒度的页面实例生命周期，仍建议在后续任务中追加页面级埋点，而不是再次依赖初始化回退值推断。
