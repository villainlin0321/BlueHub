# Service Provider Patrol Full Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为服务商模块补齐 Patrol 自动化验收，覆盖核心 5 页及关键依赖页的稳定可测试交互点，并在指定 iOS 模拟器上串行跑通。

**Architecture:** 先稳定现有 Patrol 基线与串行 iOS 执行，再按“锚点补齐 -> 页面用例补齐 -> 复杂表单页补齐 -> 全量重跑收口”的顺序推进。测试实现以 `AppTestKeys + PatrolRouteMatcher + PatrolReporter` 为核心，按页面拆分 Patrol 文件，并把结果粒度细化到交互点级别。

**Tech Stack:** Flutter, Dart, Patrol, flutter_test, Riverpod, GoRouter, EasyLocalization, iOS Simulator, Xcode

## Global Constraints

- 仅覆盖服务商角色页面与其直接依赖页，不扩展到其他角色。
- 所有新增函数必须补函数级中文注释，关键代码处补中文注释。
- 稳定锚点统一收口到 `lib/shared/ui/test_keys.dart`，命名使用 `pageXxx`、`actionXxx`、`sectionXxx`、`fieldXxx`。
- iOS 继续使用单设备串行执行，`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` 中 `RunnerUITests` 必须保持 `parallelizable="NO"`。
- Patrol 运行目标固定为 `-d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6`，避免 clone simulator。
- 对系统选择器、权限弹窗、弱数据依赖交互允许记为 `BLOCKED`，但必须输出明确原因。
- 结果记录粒度必须细化到交互点级别，不再只停留于页面级 PASS / FAIL。
- 所有新改动完成后都要运行对应测试，并对最近修改文件执行诊断检查。

---

## File Map

- `lib/shared/ui/test_keys.dart`
  - 统一新增服务商页面、按钮、筛选、表单、列表相关测试 key。
- `patrol_test/fixtures/service_provider_expectations.dart`
  - 补服务商页面与依赖页的稳定 route matcher。
- `patrol_test/fixtures/service_provider_test_cases.dart`
  - 将服务商测试点从页面可达性扩展为交互点定义。
- `patrol_test/helpers/service_provider_case_result_helper.dart`
  - 补充 `BLOCKED`、失败原因、交互点描述的统一构建逻辑。
- `patrol_test/service_provider/service_provider_home_test.dart`
  - 服务商首页深层交互用例。
- `patrol_test/service_provider/service_provider_me_test.dart`
  - 服务商“我的”深层交互用例。
- `patrol_test/service_provider/service_provider_jobs_test.dart`
  - 新增套餐管理页 Patrol 用例。
- `patrol_test/service_provider/service_provider_visa_test.dart`
  - 新增服务商签证页 Patrol 用例。
- `patrol_test/service_provider/service_provider_edit_visa_package_test.dart`
  - 新增编辑套餐页 Patrol 用例。
- `lib/features/home/presentation/role_pages/service_provider_home_page.dart`
  - 补首页稳定 key。
- `lib/features/me/presentation/role_pages/service_provider_me_page.dart`
  - 补“我的”页稳定 key。
- `lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart`
  - 补套餐管理页稳定 key。
- `lib/features/visa/presentation/role_pages/service_provider_visa_page.dart`
  - 补签证页稳定 key。
- `lib/features/visa/presentation/edit_visa_package_page.dart`
  - 补编辑套餐页主交互锚点。
- `lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart`
  - 补编辑套餐页表单区域锚点。
- `lib/features/visa/presentation/widgets/edit_visa_package_form_widgets.dart`
  - 补编辑套餐页细粒度交互锚点。
- `docs/superpowers/reports/2026-07-05-service-provider-patrol-full-coverage-report.md`
  - 记录最终 Patrol 覆盖结果与遗留阻塞项。

### Task 1: 稳定服务商 Patrol 基线与结果粒度

