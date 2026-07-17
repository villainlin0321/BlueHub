# 系统通知类型清单（前端对接）

## 前端拿到的字段（NotificationVO）

| 字段 | 说明 |
|------|------|
| `notificationId` | 通知 ID |
| `type` | **粗分类**：`order_status`（订单）/ `application`（投递）/ `system`（系统，暂未使用） |
| `title` | 已按请求语言渲染的标题 |
| `content` | 已按请求语言渲染的内容 |
| `bizType` | **跳转目标类型**：`order` / `application` / `job` / `package` |
| `bizId` | 跳转目标业务 ID（配合 bizType 做详情跳转） |
| `isRead` | 是否已读 |
| `createdAt` | 时间 |

> 跳转判断：用 `bizType` + `bizId`。例如 `bizType=order` → 跳订单详情 `/orders/{bizId}`；`bizType=application` → 跳投递详情。

## 一、投递类（type = `application`，bizType = `application`，bizId = applicationId）

| 面向角色 | 触发时机 | 标题(中/英) | 内容(中/英，`{0}`=岗位名) |
|---------|---------|------------|--------------------------|
| employer | 求职者投递岗位 | 收到新的简历投递 / New application received | 有求职者投递了您的岗位《{0}》 / A candidate applied to your job "{0}" |
| worker | 企业邀约面试 | 面试邀约 / Interview invitation | 企业邀请您参加《{0}》的面试 / You are invited to interview for "{0}" |
| worker | 投递被查看 | 投递状态更新 / Application status updated | 您投递的《{0}》已被查看 / Your application for "{0}" has been viewed |
| worker | 进入面试 | 投递状态更新 | 您投递的《{0}》进入面试环节 |
| worker | 被拒 | 投递状态更新 | 很遗憾，您投递的《{0}》未通过筛选 |
| worker | 录用 | 投递状态更新 | 恭喜！您投递的《{0}》已被录用 |
| worker | 其他状态变更 | 投递状态更新 | 您投递的《{0}》状态有更新 |

## 二、订单类（type = `order_status`，bizType = `order`，bizId = orderId）

| 面向角色 | 触发时机 | 标题(中/英) | 内容(中/英，`{0}`=订单号) |
|---------|---------|------------|--------------------------|
| visa_provider | 用户下单 | 收到新订单 / New order received | 您有一笔新的签证订单待处理，订单号 {0} |
| worker | 支付成功 | 支付成功 / Payment successful | 订单 {0} 支付成功，请上传办理材料 |
| visa_provider | 支付成功 | 订单已支付 / Order paid | 订单 {0} 已完成支付 |
| visa_provider | 用户上传材料 | 材料待审核 / Materials pending review | 订单 {0} 的申请人已上传材料，请及时审核 |
| worker | 材料审核通过 | 材料审核通过 / Materials approved | 订单 {0} 的材料已通过审核 |
| worker | 材料被驳回 | 材料被驳回 / Materials rejected | 订单 {0} 的材料未通过审核，请查看驳回原因并重新提交 |
| worker | 出签完成 | 签证已出签 / Visa issued | 订单 {0} 已完成出签，请查看出签文件 |
| worker | 退款 | 订单已退款 / Order refunded | 订单 {0} 已退款 |
| worker | 超时未支付自动取消 | 订单已取消 / Order cancelled | 订单 {0} 因超时未支付已自动取消 |

## 三、系统类（type = `system`，预留）

暂未接入业务触发；后续运营公告会用 `type=system`、`target_role=null`（对该用户所有角色可见），前端按 `type=system` 单独展示即可。

## 说明：前端如需"细粒度事件"判断

目前 VO 只暴露了粗分类 `type` + 跳转 `bizType/bizId`，**同一 `type=order_status` 下"通过/驳回/出签/退款"等无法用字段区分**（只能靠 title 文案，不利于判断/配图标）。

如果前端需要按具体事件切换图标/样式/逻辑，建议给 VO 增加一个稳定的机器码字段 `event`（如 `order_approved` / `order_rejected` / `application_hired`），前端 `switch(event)` 即可，不用解析本地化文案。需要的话我来加这个字段。
