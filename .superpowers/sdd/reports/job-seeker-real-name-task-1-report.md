# 求职者实名认证 Task 1 报告

## 完成状态

- 已完成 Task 1 约束范围内的实现：
  - “我的”页新增独立的求职者实名认证提示区
  - 顶部资料卡整卡点击仍保留跳转到 `myInfo`
  - 新增求职者实名认证占位页
  - 注册新路由 `RoutePaths.jobSeekerRealNameVerification`
  - 补充中英文文案
  - 增加聚焦 Task 1 的组件级测试

## 关键实现

### 1. 我的页入口

- 文件：`lib/features/me/presentation/role_pages/job_seeker_me_page.dart`
- 保留原顶部资料卡 `onTap -> RoutePaths.myInfo`
- 新增 `JobSeekerRealNameEntry` 组件作为独立点击区域
- 实名状态文案仅依赖 `isVerified`
  - `true` -> `我的.已完成实名认证`
  - `false` -> `我的.点击去实名认证`

### 2. 路由注册

- 文件：`lib/app/router/route_paths.dart`
  - 新增 `RoutePaths.jobSeekerRealNameVerification = '/me/real-name-verification'`
- 文件：`lib/app/router/app_router.dart`
  - 注册 `JobSeekerRealNameVerificationPage`

### 3. 占位页

- 文件：`lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
- 当前仅展示“实名认证”标题与页面主体标题
- 不包含实名表单、上传、提交逻辑，符合 Task 1 范围

### 4. 国际化文案

- 文件：
  - `assets/translations/zh.json`
  - `assets/translations/en.json`
- 新增：
  - `我的.已完成实名认证`
  - `我的.点击去实名认证`
  - `我的.实名认证`

## 测试与验证

### 自动化测试

- 文件：`test/features/me/job_seeker_real_name_page_test.dart`
- 覆盖点：
  - 未实名入口展示未实名文案并响应点击
  - 已实名入口展示完成实名文案
  - 实名认证占位页展示标题

### 本地验证命令

```bash
flutter test test/features/me/job_seeker_real_name_page_test.dart
flutter analyze lib/app/router/route_paths.dart lib/app/router/app_router.dart lib/features/me/presentation/job_seeker_real_name_verification_page.dart lib/features/me/presentation/role_pages/job_seeker_me_page.dart test/features/me/job_seeker_real_name_page_test.dart
```

### 验证结果

- `flutter test` 通过
- `flutter analyze` 通过
- VS Code diagnostics 无新增问题

## 约束符合性检查

- 仅使用 `isVerified` 作为实名状态来源
- 未改企业/服务商资质认证流
- 未新增接口
- 未新增依赖
- 沿用现有 `go_router` 路由方案
- 已为新增函数补充函数级中文注释
- 已在关键分支处补充简洁中文注释

## 风险与顾虑

- 当前测试为了避开 `easy_localization` 在 Widget 测试中的空白页问题，采用组件级断言 key 文案分支，而不是最终翻译后的展示文案；运行时多语言仍由真实翻译文件提供。
- Task 1 仅完成占位页跳转，不包含后续实名表单、上传与提交流程。

## 2026-07-05 审查修复追加

- 修复目标：
  - 将 `test/features/me/job_seeker_real_name_page_test.dart` 从孤立组件测试升级为高价值页面级测试
  - 在真实 `EasyLocalization` 宿主中断言最终中文文案，而不是国际化 key
  - 从“我的”页真实入口点击进入实名认证占位页，并断言落页标题

### 本次改动

- 文件：`test/features/me/job_seeker_real_name_page_test.dart`
  - 使用真实 `EasyLocalization` 宿主，并通过测试专用 `AssetLoader` 直接读取仓库里的翻译 JSON
  - 使用 `ProviderContainer` 覆盖 `authSessionProvider` 与 `homeDashboardStatsProvider`
  - 覆盖点调整为：
    - 未实名用户在“我的”页看到最终文案“您还未实名，点击去实名认证”，点击后进入实名认证占位页标题
    - 已实名用户在“我的”页看到最终文案“已完成实名认证”，点击后同样可进入实名认证占位页标题
- 文件：`lib/features/me/presentation/role_pages/job_seeker_me_page.dart`
  - 为实名认证入口增加测试可覆写的可选跳转回调
  - 默认行为仍保持走现有 `go_router` 路由，不影响生产逻辑

### 根因记录

- `EasyLocalization` 在 Widget 测试中若直接依赖默认资源加载路径，容易停留在空白宿主态，导致测试只能退回 key 级断言。
- `homeDashboardStatsProvider` 在测试环境会触发真实网络请求并带来重试定时器，需在页面级测试中显式覆盖为静态数据。

### 修复后验证

- 已通过：
  - `flutter test test/features/me/job_seeker_real_name_page_test.dart`
  - `flutter analyze lib/features/me/presentation/role_pages/job_seeker_me_page.dart test/features/me/job_seeker_real_name_page_test.dart lib/features/me/presentation/job_seeker_real_name_verification_page.dart`

### 更新后的顾虑

- Task 1 仍只覆盖实名认证入口与占位页落点，不包含实名表单、上传与提交流程。
