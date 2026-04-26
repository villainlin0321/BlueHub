# 订单按钮枚举化与评价页实施计划

## Summary

- 将 `lib/features/me/presentation/my_orders_page.dart` 中订单卡片按钮的样式判断与点击逻辑从“按文案字符串判断”改为“按枚举类型判断”。
- 为订单动作新增“去评价”枚举，并在对应按钮点击时跳转到新的“评价”页面，而不是继续使用空回调。
- 基于 Figma 节点 `1:6404` 新增一个独立的“评价”页面，使用 `AppBar` 实现顶部返回与标题，并接入 `lib/app/router/app_router.dart` 的顶层路由配置。

## Current State Analysis

- 当前订单列表页面位于 `lib/features/me/presentation/my_orders_page.dart`。
- 页面内现状：
  - 订单筛选使用 `_OrderFilter` 枚举，已经不是字符串驱动。
  - 订单动作仍使用 `_OrderAction`，字段只有：
    - `label`
    - `filled`
  - `_OrderActionButton` 中存在字符串判断：
    - `final isPayAction = action.label == '去支付';`
  - `_OrderActionButton` 点击事件目前固定为：
    - `onPressed: () {}`
- 这意味着当前实现存在两个问题：
  - 样式和行为都依赖展示文案，后续改字会影响逻辑。
  - “去评价”按钮已经出现在静态数据里，但没有真实跳转能力。
- 当前路由定义位于 `lib/app/router/app_router.dart`，仓库实际已有以下顶层页面：
  - `login_phone_page.dart`
  - `select_role_page.dart`
  - `order_detail_page.dart`
  - `service_detail_page.dart`
  - `my_orders_page.dart`
- 当前路由常量位于 `lib/app/router/route_paths.dart`，已存在：
  - `serviceDetail`
  - `myOrders`
  - `orderDetail`
  - 但尚无“评价”页路径。
- 当前仓库没有现成的“评价”页实现：
  - 未检索到 review/comment 页面文件
  - 未检索到“去评论”或“评价页面”对应路由
- 用户已确认订单按钮展示文案统一为 `去评价`，不使用“去评论”。

## Figma Grounding

- 新页面 Figma 链接文件 key：`I7ojJFX130Lsz8o9AEfuM7`
- 主节点：`1:6404`
- 页面名称：`我的订单-评价`
- 页面总体结构：
  - 页面背景色：`#F5F7FA`
  - 顶部导航栏高度：`88`
  - 中间订单信息卡片：`351 x 124`
  - 下方评价大卡片：`351 x 480`
  - 底部固定按钮栏：`375 x 102`
- 导航栏节点 `1:6405`：
  - 标题：`评价`
  - 左侧为返回图标
  - 白色背景
- 订单信息卡片节点 `1:6420`：
  - 标题：`法签通个人服务`
  - 价格：`¥9,000.00`
  - 元信息：
    - 服务商：`中欧出海签证服务有限公司`
    - 套餐类型：`基础套餐`
    - 订单号：`CLSKJ98793120238`
- 评价区节点：
  - 标题：`综合评价`
  - 星级行节点 `1:6437`：
    - 左文案：`服务评价`
    - 右文案：`很差`
    - 中间 5 颗星，其中结构表现为：1 颗点亮、1 颗半亮、3 颗未点亮
  - 评论输入框节点 `1:6433`：
    - 浅灰背景 `#F5F7FA`
    - 占位文案：`写评论...`
    - 字数：`0/500`
  - 上传图片区节点 `1:6447`：
    - 尺寸：`106 x 106`
    - 文案：`上传图片`
    - 含照片图标
- 底部按钮栏节点 `1:6411`：
  - 白底带顶部细分隔
  - 主按钮尺寸：`343 x 44`
  - 按钮文案：`发布`
  - 按钮蓝色：`#096DD9`
  - 当前 Figma 透明度为 0.3，表现为禁用态

## Proposed Changes

### 1. 订单动作模型改为枚举驱动

- 更新文件：`lib/features/me/presentation/my_orders_page.dart`

改动内容：

- 为订单按钮引入私有枚举，例如：
  - `contactMerchant`
  - `uploadMaterials`
  - `goPay`
  - `viewProgress`
  - `supplementMaterials`
  - `goReview`
  - `viewDetail`
- `_OrderAction` 从“只有 label/filled”升级为“动作类型 + 展示属性”：
  - `type`
  - `label`
  - `filled`
- 静态订单数据里将最后一张卡片的主按钮明确配置为：
  - 文案：`去评价`
  - 类型：`goReview`
- 支付按钮明确配置为：
  - 文案：`去支付`
  - 类型：`goPay`

原因：

- 避免再通过 `action.label == '去支付'` 这类字符串做逻辑判断。
- 后续即使改文案，也不会影响按钮颜色和点击行为。

### 2. 将按钮颜色判断改为基于动作枚举

- 更新文件：`lib/features/me/presentation/my_orders_page.dart`

改动内容：

- 删除 `final isPayAction = action.label == '去支付';`
- 改为依据 `action.type` 判断：
  - `goPay` 使用橙色 `#FE5815`
  - 其他 filled 主按钮保持蓝色 `#096DD9`
  - outline 次按钮保持白底灰边

原因：

- 当前支付按钮颜色已经是特例，但实现方式不稳定。
- 用枚举分支是这次需求的直接目标，也更符合后续继续扩展动作类型。

### 3. 为订单动作按钮补充真实点击分发

- 更新文件：`lib/features/me/presentation/my_orders_page.dart`

改动内容：

- `_OrderActionButton` 需要拿到 `BuildContext` 并根据 `action.type` 执行分发。
- 跳转策略：
  - `goReview`：跳转到新评价页路由
  - 其他动作：继续使用占位行为，例如 `SnackBar` 或保持空实现，但要在计划执行时统一一种方式

