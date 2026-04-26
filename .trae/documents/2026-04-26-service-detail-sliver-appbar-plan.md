# 服务详情折叠工具栏改造计划

## Summary
- 将 `lib/features/service_detail/presentation/service_detail_page.dart` 当前“`Stack + CustomScrollView + 顶部悬浮按钮 + 普通 Tab 区块`”结构，重构为以 `SliverAppBar` 为核心的折叠式工具栏页面。
- 顶部 Hero 图、返回/收藏/分享按钮全部并入 `SliverAppBar.flexibleSpace`，实现滚动折叠时从图片头图过渡到白底工具栏。
- 顶部摘要区从当前“卡片式浮层”改为“平铺内容区”，仅保留左上和右上圆角，与用户要求一致。
- `套餐 / 评价 234 / 商家` 顶部栏改为吸顶效果，滚动后始终固定在顶部工具栏下方。
- 右上按钮实现到“基础可用”层级：返回可关闭页面；收藏本地切换高亮；分享触发基础反馈，占位后续系统分享或业务接入。

## Current State Analysis
- 当前文件 `lib/features/service_detail/presentation/service_detail_page.dart` 里，顶部头图通过 `SliverToBoxAdapter + Stack` 实现，摘要区 `_SummaryCard` 以 `Positioned(bottom: -48)` 的方式悬浮在头图下方。
- 当前三个导航按钮不在 sliver 体系中，而是用最外层 `Stack` 叠加 `SafeArea + Row` 放在整个滚动视图之上。
- 当前摘要区 `_SummaryCard` 是完整圆角卡片，并带阴影；这与用户本次要求的“平铺，不是卡片，只有左上和右上有圆角”不一致。
- 当前 `_TopTabBar` 是普通 `SliverToBoxAdapter`，不会吸顶；仓库内也没有现成的 `SliverPersistentHeader`、`SliverAppBar` 或 `NestedScrollView` 复用模式。
- 当前页已经具备静态数据结构与底部行动栏，不需要改动套餐区、材料区、底部 CTA 的业务范围，只需围绕顶部折叠区域和吸顶标签重构滚动布局。
- 用户明确补充：本次主要目标是实现“折叠式工具栏”的效果；收藏/分享做到基础可用即可，不要求完整业务接口。

## Proposed Changes

### 1. 重构页面根结构
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 将 `body` 从当前外层 `Stack` 改为单一 `CustomScrollView` 的 sliver 结构，避免“滚动内容”和“顶部按钮层”各自管理滚动状态。
- 计划结构：
  - `SliverAppBar`
  - `SliverToBoxAdapter`：平铺式摘要区
  - `SliverPersistentHeader`：吸顶顶部栏
  - `SliverToBoxAdapter`：套餐列表
  - `SliverToBoxAdapter`：材料区
  - `SliverToBoxAdapter`：底部留白

### 2. 用 `SliverAppBar` 承载头图与导航按钮
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 将当前 `L81-L96` 的 Hero 区和 `L129-L159` 的按钮区统一并入 `SliverAppBar`。
- `SliverAppBar` 配置方案：
  - `expandedHeight` 使用当前头图高度附近的值，保持现有视觉比例。
  - `pinned: true`，保证折叠后工具栏留在顶部。
  - `backgroundColor` 根据折叠状态动态在“透明/浅色”与“白色”之间切换，满足“滑动完后背景变白”。
  - `leading`、`actions` 不直接走默认样式，而是放在 `flexibleSpace` 中自绘，便于在展开态使用半透明圆形按钮、折叠态切换为浅色工具栏按钮。
- `flexibleSpace` 内实现：
  - 背景头图。
  - 顶部渐变遮罩。
  - 返回、收藏、分享三个按钮。
  - 折叠进度监听，用于控制按钮底色、图标颜色、标题透明度。

### 3. 折叠完成后的标题与工具栏状态
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 当头图收起、`SliverAppBar` 进入折叠态时：
  - 工具栏背景切换为白色。
  - 出现标题 `服务详情`。
  - 标题不居中，使用左对齐或靠近 leading 的标准内容布局，符合用户要求“title 不居中”。
