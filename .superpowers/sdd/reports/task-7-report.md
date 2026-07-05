# Task 7 Report

## 任务目标

- 按 `/.superpowers/sdd/task-7-brief.md` 要求，为黑名单、简历编辑、订单详情、支付弹层补齐高频页面交互日志。
- 保持本地排障模式，继续输出到控制台 + 本地文件，不新增任何第三方依赖。
- 发布版日志策略继续沿用详细日志 + 脱敏/裁剪/必要频控。
- 仅补高价值测试，重点验证支付弹层打开与确认支付日志。

## 实现概览

### 1. 日志门面补齐复用辅助方法

- 修改 `lib/shared/logging/app_log_facade.dart`
- 新增 `ActionLog.tap()`、`ActionLog.sheetOpen()`、`ActionLog.scrollReachEnd()`、`StateLog.step()`
- 目的：
  - 统一点击、弹层打开、列表触底、页面单步状态事件的日志写法
  - 避免各页面重复拼接 `actionType`
  - 让 Task 7 的埋点风格与既有日志门面保持一致

### 2. 黑名单页补齐页面进入与触底日志

- 修改 `lib/features/me/presentation/blacklist_page.dart`
- 新增 `BLACKLIST_PAGE_ENTER`
  - 在页面 `initState` 时通过 `StateLog.step()` 记录进入事件
  - 上下文包含 `route/module/feature/currentPage/itemCount/hasNext/totalCount`
- 新增 `BLACKLIST_SCROLL_REACH_END`
  - 在真正接近底部且满足 `loadMore()` 触发条件前记录
  - 增加 `_hasLoggedScrollReachEnd` 避免同一次触底被重复刷屏
  - 在翻页状态变化后自动重置节流标记，允许下一次真实触底继续记录

### 3. 简历编辑页补齐保存点击日志

- 修改 `lib/features/me/presentation/my_resume_editor_page.dart`
- 新增 `RESUME_SAVE_TAP`
  - 仅在“保存”按钮路径记录，不扩到“提交并预览”
  - 使用 `AppLogScope.run()` 在点击时创建链路上下文，保证后续保存请求自动继承同一条 `traceId`
- 安全上下文字段：
  - `route/module/feature`
  - `mode`
  - `hasResumeId`
  - `completionRate`
  - `jobTagCount/countryTagCount/languageCount/experienceCount/certificateCount/educationCount`
  - `hasSelfEvaluation`
  - `salaryMinFilled/salaryMaxFilled`
  - `isPublic`
- 未直接记录简历正文、自我评价原文、手机号、备注等敏感文本

### 4. 订单详情页补齐直接支付点击日志

- 修改 `lib/features/order/presentation/order_detail_page.dart`
- 新增订单详情页支付交互上下文构建函数
- 在 `_handlePayNow()` 里把支付发起包进 `AppLogScope.run()`
- 新增 `ORDER_PAYMENT_CONFIRM_TAP`
  - 在真实支付调用前立即记录
  - 上下文包含 `route/module/feature/source/orderId/paymentMethod/orderStatus/currentStep`
- 这样订单详情页直接支付分支的后续网络/支付日志也能继承同一链路上下文

### 5. 支付弹层补齐打开与确认支付日志

- 修改 `lib/features/order/presentation/order_payment_bottom_sheet.dart`
- 新增 `ORDER_PAYMENT_SHEET_OPEN`
  - 在 `show()` 内部通过 `AppLogScope.run()` 包住整段弹层生命周期
  - 弹层刚打开时立即记录，确保后续确认支付沿用同一条 `traceId`
- 新增 `ORDER_PAYMENT_CONFIRM_TAP`
  - 在 `_handlePayNow()` 内部、真正调用支付前记录
  - 上下文包含 `route/module/feature/source/orderId/paymentMethod`
- 按 brief 要求把底部主按钮空闲文案调整为“确认支付”，与测试和交互语义保持一致
- 安全上下文仅记录 `orderId/amount/currency/hasPackageName` 等摘要信息，不写套餐原文

## 测试与验证

### 高价值测试

- 修改 `test/widget_test.dart`
- 删除失效且低价值的首页冒烟断言，替换为本任务要求的支付弹层日志测试
- 新增测试：
  - `支付弹层打开和确认支付会输出关键交互日志`
- 测试策略：
  - 通过 `FakeLogRecorder` 拦截控制台结构化日志
  - 通过 `TestOrderPaymentHost` 复用真实 `OrderPaymentBottomSheet.show()` 入口
  - 通过 `_FakePaymentFlowCoordinator` 阻断真实网络，仅验证关键交互日志是否输出

### 已执行命令

```bash
flutter test test/widget_test.dart
flutter analyze lib/features/me/presentation/blacklist_page.dart lib/features/me/presentation/my_resume_editor_page.dart lib/features/order/presentation/order_detail_page.dart lib/features/order/presentation/order_payment_bottom_sheet.dart
```

### 结果

