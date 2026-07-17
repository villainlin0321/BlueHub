# 网络层错误 Toast 改造方案

## Summary

基于 `docs/api/api_error_code.md` 对当前网络层进行统一错误提示改造，目标是让 `lib/shared/network` 与 `lib/shared/network/services` 发起的接口请求在业务失败时能够稳定展示 Toast，并优先直接使用后端 `AppResult.message` 作为用户提示文案。

本次方案采用“全局自动 toast + 清理重复提示点”的策略：

1. 网络层对 `AppResult.code != 0` 的业务失败统一识别，并在统一出口自动弹出 `AppResult.message`；
2. 前端不额外维护一份完整的 `code -> 文案` 本地映射表，错误码文档主要用于明确哪些返回属于业务失败、别名码如何看待、哪些缺失文案需要兜底；
3. 并发请求同时失败时采用“首个优先”策略：在约定时间窗口内仅展示第一条接口失败 Toast，后续失败不再追加弹窗；
4. 页面层保留首屏空态/错误态展示逻辑，但需要清理那些仅用于重复弹错的 `catch + AppToast.show(...)`；
5. 网络异常、HTTP 异常、解析异常继续沿用现有 `ApiException` 分类与兜底文案。

## Current State Analysis

### 1. 当前网络层已经能识别业务失败，但不会统一弹 Toast

- `lib/shared/network/api_result.dart`
    - `AppResult` 已包含 `code / message / data / timestamp / requestId`。
    - `isSuccess` 以 `code == 0` 判断成功。
- `lib/shared/network/api_client.dart`
    - `_unwrap()` 与 `_unwrapVoid()` 已在 `result.isSuccess == false` 时抛出 `ApiException.biz(code/message/requestId)`。
    - 这说明网络层已经拿到了实现统一提示所需的核心信息，不需要在 service 层逐个补判断。
- `lib/shared/network/api_exception.dart`
    - 已有 `network / http / biz / parse / unknown` 分类；
    - `biz` 会优先保留后端返回的 `message`，为空时才退回 `通用.业务异常`。

结论：当前缺的不是“业务错误识别”，而是“统一提示出口”和“避免页面重复提示”的机制。

### 2. 页面层已经大量依赖 `ApiException.message` 手动弹错

已确认多个页面/控制器都在做同一件事：捕获异常后，如果是 `ApiException`，直接取 `error.message` 继续 Toast。

典型例子：

- `lib/features/me/presentation/my_resume_page.dart`
- `lib/features/order/presentation/order_management_page.dart`
- `lib/features/jobs/presentation/job_apply_helper.dart`
- `lib/features/service_detail/presentation/visa_package_detail_scaffold.dart`
- `lib/features/me/presentation/finance_page_shared.dart`
- `lib/features/auth/presentation/login_phone_page.dart`

也存在通过 `feedbackMessage` 上抛到页面再 Toast 的模式，例如：

- `lib/features/auth/application/login/login_form_controller.dart`
- `lib/features/auth/select_role/application/select_role_controller.dart`
- `lib/features/jobs/application/post_job/post_job_controller.dart`

结论：如果直接在网络层新增自动 Toast，但不清理页面层，会出现双重提示。

### 3. 错误码文档对本次改造的实际意义

`docs/api/api_error_code.md` 说明了后端统一返回约定：

1. `code = 0` 表示成功；
2. 业务异常虽然很多场景是 HTTP 200，但前端必须以 body 中的 `code` 判断；
3. 错误码已分系统级、认证类、简历/岗位/应聘类、订单/支付类、签证套餐类、文件类、AI 类；
4. `10004/30002` 存在别名码，但 message 与语义一致；
5. 文档明确指出 `70002 AI_RATE_LIMIT` 的 i18n 文案目前后端可能缺失，`MessageUtils` 找不到 key 时会返回 `error.ai.rate.limit` 原文。

结论：

- 前端不需要复制整份错误码文案表；
- 但需要借助该文档决定哪些码属于“业务失败直接弹 `message`”；
- 同时要对“message 缺失/返回 key 本身”提供前端兜底策略，尤其是 `70002`。

