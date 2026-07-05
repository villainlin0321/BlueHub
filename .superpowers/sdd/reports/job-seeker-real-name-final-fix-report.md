# 求职者实名认证最终修复报告

## 2026-07-05 最终验收修复

### 修复范围

- 仅处理求职者实名认证相关文件。
- 仅使用 `isVerified` 作为实名状态来源。
- 未改动企业/服务商资质认证流。
- 未新增接口、依赖或后端未约定的加密协议。

### 问题 1：身份证号进入 HTTP 日志

#### 根因

- HTTP 请求日志会把结构化 `body/response` 交给统一日志出口递归脱敏。
- 现有敏感键规则仅覆盖 `token/authorization/password/secret/phone/email`，未覆盖 `realName`、`idCardNumber`、`idCardFrontUrl`、`idCardBackUrl` 等实名字段。

#### 修复

- 在 `lib/shared/logging/app_log_event.dart` 中补充实名与身份证类字段的统一脱敏规则。
- 保持接口请求体契约不变，不凭空引入客户端加密协议。
- 在 `test/shared/network/app_log_interceptor_test.dart` 中补充高价值回归测试，验证：
  - 结构化请求体中的 `realName/idCardNumber/idCardFrontUrl/idCardBackUrl` 会被脱敏。
  - 失败响应中的实名字段会被脱敏。
  - 原始日志文本中不再出现这些明文值。

### 问题 2：`idCardFrontUrl/idCardBackUrl` 与国徽面/人像面语义映射反了

#### 根因

- 页面内部把左侧“国徽面”上传状态直接映射到 `idCardFrontUrl`，把右侧“人像面”映射到 `idCardBackUrl`。
- 后端契约语义中 `front` 对应人像面，`back` 对应国徽面。

#### 修复

- 将页面内部状态改为明确的语义命名：`_emblemImage`、`_portraitImage`。
- 新增 `_buildRealNameVerifyRequest()`，集中处理契约映射：
  - `idCardFrontUrl = portrait`
  - `idCardBackUrl = emblem`
- 将上传区测试 key 同步改为：
  - `id-card-emblem-upload`
  - `id-card-portrait-upload`
- 在 `test/features/me/job_seeker_real_name_page_test.dart` 中补充提交断言，确保请求体按契约提交人像面 front、国徽面 back。

### 问题 3：实名提交成功但 `/users/me` 刷新失败时被误报“提交失败”

#### 根因

- 页面把“实名提交成功”和“资料刷新成功”绑定成了单一成功条件。
- `refreshCurrentUser()` 返回 `false` 时，当前页直接 toast“实名认证提交失败”并停留在表单页，造成语义错误。

#### 修复

- 提交成功后优先走成功路径，不再把刷新失败伪装成提交失败。
- 新增 `_handleSubmitSuccess()`：
  - 刷新成功：提示 `实名认证提交成功` 并返回。
  - 刷新失败：提示 `实名认证提交成功，但资料刷新失败，请稍后重新进入查看` 并返回。
- 仍保留 `refreshCurrentUser(fallbackUser: ...)` 的会话保护逻辑，避免刷新异常时清空登录态。
- 在 `test/features/me/job_seeker_real_name_page_test.dart` 中补充回归测试，验证刷新失败时：
  - 页面仍按成功路径返回；
  - 文案不再出现“实名认证提交失败”；
  - 登录态不会被清空。

### 问题 4：补一条基于真实 GoRouter 的高价值测试

#### 根因

- 原测试宿主通过手动 `Navigator.push` 打开实名页，绕过了真实路由跳转链。

#### 修复

- 在 `test/features/me/job_seeker_real_name_page_test.dart` 中新增真实 `GoRouter` 测试宿主。
- 使用 `RoutePaths.me` 与 `RoutePaths.jobSeekerRealNameVerification` 注册测试路由，真实点击“我的”页入口，验证：
  - 入口点击走 `context.push(...)`；
  - GoRouter 真正切到实名页；
  - 不再依赖手动 push 绕过链路。

### 变更文件

- `lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
- `lib/shared/logging/app_log_event.dart`
- `test/features/me/job_seeker_real_name_page_test.dart`
- `test/shared/network/app_log_interceptor_test.dart`
- `assets/translations/zh.json`
- `assets/translations/en.json`

### 验证命令

```bash
flutter test test/features/me/job_seeker_real_name_page_test.dart test/shared/network/app_log_interceptor_test.dart
flutter analyze lib/features/me/presentation/job_seeker_real_name_verification_page.dart lib/shared/logging/app_log_event.dart test/features/me/job_seeker_real_name_page_test.dart test/shared/network/app_log_interceptor_test.dart
```

### 验证结果

- `flutter test ...` 通过。
- `flutter analyze ...` 通过，`No issues found!`。