- 展开态时：
  - 不显示折叠标题。
  - 保持图片头图主视觉与圆形按钮样式。

### 4. 摘要区改为“平铺 + 上圆角”
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 重写当前 `_SummaryCard`：
  - 去掉卡片阴影。
  - 去掉完整圆角卡片表现。
  - 将背景保持为 `AppColors.surface`。
  - 仅保留左上、右上圆角，底部为直角，形成“从头图接下来的内容面板”。
- 布局位置从“悬浮覆盖头图下沿”改为：
  - 紧接在 `SliverAppBar` 之后渲染。
  - 通过负边距/顶部圆角接缝或直接让 `SliverAppBar` 底部视觉自然衔接。
- 文案、价格、标签内容保持不变，避免本次改动扩散到数据层。

### 5. 顶部栏改为吸顶
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 将当前 `L98` 的 `_TopTabBar` 从 `SliverToBoxAdapter` 改为 `SliverPersistentHeader`。
- 新增一个轻量 delegate（可放在同文件内），专门用于：
  - 固定高度。
  - 白色背景。
  - 底部分割线或轻微阴影，以区分吸顶层与内容层。
  - 保持当前标签视觉样式。
- 交互层级：
  - 仍然只有 `套餐` 为激活态。
  - `评价 234`、`商家` 暂不切内容，只保持静态展示。
  - 本次重点是“吸顶效果”，不额外扩展成 `TabController` 或联动切页。

### 6. 导航按钮的基础可用实现
- 文件：`lib/features/service_detail/presentation/service_detail_page.dart`
- 返回按钮：
  - 保留 `context.pop()` 退出页面能力。
  - 若无法返回，保留安全兜底逻辑，避免空栈报错。
- 收藏按钮：
  - 增加本地 `bool isFavorited` 状态。
  - 点击后在两种视觉间切换，例如描边星标和高亮收藏态。
  - 不接接口、不做持久化。
- 分享按钮：
  - 本次不新增分享插件。
  - 点击后提供基础反馈入口，例如 `SnackBar` 或预留方法，满足“按钮已实现可响应”。
- 三个按钮在展开态与折叠态要同步切换：
  - 展开态：半透明深色圆底 + 白色图标。
  - 折叠态：浅色或透明按钮底 + 深色图标，适配白色工具栏背景。

## Assumptions & Decisions
- 本次改造聚焦折叠式工具栏和吸顶布局，不改套餐数据、材料数据和底部操作区范围。
- `SliverAppBar + SliverPersistentHeader` 是本次推荐方案，因为它直接覆盖用户提出的四个视觉与交互要求，且比 `NestedScrollView` 更轻量，适合当前单页静态详情场景。
- 顶部栏仅做吸顶，不做真实内容切换；否则需要新增 `TabController`、锚点滚动或分段内容，这超出本次请求。
- 摘要区继续保留白色面板语义，但改成“平铺内容块”而不是“悬浮卡片”，用上圆角实现与头图的视觉承接。
- 分享先做基础反馈，不增加三方依赖，避免为了按钮可用性扩大改动面。
- 折叠标题统一使用 `服务详情`，而不是当前套餐标题，遵循用户明确要求。

## Verification Steps
- 结构验证
  - 确认 `service_detail_page.dart` 中顶部 Hero 与按钮不再由外层 `Stack` 单独覆盖，而是进入 `SliverAppBar` 体系。
  - 确认 `_TopTabBar` 不再通过普通 `SliverToBoxAdapter` 渲染，而是通过吸顶 sliver 渲染。
- 视觉验证
  - 展开态显示头图、圆形半透明按钮。
  - 摘要区不再是悬浮卡片，而是白色平铺内容区，仅上方两个角为圆角。
  - 滚动折叠后，工具栏背景变白，标题 `服务详情` 出现且不居中。
  - 顶部栏在继续滚动时始终吸顶。
- 交互验证
  - 返回按钮可退出页面。
  - 收藏按钮可本地切换状态。
  - 分享按钮点击有基础反馈。
- 诊断验证
  - 对 `service_detail_page.dart` 运行 Dart 诊断，确保无新增分析错误。
  - 如有需要，运行格式化确保 sliver 重构后的代码可读性正常。
