# Task 4 Report

## 任务结论

- 已完成 `bootstrap -> route -> auth restore/refresh` 核心启动链路的结构化日志补齐。
- 保持本地排障模式，日志仍输出到控制台与本地文件。
- 未新增第三方依赖，继续复用现有 `AppFlowLog`、`RouteLog`、`StateLog`、`AppLogger`、Riverpod 与 GoRouter。
- 仅补了一组高价值测试，重点覆盖鉴权恢复/刷新链路的事件可回放性与脱敏约束。

## 修改文件

- 修改 `lib/main.dart`
- 修改 `lib/app/router/app_router.dart`
- 修改 `lib/features/auth/application/auth_session_provider.dart`
- 修改 `lib/shared/logging/app_log_facade.dart`
- 新增 `test/features/auth/auth_session_logging_test.dart`

## 实现内容

### 1. 启动链路

- 在 `main.dart` 中为应用初始化增加 `APP_BOOTSTRAP_START / SUCCESS / FAIL` 三段式日志。
- 启动日志继续保留本地文件路径、会话 ID 等排障字段。
- 将“是否存在持久化凭据”改为非敏感布尔字段名，避免被统一脱敏规则错误裁掉。
- 启动异常会先输出 `APP_BOOTSTRAP_FAIL`，再交由现有全局异常处理继续兜底。

### 2. 路由链路

- 在 `app_router.dart` 中将关键守卫分支统一改为输出 `ROUTE_REDIRECT_APPLIED`。
- 重定向日志补齐了 `from / to / reason` 以及当前会话状态、可恢复目标路由等上下文。
- 保留现有 `RouteLogCoordinator` 的真实首屏与切页日志行为，不扩散到其他业务模块。

### 3. 鉴权恢复与刷新链路

- 在 `auth_session_provider.dart` 中为 `restoreSession()` 增加 `AUTH_RESTORE_START / SUCCESS / FAIL`。
- 为 `refreshCurrentUser()` 增加 `AUTH_REFRESH_START / SUCCESS / FAIL`。
- 日志统一通过 `StateLog.transition()` 输出，补齐 `from / to` 状态方向，方便回放启动阶段状态迁移。
- 关键上下文仅保留安全字段，例如用户 ID、角色、是否待选角色、是否存在会话凭据等。
- 失败分支额外记录是否执行了回退或清理登录态，便于区分“回退成功”和“彻底退出”。

### 4. 日志门面补齐

- 在 `app_log_facade.dart` 中新增：
  - `AppFlowLog.bootstrapStart()`
  - `AppFlowLog.bootstrapSuccess()`
  - `AppFlowLog.bootstrapFail()`
  - `RouteLog.redirectApplied()`
  - `StateLog.transition()`
- 所有新增函数均补充了函数级中文注释；关键判断处也补了简洁中文注释。

## 测试与验证

### 新增测试

- `test/features/auth/auth_session_logging_test.dart`

覆盖点：

- `restoreSession()` 会输出 `AUTH_RESTORE_START` 与 `AUTH_RESTORE_SUCCESS`
- `refreshCurrentUser()` 失败且存在回退用户时，会输出 `AUTH_REFRESH_START` 与 `AUTH_REFRESH_FAIL`
- 失败后状态会回退到登录快照
- 原始日志文件中不会明文落 access token、refresh token、手机号、邮箱

### 已执行命令

```bash
flutter test test/features/auth/auth_session_logging_test.dart
flutter test test/features/auth/auth_session_logging_test.dart test/app/router/app_router_test.dart
flutter analyze lib/main.dart lib/app/router/app_router.dart lib/features/auth/application/auth_session_provider.dart lib/shared/logging/app_log_facade.dart test/features/auth/auth_session_logging_test.dart
```

结果：

- 全部通过
- VS Code Diagnostics：相关改动文件均无新增诊断问题

## 关键设计说明

- 发布版仍保留详细日志，但敏感字段继续在统一出口做脱敏和长度裁剪。
- 为避免“仅仅因为字段名包含 token 就把布尔值也脱敏掉”，将若干存在性字段改为不触发敏感词规则的命名。
- 鉴权链路日志优先复用现有状态层日志门面，不新增新的日志层或注入机制。

## 已知顾虑

- 当前 `authSessionProvider.build()` 在检测到本地凭据时仍会自动调度一次 `restoreSession()`；生产场景符合预期，但在单测中如果同时手动调用恢复逻辑，会出现重复恢复日志，因此测试通过 traceId 过滤只断言目标链路。
- 本任务未补启动链路和路由重定向的专门日志断言测试，当前仅复用了既有路由协调器测试；后续若继续推进 Task 5 及更广业务链路，可再补更高层级的集成校验。

## 2026-07-04 审查问题二次修复

### 修复目标

- 修复 `main.dart` 中 `APP_BOOTSTRAP_SUCCESS` 记录过早的问题，避免启动流程尚未真正完成时就输出成功事件。
- 修复 `auth_session_provider.dart` 中 `restoreSession()` 与 `refreshCurrentUser()` 的 SUCCESS/FAIL 事件 `from` 状态不准确的问题，确保状态迁移能真实回放 `hydrating -> 最终态`。

### 本次修改

- `lib/main.dart`
  - 将 `APP_BOOTSTRAP_SUCCESS` 从 `runApp()` 之前移动到 `runApp()` 之后，并等待首帧完成后再记录。
  - 新增启动阶段异常跟踪器，在首帧前若命中 `FlutterError.onError` 或 `PlatformDispatcher.onError`，会先走 `APP_BOOTSTRAP_FAIL`，不再同时输出 SUCCESS。
  - 启动成功上下文中的 `phase` 更新为 `first_frame_rendered`，使日志语义与真实时机一致。
- `lib/features/auth/application/auth_session_provider.dart`
  - 为 `restoreSession()` 与 `refreshCurrentUser()` 显式保存进入 `hydrating` 后的中间态。
  - `AUTH_RESTORE_SUCCESS / FAIL`、`AUTH_REFRESH_SUCCESS / FAIL` 的 `from` 统一改为基于该 `hydrating` 中间态计算，不再复用最初旧态。
- `test/features/auth/auth_session_logging_test.dart`
  - 补强高价值断言，验证 `AUTH_RESTORE_SUCCESS` 与 `AUTH_REFRESH_FAIL` 的 `from / to` 是否真实反映迁移链路。

### 本次验证

```bash
flutter test test/features/auth/auth_session_logging_test.dart
flutter test test/features/auth/auth_session_logging_test.dart test/app/router/app_router_test.dart
flutter analyze lib/main.dart lib/features/auth/application/auth_session_provider.dart lib/shared/logging/app_log_facade.dart test/features/auth/auth_session_logging_test.dart
```

结果：

- 全部通过
- VS Code Diagnostics：本次修改文件无新增诊断问题

### 额外说明

- 当前高价值测试优先锁定鉴权迁移链问题，启动成功事件时机改动主要通过静态分析和相关回归验证；若后续需要进一步收敛启动阶段风险，可再补一条围绕首帧完成与全局异常竞争关系的专门测试。
