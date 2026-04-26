# 订单详情页面实现计划

## Summary

- 目标：基于 Figma 节点 `59:191374` 新增一个独立 Flutter 页面“订单详情”，按设计稿严格还原页面布局与视觉，并接入 `go_router` 路由。
- 页面形态：独立详情页，不显示底部 TabBar；顶部使用 `AppBar`，其中返回按钮对应 `leading`，标题“订单详情”对应 `title`，右侧“联系商家”对应 `actions`，并显式开启标题居中。
- 交互范围：本次只做静态页面与占位点击，不接真实上传、客服会话、文件选择或后端接口。
- 资源策略：优先使用 Flutter 原生绘制卡片、步骤条、按钮和上传占位，仅将 Figma 中确实需要的图标/位图下载到 `assets/images/`，并在 `pubspec.yaml` 中声明。

## Current State Analysis

- 路由入口位于 `lib/app/router/app_router.dart`，当前使用 `GoRouter` + `StatefulShellRoute.indexedStack` 管理 5 个底部 Tab 页面，同时在 Shell 之外已有登录等独立路由。
- 路径常量位于 `lib/app/router/route_paths.dart`，目前没有订单相关路径常量。
- 当前 `lib/features/` 下只有 `ai`、`auth`、`home`、`jobs`、`me`、`shell`、`visa` 模块，尚无订单模块。
- 现有页面风格使用 `AppColors`、`AppSpacing` 与局部私有组件组合完成静态还原，说明新页面应沿用相同模式，避免引入新的架构分支。
- `pubspec.yaml` 当前只声明了 `.figma/image/` 资源目录；用户要求的新页面切图需落到 `assets/images/`，因此需要新增该资源目录声明，同时保留现有 `.figma/image/` 配置。
- Figma 页面解析结果表明该页面由 5 个核心区块组成：导航栏、6 步流程条、订单信息卡、材料上传卡、底部吸底提交区；其中大部分都适合用 Flutter 原生还原。

## Proposed Changes

### 1. 新增订单详情页面文件

- 新建 `lib/features/order/presentation/order_detail_page.dart`。
- 在该文件中实现页面主体 `OrderDetailPage`，并使用私有子组件拆分以下区域：
  - `_OrderProgressStepper`：横向 6 步流程条，展示“提交订单、上传材料、支付费用、材料审核、使馆递交、签证出签”，其中按 Figma 还原完成态、当前态、未完成态。
  - `_OrderInfoCard`：白底圆角卡片，展示“德国厨师专属工作签证”以及服务商、套餐类型、套餐价格、订单号 4 组键值信息。
  - `_OrderInfoRow`：订单信息单行键值布局组件。
  - `_MaterialUploadCard`：材料上传卡片容器。
  - `_MaterialUploadItem`：单个材料项，展示标题、必填标记、右侧“查看样例”和上传占位区。
  - `_UploadPlaceholder`：统一上传占位区域，显示加号图标与“上传文件”文案。
  - `_BottomSubmitBar`：底部吸底操作栏，包含禁用视觉态的“提交材料”按钮。
- 页面整体布局采用 `Scaffold`：
  - `appBar` 使用标准 `AppBar` 配置 `leading`、`title`、`actions`、`centerTitle: true`。
  - `body` 使用滚动容器承载步骤条与两张卡片。
  - `bottomNavigationBar` 或 `bottomSheet` 风格的安全区容器承载底部按钮，以贴近 Figma 的吸底效果。
- 占位交互策略：
  - 返回按钮执行 `context.pop()`；若无可返回栈，再回退到一个安全处理方案。
  - “联系商家”“查看样例”“上传文件”“提交材料”均先绑定占位点击反馈，不接业务逻辑。

### 2. 新增订单路由常量

- 修改 `lib/app/router/route_paths.dart`。
- 新增订单详情路径常量，计划使用独立语义明确的路径，如 `orderDetail = '/order/detail'`。
- 保持命名风格与现有 `loginPhone`、`selectRole` 一致，供路由表和后续跳转统一引用。

### 3. 在主路由中接入独立详情页

- 修改 `lib/app/router/app_router.dart`。
- 引入新的 `OrderDetailPage` import。
- 在 `StatefulShellRoute` 之外新增一个独立 `GoRoute`，使该页面不落入底部 Tab 壳中，符合 Figma 的独立详情页形态。
- 路由结构保持简单直接，不额外引入嵌套路由或参数化逻辑，因为本次页面为静态还原页。

### 4. 下载并接入必要图片资源

- 先从 Figma 节点 `59:191374` 中提取需要导出的资源，优先限制在以下范围：
  - 返回图标（若项目已有可接受的原生图标，可不下载）
  - 必填标识图标
  - 上传占位区加号图标
  - 步骤完成态图标
- 下载目标目录为 `assets/images/`，文件命名使用业务可读名称，例如：
  - `assets/images/order_detail_required.svg`
  - `assets/images/order_detail_upload_add.svg`
  - `assets/images/order_detail_step_done.svg`
- 若 Figma 返回的图标更适合位图，则使用 PNG；若为纯矢量图标，则优先 SVG，以匹配现有 `flutter_svg` 依赖。
- 实现阶段同时确认是否需要把 Figma 自动导出的原始文件从临时目录移动/复制到项目内的 `assets/images/`。

### 5. 更新资源声明

- 修改 `pubspec.yaml`。
- 在 `flutter.assets` 下新增 `assets/images/`。
- 保留现有 `.figma/image/` 配置，避免影响已落地页面。

## Assumptions & Decisions

- 决策：页面为独立详情页，不显示底部 TabBar。
- 决策：本次实现严格按 Figma 视觉还原，但只做静态 UI 和占位交互，不接真实上传、样例查看、联系商家或提交流程。
- 决策：标题文字按用户明确要求使用“订单详情”；你消息里的“订单性情”视为笔误，不作为 UI 文案落地。
- 决策：顶部栏采用 `AppBar` 语义映射实现，而非整块导航栏切图。
- 决策：步骤条、卡片、按钮、上传框优先用 Flutter 原生绘制，仅导出少量不可替代图标资源。
- 假设：页面暂不需要从现有页面增加跳转入口；本次只保证路由已注册，可直接通过 `GoRouter` 路径访问。
- 假设：订单详情数据全部使用 Figma 中的静态文案，不引入模型层、Provider 或远程数据源。

## Verification Steps

- 确认 `OrderDetailPage` 能通过新增路径正常打开，且不会显示底部 TabBar。
- 校验顶部栏：返回按钮位于 `leading`，“订单详情”位于居中的 `title`，“联系商家”位于 `actions`。
- 校验页面区块顺序与 Figma 一致：步骤条、订单信息卡、材料上传卡、底部提交栏。
- 校验步骤条状态是否正确呈现：已完成、当前步骤、未完成步骤的颜色与图标区别清晰。
- 校验材料卡中 3 个材料项文案、必填状态、查看样例入口与上传占位区域均完整呈现。
- 校验 `pubspec.yaml` 资源声明包含 `assets/images/` 且不破坏已有 `.figma/image/`。
- 运行 Flutter 分析检查最近修改文件，确保无明显语法或导入错误。