**Files:**
- Modify: `patrol_test/fixtures/service_provider_test_cases.dart`
- Modify: `patrol_test/helpers/service_provider_case_result_helper.dart`
- Modify: `patrol_test/service_provider/service_provider_home_test.dart`
- Modify: `patrol_test/service_provider/service_provider_me_test.dart`
- Test: `patrol_test/service_provider/service_provider_home_test.dart`
- Test: `patrol_test/service_provider/service_provider_me_test.dart`

**Interfaces:**
- Consumes: `PatrolReporter.record(PatrolCaseResult result)`, `waitForPageReady(PatrolIntegrationTester $, {required String page})`
- Produces: 更细粒度的 `feature` 命名规则，例如 `home.quick_action.publish_package`、`me.menu.settings`

- [ ] **Step 1: 写失败用例，先让现有首页/我的测试表达“交互点级结果”**

```dart
patrolTest('服务商首页 - 首页交互结果应细化到交互点级别', ($) async {
  final reporter = PatrolReporter.memory();

  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );
  await waitForPageReady($, page: 'serviceProviderHome');

  final result = await _runHomeCase(
    $,
    const PatrolCaseDefinition(
      module: 'service_provider',
      page: 'home',
      feature: 'home.quick_action.publish_package',
      description: '发布套餐快捷入口',
      precondition: '已进入服务商首页',
      expected: '进入编辑套餐页',
    ),
  );

  await reporter.record(result);

  expect(result.feature, 'home.quick_action.publish_package');
});
```

- [ ] **Step 2: 运行失败用例，确认当前实现还停留在旧 feature 命名**

Run: `flutter test patrol_test/service_provider/service_provider_home_test.dart`

Expected: FAIL，提示 `feature` 仍是旧值如 `publish_package`，或测试定义与实现不一致

- [ ] **Step 3: 用最小实现收敛首页/我的结果粒度，并统一失败 / BLOCKED 辅助逻辑**

```dart
const List<PatrolCaseDefinition> serviceProviderHomeCases =
    <PatrolCaseDefinition>[
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'home',
        feature: 'home.quick_action.publish_package',
        description: '发布套餐快捷入口',
        precondition: '已进入服务商首页',
        expected: '进入编辑套餐页',
      ),
    ];
```

```dart
/// 构建服务商 Patrol 的统一失败结果，避免每个页面重复拼接失败原因。
PatrolCaseResult buildServiceProviderFailureResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required Object error,
  String reason = 'interaction_failed',
}) {
  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: '交互未达到预期：$error',
    status: PatrolCaseStatus.fail,
    reason: reason,
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}
```

- [ ] **Step 4: 跑首页 / 我的 Patrol，确认基线仍可执行**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_home_test.dart`

Expected: 至少能进入 Patrol 执行阶段，且结果记录使用新交互点命名

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_me_test.dart`

Expected: 至少能进入 Patrol 执行阶段，且“我的”页结果命名一致

- [ ] **Step 5: 提交**

```bash
git add patrol_test/fixtures/service_provider_test_cases.dart patrol_test/helpers/service_provider_case_result_helper.dart patrol_test/service_provider/service_provider_home_test.dart patrol_test/service_provider/service_provider_me_test.dart
git commit -m "test(patrol): refine service provider case granularity"
```

