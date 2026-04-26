# 选择角色页面实施计划

## Summary

- 基于 Figma 节点 `59:193996`（未选中态）与 `59:193947`（选中态），在 `lib/features/auth` 下新增一个“选择角色”静态页面。
- 页面实现为本地可切换交互：点击角色卡片切换选中态，同时切换底部“确认选择”按钮的可用状态；不接接口、不接真实业务流。
- 在现有 GoRouter 中为该页面补充独立路由，保持其与 `login_phone_page.dart` 一样作为顶层认证页，而不是放进主 Tab Shell。

## Current State Analysis

- 当前路由定义位于 `lib/app/router/app_router.dart`，结构为：
  - 顶层 `GoRoute`：`/` 重定向、`/login/phone`
  - `StatefulShellRoute.indexedStack`：`/home`、`/visa`、`/jobs`、`/ai`、`/me`
- 路由常量集中在 `lib/app/router/route_paths.dart`，目前只有 `root`、5 个主 Tab 路径和 `loginPhone`。
- `lib/features/auth` 当前仅有：
  - `presentation/login_phone_page.dart`
  - `data/auth_providers.dart`
  - `data/auth_service.dart`
  - `data/login_models.dart`
- 现有认证页 `login_phone_page.dart` 已使用 `AppColors`、`AppSpacing`、`PrimaryButton`，说明新页面应优先沿用共享视觉常量与基础控件，避免另起一套样式。
- Figma 两个节点显示该页核心内容一致：
  - 标题：`选择角色`
  - 说明文案：`不同角色将看到不同的首页与功能。后续可在 “我的” 中切换不同角色`
  - 角色卡片：`工人/求职者`、`企业/雇主`、`签证服务商`
  - 角色说明分别为：`寻找海外工作、办理签证`、`发布职位、筛选候选人`、`提供签证服务、管理案件`
  - 底部按钮：`确认选择`
- 差异点主要在交互状态：
  - 未选中稿：按钮为禁用态，卡片未高亮
  - 选中稿：首张卡片高亮，按钮为启用态
- 用户已确认目标交互为“本地可切换”，因此实现需要覆盖两种视觉状态，但不需要接入任何接口。

## Proposed Changes

### 1. 新增页面目录与页面文件

- 新建目录：`lib/features/auth/select_role/presentation/`
- 新建页面：`lib/features/auth/select_role/presentation/select_role_page.dart`

实现方式：

- 使用 `StatefulWidget` 承载本地选中状态。
- 在文件内定义一个轻量角色数据结构（可用私有模型类或私有常量列表），包含：
  - 角色标题
  - 角色描述
  - 对应图标类型
- 页面主体结构按现有认证页风格实现：
  - `Scaffold` + `SafeArea`
  - 顶部返回区与语言胶囊（与登录页视觉保持一致）
  - 标题与说明文案
  - 三张可点击角色卡片
  - 底部主按钮

具体交互约束：

- 初始状态：无选中项，按钮禁用，对应 Figma 未选中态。
- 点击任意角色卡片：
  - 将该角色设为当前选中项
  - 选中卡片应用高亮背景/边框/图标底色
  - 其他卡片保持默认态
  - “确认选择”按钮切换为可点击
- “确认选择”按钮仅做静态占位，不触发真实业务：
  - 可使用空回调占位或轻量提示
  - 不在本次范围内接登录、保存角色、后续跳转逻辑

视觉实现原则：

- 复用 `lib/shared/ui/app_colors.dart`、`lib/shared/ui/app_spacing.dart`、`lib/shared/widgets/primary_button.dart`
- 若 Figma 需要的颜色在现有常量中缺失，再最小化补充共享色值，避免在页面内散落魔法值
- 角色图标优先使用 Flutter 内置 `IconData` 占位还原层级；本次不额外下载 Figma 图标资源，除非实现中发现内置图标无法满足基本辨识度

### 2. 扩展路由常量

- 更新文件：`lib/app/router/route_paths.dart`

改动内容：

- 新增常量：`selectRole`
- 路径建议定为：`/auth/select-role`

原因：

- 与已有 `/login/phone` 一样保持认证域命名
- 语义清晰，便于后续把该页纳入认证流程

### 3. 注册 GoRouter 路由

- 更新文件：`lib/app/router/app_router.dart`

改动内容：

- 引入 `select_role_page.dart`
- 在 `StatefulShellRoute.indexedStack` 之前追加一个顶层 `GoRoute`
- 新路由使用 `RoutePaths.selectRole`
- `builder` 返回 `const SelectRolePage()`

原因：

- 该页属于认证流程页面，不应进入底部 Tab 导航壳
- 与现有 `LoginPhonePage` 的组织方式一致，便于后续串联登录流程

### 4. 暂不改动登录页入口

- `lib/features/auth/presentation/login_phone_page.dart` 本次不改

原因：

- 用户当前需求仅要求新增页面并补充路由配置
- 是否在登录页增加跳转入口属于流程设计问题，当前未明确提出

## Assumptions & Decisions

- 决策：页面目录使用 `select_role/presentation`，满足“在 auth 下新建一个文件夹”的要求，同时保持与现有 `presentation` 分层兼容。
- 决策：页面作为顶层独立认证路由，而非主 Shell 分支。
- 决策：页面实现“本地交互静态页”，允许卡片点击切换，不接接口、不接状态管理、不持久化结果。
- 决策：默认进入时无角色选中，按钮禁用；这是对未选中 Figma 稿的直接还原。
- 决策：选中态以单选为准，一次仅允许一个角色高亮。
- 假设：当前项目可接受在小型页面中以内聚方式定义私有角色数据，不需要额外拆分 controller/provider。
- 假设：若缺少完全一致的 Figma 图标，可用语义接近的 Material `Icon` 做静态替代。
- 范围外：
  - 角色选择结果落库
  - 确认后跳转到哪个页面
  - 与登录流程的自动串联
  - 接口联调、埋点、权限控制

## Verification Steps

- 确认新增页面文件路径与导入路径正确，无循环引用。
- 检查 `route_paths.dart` 与 `app_router.dart` 的新符号命名一致。
- 用 IDE 诊断检查新增/修改文件是否有语法或分析错误。
- 如进入执行阶段，可手动验证以下 UI 状态：
  - 进入 `/auth/select-role` 时按钮默认禁用
  - 点击任一角色后，该卡片进入选中态，按钮启用
  - 切换到另一角色时，前一个角色恢复未选中态
- 如需要进一步验证，可在执行阶段补充一次针对变更文件的 `flutter analyze` 或 IDE diagnostics。