- `flutter test test/widget_test.dart`：通过
- `flutter analyze ...`：通过，无诊断问题

## 约束符合性检查

- 本地排障模式：未改动控制台 + 本地文件双写策略，仍由现有 `AppLogger` 负责
- 发布版保留详细日志：未降级已有日志粒度，继续复用现有脱敏/裁剪出口
- 禁止新增依赖：未修改 `pubspec.yaml`
- 新增函数中文注释：已补齐
- 关键代码中文注释：已补齐
- 仅补高价值测试：仅新增支付弹层关键交互日志测试

## 风险与顾虑

- 测试环境仍会打印 `EasyLocalization` 的缺失 key 警告，但不影响本任务日志断言与通过结果；本轮未扩展翻译资源，保持任务聚焦。

---

## 2026-07-05 审查问题二次修复

### 本轮修复目标

- 修复 `OrderPaymentBottomSheet.show()` 与确认支付点击之间 `traceId` 断链，保证 `ORDER_PAYMENT_SHEET_OPEN` 与 `ORDER_PAYMENT_CONFIRM_TAP` 落在同一条链路
- 修复 `PaymentFlowCoordinator.startPayment()` 覆盖上游 `traceId` 的问题，仅在缺失时补建支付链路
- 修复支付弹层“确认支付”文案在真实界面回退 key 的问题，并补强对应高价值测试

### 根因分析

- 支付弹层打开时虽然在 `show()` 里通过 `AppLogScope.run()` 创建了 `traceId`，但按钮点击回调发生在后续异步事件里，未显式复用该 `traceId`，随后又以只传 `fields` 的方式进入新作用域，导致确认支付日志可能沿用不到弹层打开时的链路
- `PaymentFlowCoordinator.startPayment()` 一进入就直接 `buildAppTraceId('payment')`，会覆盖订单详情页或支付弹层上游已创建的用户交互链路
- 任务 7 新增的支付弹层文案在测试与局部运行环境里会回退到 key，本质上是支付弹层自身不应继续依赖这组不稳定的 key 解析路径

### 实际改动

- 修改 `lib/features/order/presentation/order_payment_bottom_sheet.dart`
- 修改 `lib/features/order/presentation/order_payment_widgets.dart`
- 新增 `lib/features/order/presentation/order_payment_copy.dart`
- 修改 `lib/features/order/application/payment/payment_flow_coordinator.dart`
- 修改 `lib/features/order/presentation/order_detail_page.dart`
- 修改 `assets/translations/zh.json`
- 修改 `assets/translations/en.json`
- 修改 `test/widget_test.dart`
- 修改 `test/features/order/payment_flow_logging_test.dart`

### 修复说明

- 弹层链路贯穿：
  - 在 `OrderPaymentBottomSheet.show()` 里先生成一次 `traceId`
  - 显式把该 `traceId` 传给 `_OrderPaymentBottomSheetContent`
  - 在 `_handlePayNow()` 里再次通过 `AppLogScope.run(traceId: widget.traceId, ...)` 复用，确保打开弹层和确认支付属于同一条链路
- 支付协调器链路复用：
  - 新增 `_resolvePaymentTraceId()`
  - 优先读取 `AppLogScope.current['traceId']`
  - 仅在上游缺失时才 `buildAppTraceId('payment')`
- 文案回退修复：
  - 新增 `OrderPaymentCopy` 轻量文案助手，按当前界面语言稳定返回“确认支付/支付中/支付倒计时/支付方式/失败提示”
  - 支付弹层和支付方式卡片不再把 key 原样暴露到界面
  - 同步补齐 `assets/translations/zh.json` 与 `assets/translations/en.json` 中的 `订单支付` 文案，保持资源层与界面文案一致

### 本轮测试与分析

```bash
flutter test test/widget_test.dart
flutter test test/features/order/payment_flow_logging_test.dart
flutter analyze lib/features/order/presentation/order_payment_bottom_sheet.dart lib/features/order/presentation/order_payment_widgets.dart lib/features/order/presentation/order_payment_copy.dart lib/features/order/application/payment/payment_flow_coordinator.dart lib/features/order/presentation/order_detail_page.dart test/widget_test.dart test/features/order/payment_flow_logging_test.dart
```

### 本轮结果

- `flutter test test/widget_test.dart`：通过，已断言 `ORDER_PAYMENT_SHEET_OPEN` 与 `ORDER_PAYMENT_CONFIRM_TAP` 的 `traceId` 相同，且界面展示“确认支付”而不是 key
- `flutter test test/features/order/payment_flow_logging_test.dart`：通过，已断言 `startPayment()` 在上游已有 `traceId` 时完整复用到创建、拉起、轮询日志
- `flutter analyze ...`：通过，无诊断问题

### 本轮剩余顾虑

- `test/features/order/payment_flow_logging_test.dart` 仍会看到既有的 `服务详情.支付成功` 缺失 key 警告；这属于支付成功提示的历史文案问题，不在本次用户限定的修复范围内，本轮未继续扩散到支付协调器文案逻辑