### Task 2: 补齐服务商首页与“我的”页锚点

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/home/presentation/role_pages/service_provider_home_page.dart`
- Modify: `lib/features/me/presentation/role_pages/service_provider_me_page.dart`
- Modify: `patrol_test/fixtures/service_provider_expectations.dart`
- Test: `patrol_test/service_provider/service_provider_home_test.dart`
- Test: `patrol_test/service_provider/service_provider_me_test.dart`

**Interfaces:**
- Consumes: `AppTestKeys`, `PatrolRouteMatcher`
- Produces: 首页 / “我的”主交互稳定 key，如 `actionServiceProviderHomeAvatar`、`actionServiceProviderHomeAiBanner`、`actionServiceProviderMeProfileCard`

- [ ] **Step 1: 先写失败断言，要求首页和“我的”关键控件能通过 key 定位**

```dart
patrolTest('服务商我的 - 资料卡应具备稳定 key', ($) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );

  await $('我的').tap();
  await waitForPageReady($, page: 'serviceProviderMe');

  expect($(find.byKey(AppTestKeys.actionServiceProviderMeProfileCard)), findsOneWidget);
});
```

- [ ] **Step 2: 运行失败测试，确认关键控件尚未绑定稳定 key**

Run: `flutter test patrol_test/service_provider/service_provider_me_test.dart`

Expected: FAIL，提示 `AppTestKeys.actionServiceProviderMeProfileCard` 未定义或找不到控件

- [ ] **Step 3: 最小实现补 key，并把首页 / 我的关键可交互控件接入**

```dart
/// 服务商首页头像入口的稳定定位 Key。
static const Key actionServiceProviderHomeAvatar = Key(
  'action-home-service-provider-avatar',
);

/// 服务商首页 AI 助手入口的稳定定位 Key。
static const Key actionServiceProviderHomeAiBanner = Key(
  'action-home-service-provider-ai-banner',
);

/// 服务商“我的”页资料卡的稳定定位 Key。
static const Key actionServiceProviderMeProfileCard = Key(
  'action-me-service-provider-profile-card',
);
```

```dart
GestureDetector(
  key: AppTestKeys.actionServiceProviderHomeAvatar,
  onTap: () => context.push(RoutePaths.serviceProviderMyInfo),
  behavior: HitTestBehavior.opaque,
  child: AppUserAvatar(...),
)
```

```dart
InkWell(
  key: AppTestKeys.actionServiceProviderMeProfileCard,
  onTap: () => context.push(RoutePaths.serviceProviderMyInfo),
  borderRadius: BorderRadius.circular(16),
  child: Row(...),
)
```

- [ ] **Step 4: 跑对应测试，确认新锚点可用且不影响现有页面路由**

Run: `flutter test patrol_test/service_provider/service_provider_home_test.dart patrol_test/service_provider/service_provider_me_test.dart`

Expected: PASS 或进入 Patrol 运行前的静态断言阶段成功

- [ ] **Step 5: 提交**

```bash
git add lib/shared/ui/test_keys.dart lib/features/home/presentation/role_pages/service_provider_home_page.dart lib/features/me/presentation/role_pages/service_provider_me_page.dart patrol_test/fixtures/service_provider_expectations.dart patrol_test/service_provider/service_provider_home_test.dart patrol_test/service_provider/service_provider_me_test.dart
git commit -m "test(patrol): add service provider home and me anchors"
```

### Task 3: 落地套餐管理页 Patrol 全扫

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart`
- Modify: `patrol_test/fixtures/service_provider_expectations.dart`
- Create: `patrol_test/service_provider/service_provider_jobs_test.dart`
- Test: `patrol_test/service_provider/service_provider_jobs_test.dart`

**Interfaces:**
- Consumes: `RoutePaths.editVisaPackage`, `PatrolReporter`, `expectRouteReady()`
- Produces: 套餐管理页锚点与用例，如 `pageServiceProviderJobs`、`actionServiceProviderJobsPublish`

- [ ] **Step 1: 写失败 Patrol 用例，先表达套餐管理页关键交互**

```dart
patrolTest('服务商套餐管理 - 发布按钮应进入编辑套餐页', ($) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );

  await $('套餐管理').tap();
  await expectRouteReady(
    $,
    routePath: RoutePaths.jobs,
    fallbackFinder: find.byKey(AppTestKeys.pageServiceProviderJobs),
  );

  await $(find.byKey(AppTestKeys.actionServiceProviderJobsPublish)).tap();
  await expectRouteReady(
    $,
    routePath: RoutePaths.editVisaPackage,
    fallbackFinder: find.byKey(AppTestKeys.pageEditVisaPackage),
  );
});
```

- [ ] **Step 2: 运行失败用例，确认套餐管理页尚无页面根 key 或发布按钮 key**

