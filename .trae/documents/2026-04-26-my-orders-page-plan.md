# 我的订单页面实施计划

## Summary

- 基于 Figma 节点 `59:190746`，新增一个独立的“我的订单”Flutter 页面，严格按设计稿还原顶部导航、状态筛选条和订单卡片列表。
- 页面作为顶层独立路由接入现有 `GoRouter`，新增路径常量并注册到 `lib/app/router/app_router.dart`，不放入底部 `StatefulShellRoute`。
- 执行阶段按需导出 Figma 资源到 `assets/images/`，并把该目录补充到 `pubspec.yaml`；能用原生 Flutter 精准还原的纯色背景、圆角卡片、分割线和文字不额外切图。

## Current State Analysis

- 当前路由定义位于 `lib/app/router/app_router.dart`：
  - 顶层 `GoRoute` 目前有 `/`、`/login/phone`、`/auth/select-role`
  - 主业务页挂在 `StatefulShellRoute.indexedStack` 下：`/home`、`/visa`、`/jobs`、`/ai`、`/me`
- 路由常量集中在 `lib/app/router/route_paths.dart`，目前还没有订单详情或“我的订单”相关路径。
- “我的”页在 `lib/features/me/presentation/me_page.dart`，其中已经出现“我的订单”“订单进度”等文案，说明“我的订单”作为 `me` 域下的子页面最贴合现有信息架构。
- 当前项目视觉常量位于：
  - `lib/shared/ui/app_colors.dart`
  - `lib/shared/ui/app_spacing.dart`
- 当前资源声明只包含 `.figma/image/`，见 `pubspec.yaml`；项目根目录还没有用户要求的 `assets/images/` 目录。
- Figma 浅层结构确认：
  - 页面尺寸为 `375 x 1324`
  - 顶部为独立导航栏，标题文本为“我的订单”
  - 标题下方是一个 5 项状态筛选条：`全部`、`待上传`、`待支付`、`办理中`、`已完成`
  - 主内容区共有 5 张订单卡片，卡片高度以 `202 / 258` 为主，使用白底圆角容器
  - 已探明的订单字段包括：时间、标题、价格、服务商、套餐类型、订单号
  - 已探明的按钮文案至少包含 `上传材料`
- Figma 当前返回的节点里，卡片底板和导航背景被标记为 `IMAGE-SVG`，但从结构和样式看大部分仍可直接用 Flutter 容器、圆角、阴影和文字还原；执行阶段仅在遇到无法等价绘制的图形或独立图标时导出资源。

## Proposed Changes

### 1. 新增我的订单页面文件

- 新建文件：`lib/features/me/presentation/my_orders_page.dart`

实现方式：

- 使用 `StatefulWidget` 承载顶部状态筛选的本地选中态。
- 页面整体采用 `Scaffold` + `AppBar` + `ListView`：
  - `leading` 使用返回按钮
  - `title` 使用 `Text('我的订单')`
  - `centerTitle: true`
- `AppBar` 下方实现一个固定高度的状态 Tab 条，默认选中 `全部`，视觉按 Figma 的蓝色文字 + 底部 2px 指示条还原。
- 主体实现为静态订单列表，使用本地常量数据驱动，至少覆盖设计稿中 5 张卡片的差异：
  - 不同状态标签
  - 不同时间格式
  - 不同标题与金额
  - 常规信息区块
  - 不同底部操作按钮组合

页面结构建议：

- `MyOrdersPage`
- 私有状态枚举或常量：订单筛选状态
- 私有数据模型：订单卡片静态展示字段
- 私有组件：
  - `_OrderStatusTabs`
  - `_OrderCard`
  - `_OrderMetaRow`
  - `_OrderActionButton`
  - 如有必要，补一个 `_OrderTag`

这样做的原因：

- 页面在 `me` 域下内聚，避免为单个子页面单独新增 feature 根目录。
- 用本地数据模型驱动卡片，有利于后续把静态 UI 平滑升级为接口返回数据。
- `AppBar` 能直接满足用户对 `leading`、`title`、标题居中的要求，不需要自定义整套导航栏。

### 2. 扩展路由常量

- 更新文件：`lib/app/router/route_paths.dart`

改动内容：

- 新增常量：`myOrders`
- 路径定为：`/me/orders`

原因：

