# 资质认证导航与提交流程补充设计

## 背景

当前资质认证流程已经改为：

- 选图阶段只做本地暂存
- 最终提交时统一上传图片并登记 `docs`
- `docs` 成功后再提交基础资料

但页面导航与返回交互仍不满足最新要求：

- 下一步仍使用 `push`
- 上一步与左上角返回仍依赖 `pop`
- 第三步仅校验资质图片，未对服务信息必填字段做完整校验
- 提交成功后的结果页左上角返回未明确回到“我的”页

## 目标

在不重构三页结构的前提下，统一资质认证流程中的页面导航与返回行为：

1. 资质认证三步页之间的“下一步 / 上一步”不再使用 `push/pop`
2. 左上角返回按钮统一为“退出整个资质认证流程，回到我的页”
3. 第三步提交前补齐服务信息必填字段校验
4. 提交成功后的结果页左上角返回点击后直接回到“我的页”

## 方案选择

采用 `方案 A`：

- 保留现有三路由结构
- 将步骤切换统一改为 `context.go(...)`
- 将流程退出统一改为 `context.go(RoutePaths.me)`

该方案相比“单路由容器 + 内部步骤切换”改动更小，同时可以满足“不要用 `push/pop`”的要求。

## 页面导航规则

### 第一步

- “下一步”：
  - 从 `RoutePaths.qualificationCertification`
  - 直接 `go(RoutePaths.qualificationCertificationStepTwo)`
- 左上角返回：
  - 不回到上一页
  - 统一退出整个流程，`go(RoutePaths.me)`

### 第二步

- “上一步”：
  - `go(RoutePaths.qualificationCertification)`
- “下一步”：
  - `go(RoutePaths.qualificationCertificationStepThree)`
- 左上角返回：
  - 统一退出整个流程，`go(RoutePaths.me)`

### 第三步

- “上一步”：
  - `go(RoutePaths.qualificationCertificationStepTwo)`
- 左上角返回：
  - 统一退出整个流程，`go(RoutePaths.me)`

## 返回确认规则

当前三步页面都已接入“未保存内容退出确认弹窗”。

本次改造后：

- 左上角返回点击时，仍先判断是否存在未保存改动
- 若无改动，则直接 `go(RoutePaths.me)`
- 若有改动，则先弹确认框
- 用户确认后，再 `go(RoutePaths.me)`

“上一步”按钮不作为退出流程动作处理：

- 第二步“上一步”只回到第一步
- 第三步“上一步”只回到第二步

因此，“上一步”不弹“退出整个流程”的确认框，而保持页面内步骤切换语义。

## 第三步表单校验规则

在现有资质图片兜底校验之外，第三步提交前新增以下必填校验：

1. 国家/地区必填
   - `_selectedCountries` 不能为空
2. 从业年限必填
   - 输入不能为空
   - 必须能解析为正整数

任一校验不通过：

- 阻止提交
- 使用现有 Toast 机制提示用户

## 提交成功页返回行为

资质认证提交成功后会进入结果页。

本次要求：

- 结果页左上角返回点击后，不回退路由栈
- 而是直接回到 `RoutePaths.me`

实现策略：

- 优先在 `AppResultPageArgs` 中增加“返回目标”或等价参数
- 仅让资质认证成功页传入 `RoutePaths.me`
- 不影响支付成功、通用结果页等其他调用方的现有行为

## 非目标

- 不重构为单页 Step 容器
- 不改变资质认证三步的 UI 布局
- 不新增自动化测试要求
- 不处理当前测试文件中的联调与环境问题

## 代码改动范围

- `lib/features/auth/presentation/qualification_certification_page.dart`
- `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
- `lib/features/auth/presentation/qualification_certification_step_three_page.dart`
- `lib/features/service_detail/presentation/app_result_page.dart`
- 视参数结构而定，可能涉及：
  - `lib/app/router/route_paths.dart`
  - `lib/app/router/app_router.dart`

## 验收标准

- 第一步点击“下一步”使用 `go` 进入第二步
- 第二步点击“上一步/下一步”使用 `go` 切换步骤
- 第三步点击“上一步”使用 `go` 回到第二步
- 三步页左上角返回统一退出到“我的”页
- 第三步提交前补齐国家/地区与从业年限必填校验
- 提交成功结果页左上角返回点击后直接回到“我的”页
- 生产代码无新增静态诊断错误