Run: `flutter test patrol_test/service_provider/service_provider_jobs_test.dart`

Expected: FAIL，提示 `pageServiceProviderJobs` 或 `actionServiceProviderJobsPublish` 未定义

- [ ] **Step 3: 最小实现补套餐管理页页面锚点、Tab 锚点和列表主操作锚点**

```dart
/// 服务商套餐管理页根节点的稳定定位 Key。
static const Key pageServiceProviderJobs = Key('page-jobs-service-provider');

/// 服务商套餐管理页发布按钮的稳定定位 Key。
static const Key actionServiceProviderJobsPublish = Key(
  'action-jobs-service-provider-publish',
);
```

```dart
return Column(
  key: AppTestKeys.pageServiceProviderJobs,
  children: <Widget>[
    _PageHeader(
      topPadding: topPadding,
      onPublishTap: () => context.push(RoutePaths.editVisaPackage),
    ),
  ],
);
```

```dart
InkWell(
  key: AppTestKeys.actionServiceProviderJobsPublish,
  onTap: onPublishTap,
  borderRadius: BorderRadius.circular(4),
  child: Padding(...),
)
```

- [ ] **Step 4: 跑套餐管理 Patrol，用例至少覆盖页面进入、发布、Tab 切换、编辑、删除确认、上下架**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_jobs_test.dart`

Expected: 能进入套餐管理页并输出交互点级报告；缺少测试数据时部分项为 `BLOCKED`

- [ ] **Step 5: 提交**

```bash
git add lib/shared/ui/test_keys.dart lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart patrol_test/fixtures/service_provider_expectations.dart patrol_test/service_provider/service_provider_jobs_test.dart
git commit -m "test(patrol): cover service provider jobs interactions"
```

### Task 4: 落地服务商签证页 Patrol 全扫

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/visa/presentation/role_pages/service_provider_visa_page.dart`
- Modify: `patrol_test/fixtures/service_provider_expectations.dart`
- Create: `patrol_test/service_provider/service_provider_visa_test.dart`
- Test: `patrol_test/service_provider/service_provider_visa_test.dart`

**Interfaces:**
- Consumes: `RoutePaths.orderDetail`, `RoutePaths.chat`
- Produces: 签证页锚点与用例，如 `pageServiceProviderVisa`、`actionServiceProviderVisaCountryFilter`

- [ ] **Step 1: 写失败 Patrol 用例，先约束签证页筛选与订单卡操作**

```dart
patrolTest('服务商签证页 - 国家与状态筛选应可打开', ($) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );

  await $('签证').tap();
  await expectRouteReady(
    $,
    routePath: RoutePaths.visa,
    fallbackFinder: find.byKey(AppTestKeys.pageServiceProviderVisa),
  );

  await $(find.byKey(AppTestKeys.actionServiceProviderVisaCountryFilter)).tap();
  await $('选择国家').waitUntilVisible();
});
```

- [ ] **Step 2: 运行失败用例，确认签证页筛选入口还没有稳定 key**

Run: `flutter test patrol_test/service_provider/service_provider_visa_test.dart`

Expected: FAIL，提示缺少 `pageServiceProviderVisa` 或筛选按钮 key

- [ ] **Step 3: 最小实现补签证页根节点、筛选入口和订单卡主操作锚点**

```dart
/// 服务商签证页根节点的稳定定位 Key。
static const Key pageServiceProviderVisa = Key('page-visa-service-provider');

/// 服务商签证页国家筛选按钮的稳定定位 Key。
static const Key actionServiceProviderVisaCountryFilter = Key(
  'action-visa-service-provider-country-filter',
);

/// 服务商签证页状态筛选按钮的稳定定位 Key。
static const Key actionServiceProviderVisaStatusFilter = Key(
  'action-visa-service-provider-status-filter',
);
```

```dart
return ColoredBox(
  key: AppTestKeys.pageServiceProviderVisa,
  color: const Color(0xFFF5F7FA),
  child: Column(...),
);
```