### 4. 统一改造应优先落在 `ApiClient`，而不是各个 Service

- `lib/shared/network/services/*.dart` 基本都只是调用 `_apiClient.get/post/put/delete`；
- service 层没有统一 UI 上下文，也不适合直接依赖 Toast；
- 网络层只有 `ApiClient` 掌握所有普通 HTTP 请求的公共出口。

结论：核心能力应落在 `ApiClient` 及其关联的公共错误提示组件，service 层仅保持纯请求封装。

## Proposed Changes

### A. 在共享网络层增加“业务错误自动 Toast”能力

#### 1. `lib/shared/network/api_exception.dart`

补充与“是否已自动提示”相关的异常元数据，建议增加显式字段，例如：

- `bool hasShownToast`

并为构造器与各工厂方法补齐默认值：

- `network/http/parse/unknown` 默认 `false`
- `biz` 在网络层自动提示后可生成 `hasShownToast: true` 的异常实例，供页面层判断

原因：

- 仅靠 `type == biz` 无法区分“这个错误是否已经在网络层弹过”；
- 页面层后续收口时可以安全跳过已提示异常，避免重复 Toast；
- 这个标记也适用于后续 SSE 或上传等非标准链路逐步接入。

#### 2. `lib/shared/network/api_client.dart`

在 `_unwrap()` 与 `_unwrapVoid()` 的 `!result.isSuccess` 分支收口业务错误提示：

- 新增一个私有方法，例如 `_buildBizException(ApiResult result)` 或 `_handleBizFailure(...)`
- 逻辑顺序建议固定为：
    1. 读取 `result.code`
    2. 读取并清洗 `result.message`
    3. 基于错误码文档判断这是业务失败，统一弹 Toast
    4. 抛出带 `hasShownToast: true` 的 `ApiException.biz(...)`

Toast 文案策略：

1. 第一优先级：`AppResult.message.trim()` 非空且不是明显的 i18n key 时，直接弹它；
2. 第二优先级：若 message 为空或长得像 `error.xxx.xxx`，走前端兜底文案；
3. 第三优先级：若 code 未知且 message 也不可用，则退回 `通用.业务异常`。

为什么不直接按文档手写完整映射：

- 文档已经说明后端会根据语言环境返回 message；
- 复制完整映射会形成前后端双维护，后续极易漂移；
- 当前真实目标是“接口失败能正确提示”，不是在 Flutter 端重建一份后端错误码系统。

#### 3. `lib/shared/network/api_client.dart` 中补充业务码兜底解析表

虽然不维护完整文案映射，但建议维护一个“极小兜底表”，只覆盖以下情况：

- `70002 AI_RATE_LIMIT`
- 未来文档中明确“messageKey 尚未配置”或已知后端会返回 key 字符串的错误码

实现建议：

- 新增一个私有 `Map<int, String Function()>` 或单独私有方法；
- 当前最少覆盖：
    - `70002 -> 'AI 对话频次受限（每天/每分钟）'` 对应现有本地化 key 或临时兜底文案

这样既利用了错误码文档，又避免把整份文档全部搬到前端。

#### 4. `lib/shared/network/api_client.dart` 或新文件 `lib/shared/network/app_result_error_resolver.dart`（推荐新增）

建议把“业务失败提示文案解析”从 `ApiClient` 中拆成独立纯函数/工具类，例如：

- `resolveAppResultErrorMessage({required int code, required String message})`

职责：

- 接收 `code + message`
- 统一做 trim、i18n key 检测、兜底码处理
- 返回最终要展示的用户提示

原因：

- 方便单元测试；
- 避免 `ApiClient` 文件继续膨胀；
- 后续 file upload、SSE、controller 自定义失败分支也可以复用。

### B. 在 Toast 层保持统一出口，不把 UI 依赖散落到 services

#### 5. `lib/shared/widgets/app_toast.dart`

在当前统一 Toast 组件上增加一个轻量级全局闸门，实现“首个优先”策略。

建议能力：

- 新增一个仅给网络层失败使用的入口，例如：
    - `showFirstPriorityError(...)`
    - 或 `showOnceWithinWindow(...)`
