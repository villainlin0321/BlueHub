# Task 3 Report

## 任务目标

完成日志系统第三步，把 HTTP 请求链路与 `route`、`traceId`、业务 `action` 串联起来，为后续鉴权和业务日志接入提供统一基础。

## 实现概述

- 在 `lib/shared/logging/app_log_facade.dart` 为 `HttpFlowLog` 补充 `requestStart()`、`requestSuccess()`、`requestFail()` 语义化入口。
- 在 `lib/shared/network/interceptors/app_log_interceptor.dart` 的 `onRequest` 阶段把当前 `AppLogScope` 与 `AppRouteTracker` 中的链路字段写入 `RequestOptions.extra`。
- 在同一拦截器的 `onResponse` 与 `onError` 阶段继续复用 `RequestOptions.extra` 中的链路字段，保证 request/response/error 三段日志不丢链。
- 在 `lib/shared/network/api_client.dart` 的公共请求入口补充最小 `extra` 透传，统一把 `httpPath`、`traceId`、`route`、`logAction` 向下传递给 Dio 请求。
- 新增 `test/shared/network/app_log_interceptor_test.dart`，验证 `traceId`、`route`、`logAction` 会写入请求上下文。

## 关键实现说明

### 1. HTTP 日志门面统一出口

- 之前网络日志主要通过 `AppLogger.instance.info/error` 直接输出，缺少统一的 HTTP 语义事件。
- 现在由 `HttpFlowLog.requestStart()`、`requestSuccess()`、`requestFail()` 统一输出结构化 HTTP 事件。
- 这样后续新增鉴权、岗位发布、消息等业务日志时，可以直接复用同样的请求生命周期语义。

### 2. 请求上下文串联

- `AppLogInterceptor.onRequest()` 会优先从 `RequestOptions.extra` 读取链路字段。
- 若调用方未显式传值，则回退到 `AppLogScope.current`。
- `route` 还会进一步回退到 `AppRouteTracker.instance.currentRoute`，避免仅靠业务显式传参。
- 命中的链路字段会写回 `RequestOptions.extra['traceId']`、`RequestOptions.extra['route']`、`RequestOptions.extra['logAction']`。

### 3. 三段日志不断链

- `requestStart`、`requestSuccess`、`requestFail` 都从同一个 `RequestOptions.extra` 读取链路字段。
- 日志字段统一输出为 `traceId`、`route`、`action`，其中请求上下文内部继续保留 `logAction` 作为 extra 键名。
- 这样既满足任务要求的 `extra` 结构，也避免最终日志里同时出现 `action` 和 `logAction` 的重复语义。

### 4. 公共请求入口最小透传

- `ApiClient` 新增 `_buildRequestOptions()` 和 `_buildRequestExtra()`。
- 公共请求入口会在不覆盖业务层显式值的前提下，把 `httpPath`、`traceId`、`route`、`logAction` 写入 `Options.extra`。
- 这样拦截器、异常映射和后续业务层都能看到同一份最小上下文。

## 关于 `dio_factory.dart` 与 `providers.dart`

- 已按任务说明核查这两个文件。
- 当前 `DioFactory.create()` 已经正确挂载 `AppLogInterceptor(enabled: true)`，`providers.dart` 也已通过 `dioProvider` / `apiClientProvider` 把链路接通。
- 为遵守“只做必要接线，不扩 scope”的约束，本任务未对这两个文件做额外修改，避免引入低价值噪音变更。

## TDD 记录

### Red

- 先新增 `test/shared/network/app_log_interceptor_test.dart`。
- 初次运行 `flutter test test/shared/network/app_log_interceptor_test.dart` 失败。
- 失败原因符合预期：`options.extra['traceId']` 为 `null`，说明测试确实覆盖了缺失行为。

### Green

- 实现 `AppLogInterceptor` 链路字段写入与 `HttpFlowLog` 语义化输出。
- 重新运行同一测试后通过。

## 验证结果

### 测试

```bash
flutter test test/shared/network/app_log_interceptor_test.dart
```

- 结果：通过。

### 静态检查

```bash
flutter analyze lib/shared/network/interceptors/app_log_interceptor.dart lib/shared/network/api_client.dart lib/shared/network/dio_factory.dart lib/shared/logging/app_log_facade.dart
```

- 结果：`No issues found!`

### 编辑器诊断

- `lib/shared/network/interceptors/app_log_interceptor.dart`：无诊断问题。
- `lib/shared/network/api_client.dart`：无诊断问题。
- `lib/shared/logging/app_log_facade.dart`：无诊断问题。
- `test/shared/network/app_log_interceptor_test.dart`：无诊断问题。

## 变更文件

- 修改：`lib/shared/logging/app_log_facade.dart`
- 修改：`lib/shared/network/interceptors/app_log_interceptor.dart`
- 修改：`lib/shared/network/api_client.dart`
- 新增：`test/shared/network/app_log_interceptor_test.dart`

## 风险与后续建议

- 当前只补了必需的高价值单测，尚未覆盖 `onResponse` / `onError` 是否带上同一链路字段的回归测试；如后续继续做 Task 4/5，建议补一个失败链路测试，验证异常日志也能完整回放。
- 当前 `action` 最终来自 `AppLogScope` 或 `Options.extra` 的最小透传；后续若业务层引入统一动作埋点规范，建议明确 `action` 命名约定，避免不同模块出现大小写或语义不一致。
