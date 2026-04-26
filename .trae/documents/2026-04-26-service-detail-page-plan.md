# 服务详情页面规划

## Summary
- 基于 Figma 节点 `59:191881` 新增一个独立的“服务详情-套餐”Flutter 页面，按当前项目的静态还原风格实现首版，不接接口、不改现有列表点击逻辑。
- 页面放在 `lib/features/service_detail/` 下，遵循用户要求的 `英文_英文` 目录命名格式。<mccoremem id="03g0m8j4b8x55jpu758ljuf01" />
- 新增独立路由并注册到 `lib/app/router/app_router.dart`，仅完成路由可访问能力，不从 `VisaPage` 或 `HomePage` 增加跳转入口。
- 资源处理以“Flutter 原生绘制优先，必要资源切图”为原则：导出顶部 Hero 主视觉图到 `assets/images/`，并在 `pubspec.yaml` 中显式声明 `assets/images/` 目录；基础按钮、卡片、标签、边框、底栏全部由 Flutter 绘制。

## Current State Analysis
- 当前项目为 Flutter 应用，使用 `flutter_riverpod + go_router`；底部 5 个 Tab 通过 `StatefulShellRoute.indexedStack` 承载，普通页面路由在 Shell 外层通过 `GoRoute` 注册。
- 现有页面（如 `lib/features/home/presentation/home_page.dart`、`lib/features/visa/presentation/visa_page.dart`）均为静态 Figma 还原页，未接入真实数据流，适合本次沿用“静态展示 + 后续再接接口”的实现方式。
- 当前 `lib/app/router/route_paths.dart` 仅包含首页、签证、招聘、AI、我的、登录/选角色等路径，尚无服务详情相关路由。
- `pubspec.yaml` 当前已声明 `.figma/image/` 资源目录，但尚未显式声明 `assets/images/`，而仓库中已存在 `assets/images/image_service_detail_top_background.png`，说明服务详情顶部视觉资源已有本地文件，可纳入正式资源目录声明。
- 从 Figma 节点 `59:191881` 可确认本页是移动端“服务详情-套餐”页面，核心结构为：
  - 顶部大图 Hero 区，带返回/收藏/分享三个悬浮操作按钮。
  - 白色圆角内容承接层。
  - 套餐标题、价格、国家/签证类型标签、简介。
  - 一级切换栏：`套餐`、`评价 234`、`商家`，当前高亮 `套餐`。
  - 3 个套餐卡片：基础、标准、尊享，带选中/未选中状态。
  - 所需材料区：标题、`查看样例` 操作、3 条材料项、`必填/选填` 标签。
  - 底部固定行动区：`咨询` 与 `立即申请`。
- 用户已确认本次只需“新增页面 + 注册路由”，不要求从现有页面跳转；同时要求新页面内容集中放入 `lib/features` 下新建的英文下划线目录中。<mccoremem id="03g0m8j4b8x55jpu758ljuf01" />

## Proposed Changes

### 1. 新增 Feature 目录与页面文件
- 新增目录：`lib/features/service_detail/`
- 新增主页面：`lib/features/service_detail/presentation/service_detail_page.dart`
- 页面实现方式：
  - 使用 `Scaffold` 作为页面根容器，背景色沿用 `AppColors.background`。
  - 使用 `Stack + CustomScrollView + bottomNavigationBar` 实现“顶部大图 + 可滚动内容 + 底部固定按钮”的结构。
  - 顶部区域采用 Hero 图片 + 半透明圆形按钮覆盖层；按钮视觉按 Figma 还原，交互先做占位：
    - 返回：`Navigator/GoRouter.pop`
    - 收藏、分享：无业务逻辑时先留空回调
  - 滚动内容区拆分为若干私有 section widget，避免单个 `build()` 过长：
    - `_HeroSection`
    - `_SummarySection`
    - `_TopTabBar`
    - `_PackageOptionCard`
    - `_MaterialsSection`
    - `_BottomActionBar`
  - 页面数据先以内联静态常量组织，不新增 provider / model / API 层，保持与现有 Figma 还原页一致。

### 2. 页面内容按 Figma 固定还原
- 页面标题与说明区：
  - 标题：`德国厨师专属工作签证`
  - 价格：`¥15,000` + `起`
  - 标签：`德国`、`工作签`
  - 简介：采用 Figma 中当前展示文案做静态还原
- 顶部一级切换栏：
  - 渲染 `套餐`、`评价 234`、`商家`
  - 视觉上仅高亮 `套餐`
  - 本次不接真实分页或联动切换，另外两个标签作为静态非激活项
- 套餐区：
  - 渲染 3 张套餐卡片：基础套餐、标准套餐、尊享套餐
  - 通过本地 `selectedIndex` 做卡片选中态切换
  - 选中态使用蓝色边框和浅蓝底色，未选中态使用浅灰边框和白底
  - 每张卡片包含标题、价格、卖点标签、单选图示