- 语义上属于“我的”域下的子页面。
- 是独立路由，但不属于底部 Tab 本身；使用嵌套语义路径更清晰，也便于后续从 `MePage` 接入跳转。

### 3. 注册顶层订单路由

- 更新文件：`lib/app/router/app_router.dart`

改动内容：

- 引入 `my_orders_page.dart`
- 在 `StatefulShellRoute.indexedStack` 之前新增一个顶层 `GoRoute`
- `path` 使用 `RoutePaths.myOrders`
- `builder` 返回 `const MyOrdersPage()`

原因：

- 该页带返回按钮，明显是二级页面而不是底部导航主页。
- 顶层独立 `GoRoute` 与现有登录页、选择角色页的组织方式一致。

### 4. 处理 Figma 资源与 Flutter 资源声明

- 新建目录：`assets/images/`
- 更新文件：`pubspec.yaml`

改动内容：

- 在保留 `.figma/image/` 的前提下，新增 `assets/images/`
- 执行阶段使用 Figma MCP 导出“确实需要切图”的资源到 `assets/images/`
- 页面代码统一通过 `Image.asset` 或 `SvgPicture.asset` 引用这些资源

资源策略：

- 优先用 Flutter 原生绘制的元素：
  - 页面背景色
  - 白底圆角卡片
  - 底部分割线
  - 筛选条下划线
  - 纯文字标签和按钮圆角底色
- 仅对下列元素执行导出：
  - 无法用原生 `Icon` 高精度替代的独立图标
  - 复杂矢量装饰
  - 若 Figma 中某些按钮或标签依赖特殊矢量形态时的 SVG

原因：

- 满足用户“需要切图时自动下载到 `assets/images`”的要求。
- 避免把本可用代码还原的纯结构元素变成低复用图片资源。

### 5. 暂不修改我的页入口

- `lib/features/me/presentation/me_page.dart` 本次默认不改

原因：

- 用户当前明确要求是“生成页面内容 + 添加路由到 `app_router.dart`”。
- 是否在“我的”页的统计区或菜单区增加跳转入口，属于额外流程接入，不在本次最小交付范围内。

## Assumptions & Decisions

- 决策：页面文件放在 `lib/features/me/presentation/my_orders_page.dart`，而不是新建独立 `orders` feature。
- 决策：路由使用顶层 `GoRoute + /me/orders`，不加入 `StatefulShellRoute` 分支。
- 决策：顶部导航使用标准 `AppBar`，并明确设置 `centerTitle: true`、`leading` 为返回按钮、`title` 为“我的订单”。
- 决策：筛选条为本地交互，仅切换选中态与可见订单列表，不接接口。
- 决策：订单内容先使用 Figma 中提取的静态数据实现，保证页面像素级接近设计稿。
- 决策：资源导出采用“最小切图”原则，真正需要的资源下载到 `assets/images/`，同时保留现有 `.figma/image/` 配置以免影响已有页面。
- 假设：当前用户没有要求把“我的”页现有“我的订单”入口改成可点击导航。
- 假设：执行阶段若继续读取 Figma 子节点发现更多按钮文案或图形差异，会在不改变页面结构的前提下补齐到静态数据里。
- 范围外：
  - 订单接口联调
  - 分页、下拉刷新、空状态
  - 从 `MePage` 进入该页的入口接线
  - 真实上传材料、支付、联系客服等业务动作

## Verification Steps

- 检查 `lib/features/me/presentation/my_orders_page.dart` 是否只依赖现有共享样式和新增的必要资源。
- 检查 `route_paths.dart` 与 `app_router.dart` 中新增的 `myOrders` 常量与导入是否一致。
- 检查 `pubspec.yaml` 是否同时保留 `.figma/image/` 和新增 `assets/images/` 资源声明。
- 用 IDE diagnostics 或 `flutter analyze` 验证新增文件和修改文件无语法/分析错误。
- 执行阶段完成后手动验证：
  - 访问 `/me/orders` 能进入新页面
  - 顶部返回按钮位于 `AppBar.leading`
  - 标题“我的订单”居中显示
  - 5 个筛选项样式与 Figma 一致，默认选中“全部”
  - 订单卡片数量、间距、圆角、文案和按钮与设计稿一致
  - 若导出了图片/SVG，资源路径能正常加载，无红屏或资源缺失