- 在 `AppToast` 内维护最小状态：
    - 最近一次被放行的时间戳；
    - 固定时间窗口，建议先从 `1500ms ~ 2000ms` 起步；
- 放行规则固定为：
    1. 当前时间距离上一次放行未超过窗口时，直接忽略；
    2. 超过窗口时，展示本次 Toast，并刷新时间戳。

这样在“多个接口同时报错”时：

- 只展示第一条失败；
- 后续并发失败不会继续顶掉前面的提示；
- 超过窗口后的新错误仍能正常提示。

本次计划中 `AppToast` 的职责仍然是：

- 网络层和页面层统一走同一个展示组件；
- 不让 service 直接持有页面上下文。

### C. 清理页面层重复错误 Toast，按场景分两类处理

#### 6. 清理“只为重复弹错而存在”的页面 Toast

需要重点检索并收口以下模式：

- `if (error is ApiException) return error.message;`
- `AppToast.show(_resolveErrorMessage(error));`
- `AppToast.show(_normalizeError(error));`
- controller 中将 `ApiException.message` 塞入 `feedbackMessage`，页面再 toast

处理原则：

1. **操作型失败**：如果网络层已经自动弹错，页面层不再重复 `AppToast.show(error.message)`；
2. **内容态失败**：如果页面需要首屏错误空态/占位文案，仍保留 `_errorMessage = ...`，但不额外弹一次 Toast；
3. **非接口失败**：本地校验失败、路由参数缺失、文件地址无效、权限问题等，继续保留页面层 Toast。

优先关注的文件组：

- `lib/features/me/presentation/*.dart`
- `lib/features/order/presentation/*.dart`
- `lib/features/jobs/presentation/*.dart`
- `lib/features/service_detail/presentation/*.dart`
- `lib/features/auth/presentation/*.dart`
- `lib/features/visa/presentation/*.dart`

#### 7. 对 `feedbackMessage` 型状态流做“来源分流”

部分控制器不是直接在页面 `catch`，而是把错误文字放进状态，例如：

- `lib/features/auth/application/login/login_form_controller.dart`
- `lib/features/auth/select_role/application/select_role_controller.dart`
- `lib/features/jobs/application/post_job/post_job_controller.dart`
- `lib/features/me/application/blacklist/blacklist_controller.dart`
- `lib/features/ai/application/ai_assistant/ai_assistant_controller.dart`

需要逐个区分：

1. `feedbackMessage` 来自接口业务失败：
    - 如果已经通过网络层自动 Toast，则不要再把相同 message 往上冒泡给页面重复弹；
    - 更合适的做法是仅保留状态切换，不设置 toast 型 feedback，或增加 `shouldToast`/`feedbackConsumed` 之类的区分。
2. `feedbackMessage` 来自本地成功提示或本地校验提示：
    - 继续保留，例如“发送成功”“保存成功”“请选择学校”等。

额外约束：

- 页面层本地成功提示不受“首个优先”闸门影响，仍走普通 `AppToast.show(...)`；
- 只有网络层自动错误提示走“首个优先”入口，避免把成功提示、本地校验提示一并吞掉。

### D. 覆盖非 `ApiClient` 标准链路，保证行为一致

#### 8. `lib/shared/network/services/file_service.dart`

该文件已有自定义 `ApiException.http(...)` / 自定义错误消息组装逻辑，不完全经过 `ApiClient._unwrap()`。

需要检查并统一：

- 上传接口业务失败时是否也会拿到 `code/message`；
- 若有自定义解析逻辑，需复用同一套 `resolveAppResultErrorMessage(...)`；
- 如果 file service 当前仍在页面层额外 toast，要同步清理重复提示。

#### 9. `lib/shared/network/sse_client.dart`

SSE 不在本次“普通接口调用”主链路，但它也会抛 `ApiException`。本轮计划不强制为 SSE 自动弹 Toast，只需确认：

- SSE 保持现有行为；
- 不误接入普通 HTTP 的自动 toast 分支；
- 在计划说明里明确其为 out of scope，避免执行时扩散。