```dart
_FilterButton(
  buttonKey: AppTestKeys.actionServiceProviderVisaCountryFilter,
  label: countryLabel,
  onTap: onCountryTap,
)
```

- [ ] **Step 4: 跑签证页 Patrol，用例覆盖筛选、订单详情、联系客户、处理订单、错误态 / 空态 / 重试**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_visa_test.dart`

Expected: 签证页关键筛选与订单操作可执行；无数据或外部依赖场景输出 `BLOCKED`

- [ ] **Step 5: 提交**

```bash
git add lib/shared/ui/test_keys.dart lib/features/visa/presentation/role_pages/service_provider_visa_page.dart patrol_test/fixtures/service_provider_expectations.dart patrol_test/service_provider/service_provider_visa_test.dart
git commit -m "test(patrol): cover service provider visa interactions"
```

### Task 5: 落地编辑套餐页 Patrol 全扫

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/visa/presentation/edit_visa_package_page.dart`
- Modify: `lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart`
- Modify: `lib/features/visa/presentation/widgets/edit_visa_package_form_widgets.dart`
- Create: `patrol_test/service_provider/service_provider_edit_visa_package_test.dart`
- Test: `patrol_test/service_provider/service_provider_edit_visa_package_test.dart`

**Interfaces:**
- Consumes: `AppTestKeys.pageEditVisaPackage`, `AppTestKeys.actionEditVisaPackageBack`
- Produces: 编辑套餐页主表单锚点，如 `fieldEditVisaPackageName`、`actionEditVisaPackageSaveDraft`、`actionEditVisaPackageCountry`

- [ ] **Step 1: 写失败 Patrol 用例，先约束编辑套餐页关键表单交互**

```dart
patrolTest('编辑套餐 - 套餐名称输入与保存草稿应可执行', ($) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );

  await $(find.byKey(AppTestKeys.actionServiceProviderJobsPublish)).tap();
  await waitForPageReady($, page: 'editVisaPackage');

  await $(find.byKey(AppTestKeys.fieldEditVisaPackageName)).enterText('Patrol 测试套餐');
  await $(find.byKey(AppTestKeys.actionEditVisaPackageSaveDraft)).tap();

  expect($(find.textContaining('保存')), findsWidgets);
});
```

- [ ] **Step 2: 运行失败用例，确认编辑套餐页表单锚点仍不完整**

Run: `flutter test patrol_test/service_provider/service_provider_edit_visa_package_test.dart`

Expected: FAIL，提示缺少表单字段 key 或保存按钮 key

- [ ] **Step 3: 最小实现补编辑套餐页表单主锚点，并优先覆盖强闭环交互**

```dart
/// 编辑套餐页套餐名称输入框的稳定定位 Key。
static const Key fieldEditVisaPackageName = Key(
  'field-edit-visa-package-name',
);

/// 编辑套餐页保存草稿按钮的稳定定位 Key。
static const Key actionEditVisaPackageSaveDraft = Key(
  'action-edit-visa-package-save-draft',
);

/// 编辑套餐页国家选择入口的稳定定位 Key。
static const Key actionEditVisaPackageCountry = Key(
  'action-edit-visa-package-country',
);
```

```dart
TextField(
  key: AppTestKeys.fieldEditVisaPackageName,
  controller: controller,
  decoration: decoration,
)
```

```dart
TextButton(
  key: AppTestKeys.actionEditVisaPackageSaveDraft,
  onPressed: actionsEnabled ? onSaveDraftTap : null,
  child: Text(...),
)
```

