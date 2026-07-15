# Job Seeker Real Name Production Router Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让求职者实名认证入口测试直接绑定生产 `routerProvider`，确保生产 `app_router.dart` 中的实名页注册被真实验证。

**Architecture:** 保持运行时代码不变，只调整 `test/features/me/job_seeker_real_name_page_test.dart` 的测试宿主与断言来源。测试通过 `ProviderContainer.read(routerProvider)` 取得生产 `GoRouter`，从真实“我的”页入口点击后校验当前地址与落页标题，并把修复记录追加到最终验收报告。

**Tech Stack:** Flutter widget test、Riverpod、GoRouter、EasyLocalization

## Global Constraints

- 仅使用 `isVerified`。
- 不改企业/服务商认证流。
- 不新增接口。
- 不新增依赖。
- 沿用现有页面风格、路由方案、上传工具和 Toast 能力。
- 新增函数补函数级中文注释，关键代码补简洁中文注释。
- 优先补高价值测试。

---

### Task 1: 绑定生产路由并修正测试宿主

**Files:**
- Modify: `test/features/me/job_seeker_real_name_page_test.dart`

**Interfaces:**
- Consumes: `routerProvider`, `RoutePaths.me`, `RoutePaths.jobSeekerRealNameVerification`
- Produces: 基于生产 `GoRouter` 的实名认证入口跳转测试宿主与断言

- [ ] **Step 1: 写出失败测试约束**

```dart
testWidgets('未实名用户点击实名认证入口会通过生产 routerProvider 进入已注册实名页', (
  WidgetTester tester,
) async {
  final ProviderContainer container = _createAuthenticatedContainer(
    isVerified: false,
  );
  final GoRouter router = container.read(routerProvider);

  await tester.pumpWidget(
    _buildGoRouterRealNameTestHost(
      container: container,
      router: router,
    ),
  );

  await tester.tap(find.text('您还未实名，点击去实名认证'));
  await tester.pumpAndSettle();

  expect(router.state.uri.toString(), RoutePaths.jobSeekerRealNameVerification);
});
```

- [ ] **Step 2: 运行单测确认旧实现不满足“生产来源”要求**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart --plain-name "未实名用户点击实名认证入口会通过真实 GoRouter 进入已注册实名页"`
Expected: 旧测试仍依赖 `_buildRealNameTestRouter()`，需要修改为生产 `routerProvider`

- [ ] **Step 3: 写最小实现**

```dart
/// 构建使用生产 `routerProvider` 的测试宿主，覆盖入口点击到真实路由注册的完整链路。
Widget _buildGoRouterRealNameTestHost({
  required ProviderContainer container,
}) {
  final GoRouter router = container.read(routerProvider);
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: _GoRouterRealNameTestApp(router: router),
    ),
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add test/features/me/job_seeker_real_name_page_test.dart
git commit -m "test: bind real name route test to production router"
```

### Task 2: 追加最终验收报告并验证

**Files:**
- Modify: `.superpowers/sdd/reports/job-seeker-real-name-final-fix-report.md`

**Interfaces:**
- Consumes: Task 1 的测试实现与验证结果
- Produces: 本次修复报告追加记录与最终验收命令结果

- [ ] **Step 1: 写出报告追加内容**

```md
### 问题 5：实名认证入口测试未绑定生产路由注册

#### 根因

- 现有 GoRouter 测试使用测试文件内自建 `_buildRealNameTestRouter()`。
- 即使生产 `app_router.dart` 删除 `RoutePaths.jobSeekerRealNameVerification` 注册，测试仍可能继续通过。

#### 修复

- 改为在测试中直接通过 `ProviderContainer.read(routerProvider)` 读取生产 `GoRouter`。
- 保留从“我的”页真实入口点击的交互路径。
- 断言当前地址为 `RoutePaths.jobSeekerRealNameVerification`，并验证落到生产注册的实名认证页面。
```

- [ ] **Step 2: 运行定向验证**

Run: `flutter analyze test/features/me/job_seeker_real_name_page_test.dart lib/app/router/app_router.dart`
Expected: `No issues found!`

- [ ] **Step 3: 运行完整相关验证**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart && flutter analyze test/features/me/job_seeker_real_name_page_test.dart lib/app/router/app_router.dart`
Expected: tests PASS，analyze PASS

- [ ] **Step 4: 提交**

```bash
git add .superpowers/sdd/reports/job-seeker-real-name-final-fix-report.md \
  test/features/me/job_seeker_real_name_page_test.dart \
  docs/superpowers/plans/2026-07-05-job-seeker-real-name-production-router-test.md
git commit -m "test: verify real name route via production router"
```