- 材料区：
  - 标题：`所需材料`
  - 右侧操作：`查看样例`
  - 渲染 3 条材料数据，并保留必填/选填视觉区分
  - 材料卡片中的“文件图标”“下拉箭头”优先用 Flutter Icon 或现有 SVG 资源实现；若实测与 Figma 偏差明显，再补导出对应 SVG
- 底部行动栏：
  - 左侧咨询按钮：图标 + `咨询`
  - 右侧主按钮：`立即申请`
  - 使用 `SafeArea` 包裹，避免遮挡底部系统区域

### 3. 资源处理
- 更新 `pubspec.yaml`
  - 在 `flutter/assets` 中新增 `assets/images/`
  - 保留现有 `.figma/image/` 声明，避免影响已有页面资源
- 资源使用策略：
  - 直接使用/补充顶部 Hero 图资源到 `assets/images/`
  - 当前仓库已存在 `assets/images/image_service_detail_top_background.png`，执行阶段先核对其是否与 Figma 节点匹配；若一致则直接引用，若不一致再通过 Figma 图片下载工具重新导出覆盖或新增同目录资源
  - 返回、收藏、分享、咨询、文件、选中态等图标优先用 Flutter 原生 Icon 或现有 `AppSvgIcon` 方案实现；只有在严格对齐 Figma 时无法满足的图标才作为补充 SVG 导出到 `assets/images/`
- 资源命名规则：
  - 统一使用语义化英文下划线命名，例如 `service_detail_top_background.png`
  - 避免继续直接引用 Figma 自动生成的随机文件名到业务页面

### 4. 路由接入
- 更新 `lib/app/router/route_paths.dart`
  - 新增服务详情路径常量，建议命名为 `serviceDetail`
  - 建议路径值：`/service-detail`
- 更新 `lib/app/router/app_router.dart`
  - 新增对 `service_detail_page.dart` 的 import
  - 在 Shell 外层新增一个普通 `GoRoute`
  - `builder` 返回 `const ServiceDetailPage()`
- 本次不改 `VisaPage`、`HomePage` 的卡片点击行为，确保改动范围与用户确认一致

### 5. 样式与复用策略
- 优先复用：
  - `AppColors`
  - `AppSpacing`
  - `PrimaryButton`（若尺寸/圆角与 Figma 接近，可直接复用；若差异较大，则在详情页底栏局部实现按钮样式）
  - `AppSvgIcon`
- 仅在服务详情页面内局部实现的样式：
  - Hero 覆盖按钮
  - 套餐选中卡
  - 材料项状态标签
  - 底部双按钮栏
- 不在本次范围内扩展全局设计系统，除非发现某个样式已经被多个页面重复需要且抽取成本很低

## Assumptions & Decisions
- 以 Figma 为准，不强行补 PRD 中“详情 / 商家 / 评价联动内容、套餐对比表、时间轴”等未在当前设计稿中出现的复杂模块。
- 首版页面为静态 UI 还原，不接接口、不做状态持久化、不增加新的 Riverpod provider。
- 只注册独立路由，不从现有列表页接入跳转，这是用户已明确确认的范围。
- 新 feature 目录命名采用 `service_detail`，符合用户的英文下划线目录命名要求。<mccoremem id="03g0m8j4b8x55jpu758ljuf01" />
- 资源以 `assets/images/` 作为正式落地目录；`.figma/image/` 继续保留给现有页面，不在本次重构旧页面资源引用。
- 图标资源的策略是“能原生绘制就不切图，不能精确还原则补 SVG/PNG 资源”，这样既满足严格对齐设计，也避免资源过度碎片化。
- 路由路径采用 `/service-detail`，因为它与当前项目的短路径命名风格一致，也便于后续扩展 query/path 参数。

## Verification Steps
- 代码结构验证
  - 确认新增目录 `lib/features/service_detail/` 和主页面文件存在。
  - 确认 `route_paths.dart` 与 `app_router.dart` 均已接入服务详情路由。
  - 确认 `pubspec.yaml` 已声明 `assets/images/`。
- 视觉验证
  - 页面顶部大图、白色承接层、标题价格区、套餐切换卡、材料列表、底部按钮与 Figma 主要层级一致。
  - 套餐选中态与未选中态视觉区分明显。
  - 底部按钮固定，滚动到页面底部时材料列表不被遮挡。
- 交互验证
  - 访问 `/service-detail` 能正常打开页面。
  - 返回按钮可以退出页面。
  - 套餐卡片点击后选中态正常切换。
- 诊断验证
  - 对新改动文件运行诊断检查，确保没有新增 Dart 分析错误。
  - 如需要，本地运行 Flutter 格式化与静态检查，确认资源路径和 import 正确。