- [ ] **Step 4: 跑编辑套餐 Patrol，用例覆盖输入、选择、增删、保存与上传入口弱闭环**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_edit_visa_package_test.dart`

Expected: 强闭环交互可执行；上传入口至少能拉起页面内选择面板或输出明确 `BLOCKED`

- [ ] **Step 5: 提交**

```bash
git add lib/shared/ui/test_keys.dart lib/features/visa/presentation/edit_visa_package_page.dart lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart lib/features/visa/presentation/widgets/edit_visa_package_form_widgets.dart patrol_test/service_provider/service_provider_edit_visa_package_test.dart
git commit -m "test(patrol): cover edit visa package interactions"
```

### Task 6: 补齐首页 / 我的深层交互并完成全量收口

**Files:**
- Modify: `patrol_test/service_provider/service_provider_home_test.dart`
- Modify: `patrol_test/service_provider/service_provider_me_test.dart`
- Create: `docs/superpowers/reports/2026-07-05-service-provider-patrol-full-coverage-report.md`
- Test: `patrol_test/service_provider/*.dart`

**Interfaces:**
- Consumes: 前 5 个任务新增的所有 `AppTestKeys`、页面 route matcher、结果帮助函数
- Produces: 服务商 Patrol 全覆盖报告

- [ ] **Step 1: 写失败 Patrol 用例，要求首页 / 我的不再只测可达性，而要覆盖深层交互**

```dart
patrolTest('服务商首页 - 待处理订单区应覆盖全部、联系客户、处理订单', ($) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );
  await waitForPageReady($, page: 'serviceProviderHome');

  await $(find.byKey(AppTestKeys.actionServiceProviderHomePendingOrdersAll)).tap();
  await expectRouteReady(
    $,
    routePath: RoutePaths.orderManagement,
    fallbackFinder: find.text('订单管理'),
  );
});
```

- [ ] **Step 2: 运行失败用例，确认首页 / 我的仍缺待处理订单区和消息中心等细粒度锚点**

Run: `flutter test patrol_test/service_provider/service_provider_home_test.dart patrol_test/service_provider/service_provider_me_test.dart`

Expected: FAIL，提示新的首页 / 我的深层交互锚点不存在

- [ ] **Step 3: 最小实现补齐首页 / 我的深层交互锚点，并把所有服务商 Patrol 测试串成完整报告**

```dart
/// 服务商首页待处理订单“全部”入口的稳定定位 Key。
static const Key actionServiceProviderHomePendingOrdersAll = Key(
  'action-home-service-provider-pending-orders-all',
);
```

```dart
InkWell(
  key: AppTestKeys.actionServiceProviderHomePendingOrdersAll,
  onTap: () => context.push(RoutePaths.orderManagement),
  borderRadius: BorderRadius.circular(4),
  child: const Padding(...),
)
```

```markdown
# 服务商 Patrol 全覆盖测试报告

- 设备：`iPhone 16 Pro / iOS 18.6`
- 运行方式：`patrol test -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF`
- 覆盖页面：首页、我的、套餐管理、编辑套餐、签证页
- 遗留 BLOCKED：
  - 上传依赖系统选择器自动确认
  - 测试数据缺少可操作套餐 / 订单
```

- [ ] **Step 4: 全量执行服务商 Patrol，并补诊断与报告**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_home_test.dart`

Expected: 首页深层交互结果输出

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_me_test.dart`

Expected: “我的”深层交互结果输出

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_jobs_test.dart`

Expected: 套餐管理页结果输出

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_edit_visa_package_test.dart`

Expected: 编辑套餐页结果输出

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 74DB60A8-9921-40FD-AADD-4E9E518CDBAF --ios 18.6 --target patrol_test/service_provider/service_provider_visa_test.dart`

Expected: 签证页结果输出

Run: `dart analyze lib/shared/ui/test_keys.dart patrol_test/service_provider`

Expected: 无新增静态错误

- [ ] **Step 5: 提交**

```bash
git add patrol_test/service_provider/service_provider_home_test.dart patrol_test/service_provider/service_provider_me_test.dart patrol_test/service_provider/service_provider_jobs_test.dart patrol_test/service_provider/service_provider_edit_visa_package_test.dart patrol_test/service_provider/service_provider_visa_test.dart docs/superpowers/reports/2026-07-05-service-provider-patrol-full-coverage-report.md
git commit -m "test(patrol): finish service provider full coverage"
```

