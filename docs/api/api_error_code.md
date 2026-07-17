# App 端错误码（AppErrorCode）总结

> 统一响应体：`AppResult { code, message, data, timestamp, requestId }`，`code=0` 表示成功。

## 一、错误码分段规则

| 段位 | 分类 |
|------|------|
| `0` | 成功 |
| `10001–10008` | 系统级 |
| `20001–20006` | 用户 / 认证 |
| `30001–30005` | 简历 / 岗位 / 应聘 |
| `40001–40007` | 订单 / 支付 |
| `50001–50002` | 签证套餐 |
| `60001–60002` | 文件 |
| `70001–70002` | AI |

## 二、完整清单

### 系统级（10001–10008）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 0 | `SUCCESS` | error.success | 成功 | Success |
| 10001 | `PARAM_ERROR` | error.param.error | 参数校验失败 | Parameter validation failed |
| 10002 | `UNAUTHORIZED` | error.unauthorized | 未登录或 Token 过期 | Not logged in or token expired |
| 10003 | `FORBIDDEN` | error.forbidden | 无权限操作 | No permission to perform this action |
| 10004 | `NOT_FOUND` | error.not.found | 资源不存在 | Resource not found |
| 10004 | `RESOURCE_NOT_FOUND` *(别名)* | error.not.found | 资源不存在 | Resource not found |
| 10005 | `CONFLICT` | error.conflict | 资源冲突（重复操作） | Resource conflict (duplicate operation) |
| 10006 | `RATE_LIMIT` | error.rate.limit | 请求频率超限 | Request rate limit exceeded |
| 10007 | `SERVER_ERROR` | error.server.error | 服务器内部错误 | Internal server error |
| 10008 | `SERVICE_UNAVAILABLE` | error.service.unavailable | 服务暂时不可用 | Service temporarily unavailable |

### 用户 / 认证（20001–20006）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 20001 | `PHONE_FORMAT_ERROR` | error.phone.format | 手机号格式错误 | Invalid phone number format |
| 20002 | `CODE_ERROR` | error.code.invalid | 验证码错误或已过期 | Verification code is invalid or expired |
| 20003 | `ACCOUNT_DISABLED` | error.account.disabled | 账号已被禁用 | Account has been disabled |
| 20004 | `ROLE_SWITCH_FAIL` | error.role.switch.fail | 角色切换失败（当前有未完成订单） | Failed to switch role (incomplete orders exist) |
| 20005 | `PHONE_ALREADY_USED` | error.phone.already.used | 该手机号已被其他账号使用，请先解绑后再绑定 | This phone number is already used by another account; please unbind it first |
| 20006 | `EMAIL_ALREADY_USED` | error.email.already.used | 该邮箱已被其他账号使用，请先解绑后再绑定 | This email is already used by another account; please unbind it first |

### 简历 / 岗位 / 应聘（30001–30005）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 30001 | `RESUME_INCOMPLETE` | error.resume.incomplete | 简历未完成，无法投递 | Resume incomplete, cannot apply |
| 30002 | `DUPLICATE_APPLY` | error.duplicate.apply | 本月已投递过该岗位，每月限投一次，下月可重新投递 | You have already applied for this job this month. You may apply again next month. |
| 30002 | `DUPLICATE_APPLICATION` *(别名)* | error.duplicate.apply | 同上 | 同上 |
| 30003 | `JOB_OFFLINE` | error.job.offline | 岗位已下线 | Job has been taken offline |
| 30004 | `CANNOT_DELETE_DEFAULT_RESUME` | error.resume.cannot.delete.default | 默认简历不可删除，请先切换默认简历后再删除 | Cannot delete default resume, please set another as default first |
| 30005 | `NO_DEFAULT_RESUME` | error.resume.no.default | 您还没有设置默认简历，请先创建或设置一份默认简历后再投递 | No default resume found, please create or set a default resume before applying |