### E. 验收时使用错误码文档驱动测试覆盖，而不是逐页手工拍脑袋

#### 10. 测试策略

需要新增/补充以下层级验证：

1. **网络层单元测试**
    - 针对 `ApiClient` 或新 resolver：
        - `code = 0` 不弹错；
        - `code = 20002/30002/40001` 等业务失败时返回后端 message，并标记为已提示；
        - `code = 70002` 且 message 为 `error.ai.rate.limit` 时走前端兜底；
        - `message` 为空时走 `通用.业务异常`；
        - 在时间窗口内连续触发多个业务失败时，只放行第一条 Toast。

2. **页面层回归验证**
    - 选择几个高频页面做 widget / 行为回归，至少覆盖：
        - 首屏加载失败页只展示错误态，不重复 toast；
        - 按钮提交失败只弹一次 toast；
        - 本地校验失败仍能弹 toast；
        - 并发多个接口失败时只出现第一条 toast。

3. **静态扫描验证**
    - 通过 `rg` 检查 `ApiException.message -> AppToast.show` 的残留点，确保本轮收口范围明确；
    - 对保留点写明原因，例如本地错误、非网络链路错误、空态展示。

#### 11. 建议的重点验证页面

- `lib/features/auth/presentation/login_phone_page.dart`
    - 验证登录失败是否只弹一次；
- `lib/features/me/presentation/my_resume_page.dart`
    - 验证首屏加载失败是错误态，不重复 toast；
- `lib/features/order/presentation/order_management_page.dart`
    - 验证分页加载更多失败只弹一次；
- `lib/features/jobs/presentation/job_detail_page.dart` / `job_search_page.dart`
    - 验证投递失败只弹一次；
- `lib/features/service_detail/presentation/visa_package_detail_scaffold.dart`
    - 验证收藏/操作失败只弹一次。

## Assumptions & Decisions

1. 以后端 `AppResult.message` 作为业务失败提示的主来源，不在 Flutter 端维护完整错误码中文/英文文案表。
2. `docs/api/api_error_code.md` 的主要用途是：
    - 确认 body `code` 才是真实业务结果；
    - 指导前端识别别名码与业务分类；
    - 明确少数需要本地兜底的错误码（当前已知重点是 `70002`）。
3. 本次改造只覆盖普通接口调用主链路，即 `ApiClient` 驱动的 HTTP 请求与其页面消费逻辑。
4. 网络层自动错误提示采用“首个优先”策略：同一时间窗口内仅展示第一条接口失败 Toast，后续接口失败直接忽略，不排队、不覆盖。
5. 页面首屏错误态文案仍允许继续使用 `ApiException.message` 填充，但不应在相同场景再重复弹 Toast。
6. 本地校验、权限说明、文件选择失败、路由参数缺失等非后端业务失败，不纳入网络层自动 Toast，保持页面层现状。
7. 若执行中发现某些控制器的 `feedbackMessage` 同时承载“成功提示”和“错误提示”，应优先做最小分流，而不是全量重构状态模型。

## Verification Steps

1. 为网络层新增/补齐单元测试，覆盖：
    - `code=0`
    - 常规业务失败码
    - `message` 为空
    - `message` 为 i18n key
    - `70002` 兜底
2. 对改造后的高频页面执行静态回归检查：
    - 不再存在明显重复的 `ApiException.message -> AppToast.show` 链路；
    - 首屏错误态页面仍有可见错误文案；
    - 提交型操作失败仍能给出一次明确提示。
3. 运行项目既有静态校验（至少 `flutter analyze`）。
4. 手工验证至少以下场景：
    - 登录失败；
    - 岗位投递失败；
    - 订单列表加载更多失败；
    - 简历列表首屏失败；
    - AI 限流失败。
5. 验证 toast 行为：
    - 同一失败场景只出现一次 toast；
    - 多个接口并发失败时，仅第一条失败 toast 会展示；
    - 文案优先显示后端返回的自然语言 message；
    - 对于后端 message 缺失的已知错误码，前端能展示合理兜底文案。