实现建议：

- 优先把点击分发放到页面层或卡片层，例如：
  - `_OrderCard` 接受 `onActionTap`
  - 页面根据 `action.type` 统一处理导航
- 不推荐把复杂跳转逻辑深埋在 `_OrderActionButton` 纯样式组件内部

原因：

- 样式组件只负责渲染，页面负责路由分发，职责更清晰。
- 后续如果“联系商家”“查看详情”也要跳转，不需要重新拆按钮组件。

### 4. 新增评价页面

- 新建文件：`lib/features/order/presentation/order_review_page.dart`

页面结构：

- `Scaffold`
- `AppBar`
  - `leading`：返回按钮
  - `title`：`评价`
  - `centerTitle: true`
- `body`
  - `ListView` 或 `SingleChildScrollView`
  - 第一块订单信息卡片
  - 第二块评价内容卡片
- `bottomNavigationBar`
  - 白底固定底栏
  - 顶部分隔线
  - 主按钮 `发布`

页面内容按 Figma 还原：

- 顶部卡片：
  - 标题 + 价格一行
  - 3 行元信息
- 评价卡片：
  - `综合评价`
  - `服务评价` 文案
  - 5 星评分控件
  - 右侧评价程度文案，初始为 `很差`
  - 评论输入区
  - `0/500` 字数统计
  - 上传图片宫格起始项

交互策略：

- 页面至少实现本地可交互版本：
  - 星级可点击切换
  - 右侧评价描述随评分变化
  - 文本输入更新字数统计
  - 上传图片区先做静态占位点击态
  - 底部 `发布` 按钮先为禁用态样式，是否可用根据输入/评分策略由执行阶段按 Figma 决定

原因：

- 用户要求“严格按照设计图实现新的评价页面”，仅做静态截图式页面不够，至少要具备基础输入交互。
- 页面放在 `features/order/presentation` 下，与现有 `order_detail_page.dart` 保持同域组织。

### 5. 扩展评价页路由常量

- 更新文件：`lib/app/router/route_paths.dart`

改动内容：

- 新增常量，例如：`orderReview = '/order/review'`

原因：

- 当前订单相关独立页已有 `orderDetail = '/order/detail'`
- 评价页继续沿用订单域命名最清晰，也便于从订单列表和订单详情复用跳转

### 6. 注册评价页路由

- 更新文件：`lib/app/router/app_router.dart`

改动内容：

- 引入 `order_review_page.dart`
- 在现有顶层 `GoRoute` 区域新增评价页路由
- 使用 `RoutePaths.orderReview`
- `builder` 返回 `const OrderReviewPage()`

当前文件实际情况需保留：

- 现有 `app_router.dart` 已含：
  - `orderDetail`
  - `serviceDetail`
  - `myOrders`
- 当前 `initialLocation` 暂被改为 `RoutePaths.myOrders`

计划决策：

- 本次只新增评价页路由，不主动调整 `initialLocation`
- 避免把当前用户调试入口改回去，除非执行阶段用户另有要求

## Implementation Approaches

### 方案 A：最小改动直连

- 在 `_OrderActionButton` 内直接根据 `action.type` 做跳转
- 优点：改动最少
- 缺点：样式组件承担行为逻辑，后续维护差

### 方案 B：页面层统一分发

- `_OrderActionButton` 只接收 `onPressed`
- `_OrderCard` 或 `MyOrdersPage` 负责根据枚举分发导航
- 优点：职责清晰，后续增加动作最稳
- 缺点：会多传一层回调

### 方案 C：动作配置对象集中处理

- 将按钮文案、样式、点击行为映射集中在动作枚举扩展中
- 优点：扩展性最好
- 缺点：对于当前规模略偏重

推荐方案：

- 采用方案 B
- 这是当前需求下最平衡的做法：既去掉字符串判断，也不会把路由逻辑塞进纯按钮组件

## Assumptions & Decisions

- 决策：订单卡片按钮文案统一使用 `去评价`。
- 决策：订单动作逻辑和样式均改为基于枚举类型，不再依赖展示文案。
- 决策：评价页文件放在 `lib/features/order/presentation/order_review_page.dart`。
- 决策：评价页路由归入订单域，路径采用 `/order/review`。
- 决策：评价页顶部使用 `AppBar` 实现返回和标题，不自定义整套导航栏。
- 决策：订单页点击 `goReview` 时跳转评价页；其他动作本次不扩展真实业务，只保留占位或原有表现。
- 决策：不主动改动当前 `app_router.dart` 里的 `initialLocation: RoutePaths.myOrders`，以免打断现有联调路径。
- 假设：评价页所需星星与上传图片区图标可以优先用 Flutter 原生图标还原；若执行阶段发现无法满足像素要求，再导出 Figma 图标资源。
- 假设：本次不接真实图片上传、发布接口、评论提交接口。

## Verification Steps

- 检查 `my_orders_page.dart` 中不再出现基于按钮文案的逻辑判断。
- 检查 `_OrderAction` 是否已携带枚举类型，静态订单数据是否为每个按钮标注了正确动作。
- 检查 `goReview` 动作点击后是否导航到新的评价页路由。
- 检查 `route_paths.dart` 与 `app_router.dart` 中的评价页路由命名一致。
- 检查 `order_review_page.dart` 是否实现：
  - `AppBar.leading`
  - `AppBar.title`
  - `centerTitle: true`
  - 订单信息卡片
  - 星级评价区
  - 评论输入框
  - 字数统计
  - 上传图片区
  - 底部发布按钮
- 执行阶段完成后，用 IDE diagnostics 或 `flutter analyze` 验证新增/修改文件无分析错误。