### 订单 / 支付（40001–40007）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 40001 | `ORDER_STATUS_ERROR` | error.order.status | 订单状态不允许此操作 | Order status does not allow this operation |
| 40002 | `PAYMENT_TIMEOUT` | error.payment.timeout | 支付超时，请重新下单 | Payment timeout, please place order again |
| 40003 | `MATERIAL_REVIEWING` | error.material.reviewing | 材料审核中，请勿重复上传 | Materials under review, do not upload again |
| 40004 | `PAYMENT_METHOD_NOT_SUPPORTED` | error.payment.method.not.supported | 不支持的支付方式 | Payment method not supported |
| 40005 | `PAYMENT_CREATE_FAILED` | error.payment.create.failed | 支付下单失败，请重试 | Failed to create payment, please try again |
| 40006 | `PAYMENT_VERIFY_FAILED` | error.payment.verify.failed | 支付回调验签失败 | Payment callback verification failed |
| 40007 | `PAYMENT_NOT_FOUND` | error.payment.not.found | 支付流水不存在 | Payment record not found |

### 签证套餐（50001–50002）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 50001 | `PACKAGE_REJECTED` | error.package.rejected | 套餐审核驳回 | Package rejected by audit |
| 50002 | `PROVIDER_NOT_VERIFIED` | error.provider.not.verified | 服务商资质未认证，无法发布套餐 | Provider not verified, cannot publish packages |

### 文件（60001–60002）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 60001 | `FILE_SIZE_EXCEED` | error.file.size.exceed | 文件大小超限 | File size exceeds limit |
| 60002 | `FILE_TYPE_NOT_SUPPORT` | error.file.type.not.support | 文件类型不支持 | File type not supported |

### AI（70001–70002）

| code | 枚举 | messageKey | 中文 | English |
|------|------|-----------|------|---------|
| 70001 | `AI_SERVICE_UNAVAILABLE` | error.ai.unavailable | AI 服务暂时不可用 | AI service temporarily unavailable |
| 70002 | `AI_RATE_LIMIT` | error.ai.rate.limit | AI 对话频次受限（每天/每分钟） | ⚠️ 见下方"待补" |

## 三、HTTP 状态码映射（AppGlobalExceptionHandler）

| 异常 | HTTP 状态 | 返回 code |
|------|-----------|-----------|
| `AppException` | 200 | 对应的业务 code |
| `NotLoginException`（Sa-Token） | 401 | 10002 UNAUTHORIZED |
| `NotPermissionException`（Sa-Token） | 403 | 10003 FORBIDDEN |
| `MethodArgumentNotValid` / `BindException` / `ConstraintViolation` / 缺参 / JSON 解析 | 400 | 10001 PARAM_ERROR |
| `ServiceException`（common 层，如 `@RateLimiter` 限流） | 429 | 10006 RATE_LIMIT |
| 其他未捕获 `Exception` | 500 | 10007 SERVER_ERROR |

> 业务异常 `AppException` 走 HTTP 200 + body 里的 `code`，前端应以 `code` 判断结果，而非 HTTP 状态。

## 四、注意事项 / 待补

1. **别名码**：`RESOURCE_NOT_FOUND`＝`NOT_FOUND`（10004）、`DUPLICATE_APPLICATION`＝`DUPLICATE_APPLY`（30002），仅为方便服务层调用，code 与文案完全一致。
2. **`error.ai.rate.limit` 文案缺失**：`AI_RATE_LIMIT(70002)` 的 messageKey 在 `messages_zh/en.properties` 中**尚未定义**，`MessageUtils.message()` 找不到 key 会原样返回 `error.ai.rate.limit`。建议补齐三个 i18n 文件的该 key。
3. **文案获取**：`AppErrorCode.getMessage()` 通过 `MessageUtils` 按 `LocaleContextHolder.getLocale()`（通常由请求 `Accept-Language` 决定）返回中/英文；找不到 key 时返回 key 本身，不抛异常。
4. **段位余量**：各分类均预留了连续段位，新增错误码请按分类续号（如用户类下一个用 20007）。
