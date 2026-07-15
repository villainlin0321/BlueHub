# 编辑页键盘收起统一 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一本轮编辑页的点击空白与拖动滚动收键盘行为，并补齐 `Widget` + `Patrol` 两层自动验证。

**Architecture:** 复用现有 `TapBlankToDismissKeyboard` 作为页面级失焦入口，在本轮范围内的长表单滚动容器补 `ScrollViewKeyboardDismissBehavior.onDrag`。测试层采用“共享组件 + 代表页 Widget 测试”验证焦点释放，再通过 1 条 Patrol 真实链路验证 `MyResumeEditorPage -> SelfEvaluationPage` 的键盘收起体验。

**Tech Stack:** Flutter、easy_localization、go_router、flutter_test、patrol、flutter_riverpod

## Global Constraints

- 仅处理明确属于资料编辑、表单编辑、信息编辑的页面，不扩展到搜索页、聊天页和纯输入弹层。
- 本轮统一策略固定为“页面级 `TapBlankToDismissKeyboard` + 滚动级 `ScrollViewKeyboardDismissBehavior.onDrag`”。
- 不在本轮全量改造所有 `TextField/TextFormField` 的 `onTapOutside`。
- 不允许借机修改页面业务提交流程、字段校验逻辑、路由结构和非编辑页交互。
- 自动验证必须同时覆盖 `Widget` 与 `Patrol` 两层。
- 代码修改遵守用户规则：使用中文回复、添加函数级中文注释、在关键代码处添加中文注释。
- Patrol 默认使用项目约定的 iOS 模拟器 UDID：`683FA825-579A-4240-AE46-FABCC5EA7B93`。

---

### Task 1: 共享失焦能力与代表页 Widget 验证

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/me/presentation/self_evaluation_page.dart`
- Test: `test/shared/widgets/tap_blank_to_dismiss_keyboard_test.dart`
- Test: `test/features/me/self_evaluation_page_test.dart`

**Interfaces:**
- Consumes: `TapBlankToDismissKeyboard({Key? key, required Widget child})`
- Consumes: `SelfEvaluationPage({Key? key, String initialValue = ''})`
- Produces: `AppTestKeys.pageSelfEvaluation`
- Produces: `AppTestKeys.fieldSelfEvaluationInput`
- Produces: `AppTestKeys.actionSelfEvaluationSave`
- Produces: `AppTestKeys.actionSelfEvaluationDone`

- [ ] **Step 1: 先写共享组件与代表页的失败测试**

```dart
testWidgets('点击空白区域后输入框会失焦', (WidgetTester tester) async {
  final FocusNode focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TapBlankToDismissKeyboard(
          child: Column(
            children: <Widget>[
              TextField(key: const Key('field'), focusNode: focusNode),
              const Expanded(child: SizedBox(key: Key('blank'))),
            ],
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('field')));
  await tester.pump();
  expect(focusNode.hasFocus, isTrue);

  await tester.tap(find.byKey(const Key('blank')));
  await tester.pump();
  expect(focusNode.hasFocus, isFalse);
});

testWidgets('拖动自我评价页后输入框会失焦', (WidgetTester tester) async {
  await tester.pumpWidget(_buildSelfEvaluationTestHost());

  await tester.tap(find.byKey(AppTestKeys.fieldSelfEvaluationInput));
  await tester.pump();
  expect(FocusManager.instance.primaryFocus, isNotNull);

  await tester.drag(
    find.byType(Scrollable).first,
    const Offset(0, -120),
  );
  await tester.pump();

  expect(FocusManager.instance.primaryFocus, isNull);
});
```

- [ ] **Step 2: 运行测试，确认当前实现确实失败**

Run: `flutter test test/shared/widgets/tap_blank_to_dismiss_keyboard_test.dart test/features/me/self_evaluation_page_test.dart`

Expected: 至少 1 条失败，原因应指向 `SelfEvaluationPage` 仍使用自定义全屏 `GestureDetector`、缺少滚动容器或缺少稳定测试 Key。

- [ ] **Step 3: 最小实现共享 Key 与代表页结构改造**

```dart
// lib/shared/ui/test_keys.dart
static const Key pageSelfEvaluation = Key('page-self-evaluation');
static const Key fieldSelfEvaluationInput = Key('field-self-evaluation-input');
static const Key actionSelfEvaluationSave = Key('action-self-evaluation-save');
static const Key actionSelfEvaluationDone = Key('action-self-evaluation-done');

// lib/features/me/presentation/self_evaluation_page.dart
return Scaffold(
  key: AppTestKeys.pageSelfEvaluation,
  body: TapBlankToDismissKeyboard(
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight),
          child: IntrinsicHeight(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: AppTestKeys.fieldSelfEvaluationInput,
                    focusNode: _focusNode,
                    controller: _controller,
                    maxLength: _maxLength,
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
  bottomNavigationBar: FilledButton(
    key: AppTestKeys.actionSelfEvaluationSave,
    onPressed: _handleSave,
    child: Text('我的.保存'.tr()),
  ),
);
```

- [ ] **Step 4: 为新增或改动的方法补中文注释**

```dart
/// 构建自我评价页可滚动内容区，并统一处理点击空白与拖动失焦。
Widget _buildScrollableBody(BuildContext context, double bottomInset) {
  ...
}

/// 输入框聚焦时主动收起键盘，避免底部按钮点击后再次抢焦点。
void _dismissKeyboard() {
  ...
}
```

- [ ] **Step 5: 重新运行 Widget 测试并确认通过**

Run: `flutter test test/shared/widgets/tap_blank_to_dismiss_keyboard_test.dart test/features/me/self_evaluation_page_test.dart`

Expected: PASS，且 `SelfEvaluationPage` 的点击空白失焦、拖动失焦断言全部通过。

- [ ] **Step 6: 提交 Task 1**

```bash
git add \
  lib/shared/ui/test_keys.dart \
  lib/features/me/presentation/self_evaluation_page.dart \
  test/shared/widgets/tap_blank_to_dismiss_keyboard_test.dart \
  test/features/me/self_evaluation_page_test.dart
git commit -m "test(me): cover self evaluation keyboard dismiss"
```

### Task 2: 批量补齐编辑页页面级与滚动级键盘收起

**Files:**
- Modify: `lib/features/me/presentation/add_work_experience_page.dart`
- Modify: `lib/features/me/presentation/add_education_experience_page.dart`
- Modify: `lib/features/auth/presentation/qualification_certification_page.dart`
- Modify: `lib/features/auth/presentation/qualification_certification_step_three_page.dart`
- Modify: `lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart`
- Modify: `lib/features/me/presentation/my_resume_editor_page.dart`

**Interfaces:**
- Consumes: `TapBlankToDismissKeyboard({Key? key, required Widget child})`
- Produces: 页面级统一行为：点击空白区域执行 `FocusScope.of(context).unfocus()`
- Produces: 滚动级统一行为：`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`

- [ ] **Step 1: 先写本轮范围补齐清单，避免边改边漏**

```text
add_work_experience_page.dart                 已有 TapBlank，补 onDrag
add_education_experience_page.dart            已有 TapBlank，补 onDrag
qualification_certification_page.dart         已有 TapBlank，补 onDrag
qualification_certification_step_three_page.dart 已有 TapBlank，补 onDrag
edit_visa_package_page_view.dart              已有 onDrag，补 TapBlank
my_resume_editor_page.dart                    自定义 GestureDetector 收敛为 TapBlank，并补 onDrag
```

- [ ] **Step 2: 先改 4 个已包裹 `TapBlankToDismissKeyboard` 的 `SingleChildScrollView`**

```dart
child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 140),
  child: Column(
    children: <Widget>[...],
  ),
),
```

适用文件：

- `lib/features/me/presentation/add_work_experience_page.dart`
- `lib/features/me/presentation/add_education_experience_page.dart`
- `lib/features/auth/presentation/qualification_certification_page.dart`
- `lib/features/auth/presentation/qualification_certification_step_three_page.dart`

- [ ] **Step 3: 给签证编辑页补页面级 `TapBlankToDismissKeyboard`**

```dart
body: TapBlankToDismissKeyboard(
  child: LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ...,
            ),
          ),
        ],
      );
    },
  ),
),
```

- [ ] **Step 4: 收敛简历编辑页的自定义 `GestureDetector` 并补 `ListView.onDrag`**

```dart
body: TapBlankToDismissKeyboard(
  child: ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.zero,
    children: <Widget>[
      _buildCompletionSection(),
      _buildBasicInfoSection(),
      _buildJobIntentionSection(),
      _buildWorkExperienceSection(),
      _buildLanguageSection(),
      _buildCertificateSection(),
      _buildEducationSection(),
      _buildSelfEvaluationSection(),
    ],
  ),
),
```

- [ ] **Step 5: 跑受影响页面的最小回归测试与静态检查**

Run: `flutter test test/features/me/self_evaluation_page_test.dart`

Run: `flutter analyze lib/features/me/presentation/add_work_experience_page.dart lib/features/me/presentation/add_education_experience_page.dart lib/features/auth/presentation/qualification_certification_page.dart lib/features/auth/presentation/qualification_certification_step_three_page.dart lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart lib/features/me/presentation/my_resume_editor_page.dart`

Expected: `flutter test` PASS，`flutter analyze` 无新增错误。

- [ ] **Step 6: 提交 Task 2**

```bash
git add \
  lib/features/me/presentation/add_work_experience_page.dart \
  lib/features/me/presentation/add_education_experience_page.dart \
  lib/features/auth/presentation/qualification_certification_page.dart \
  lib/features/auth/presentation/qualification_certification_step_three_page.dart \
  lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart \
  lib/features/me/presentation/my_resume_editor_page.dart
git commit -m "fix(me): unify editor keyboard dismiss behavior"
```

### Task 3: Patrol 真实链路验证我的简历编辑页

**Files:**
- Modify: `lib/shared/ui/test_keys.dart`
- Modify: `lib/features/auth/presentation/widgets/login_phone_view.dart`
- Modify: `lib/features/me/presentation/my_resume_editor_page.dart`
- Modify: `patrol_test/helpers/auth_test_helper.dart`
- Test: `patrol_test/me/my_resume_editor_keyboard_test.dart`

**Interfaces:**
- Consumes: `Future<void> bootstrapPatrolApp(PatrolIntegrationTester $)`
- Consumes: `ProviderContainer readAppProviderContainer(PatrolIntegrationTester $)`
- Produces: `AppTestKeys.loginTestJobSeekerButton`
- Produces: `AppTestKeys.pageMyResumeEditor`
- Produces: `AppTestKeys.actionMyResumeEditorOpenSelfEvaluation`
- Produces: `Future<void> ensureJobSeekerAuthenticated(PatrolIntegrationTester $)`

- [ ] **Step 1: 先写 Patrol 失败用例，固定目标链路**

```dart
patrolTest('我的简历编辑页 - 自我评价输入支持点击空白与拖动收键盘', ($) async {
  await bootstrapPatrolApp($);
  await ensureJobSeekerAuthenticated($);

  final container = readAppProviderContainer($);
  await container.read(routerProvider).push(
    RoutePaths.myResumeEditor,
    extra: const ResumeEditorArgs.create(),
  );

  await $(find.byKey(AppTestKeys.pageMyResumeEditor)).waitUntilVisible();
  await $(find.byKey(AppTestKeys.actionMyResumeEditorOpenSelfEvaluation)).tap();
  await $(find.byKey(AppTestKeys.pageSelfEvaluation)).waitUntilVisible();

  await $(find.byKey(AppTestKeys.fieldSelfEvaluationInput)).tap();
  await $.tester.enterText(
    find.byKey(AppTestKeys.fieldSelfEvaluationInput),
    '三年海外蓝领招聘与签证协同经验',
  );

  await $.tester.tapAt(const Offset(30, 120));
  await $.pump();
  expect(FocusManager.instance.primaryFocus, isNull);

  await $(find.byKey(AppTestKeys.fieldSelfEvaluationInput)).tap();
  await $.drag(find.byType(Scrollable).first, const Offset(0, -160));
  await $.pump();
  expect(FocusManager.instance.primaryFocus, isNull);
});
```

- [ ] **Step 2: 运行 Patrol 测试，确认当前失败点**

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 683FA825-579A-4240-AE46-FABCC5EA7B93 --target patrol_test/me/my_resume_editor_keyboard_test.dart`

Expected: FAIL，原因应指向缺少求职者快捷登录 Key、缺少简历编辑页稳定 Key，或缺少进入自我评价页的稳定入口。

- [ ] **Step 3: 最小补齐 Patrol 稳定锚点与求职者登录 helper**

```dart
// lib/shared/ui/test_keys.dart
static const Key loginTestJobSeekerButton = Key('login-test-job-seeker');
static const Key pageMyResumeEditor = Key('page-my-resume-editor');
static const Key actionMyResumeEditorOpenSelfEvaluation = Key(
  'action-my-resume-editor-open-self-evaluation',
);

// lib/features/auth/presentation/widgets/login_phone_view.dart
_LoginButton(
  key: AppTestKeys.loginTestJobSeekerButton,
  label: '认证.测试登录求职者'.tr(),
  onPressed: onTestWorkerLogin,
),

// lib/features/me/presentation/my_resume_editor_page.dart
return Scaffold(
  key: AppTestKeys.pageMyResumeEditor,
  ...
);

Widget _buildSelfEvaluationSection() {
  return Container(
    child: Column(
      children: <Widget>[
        _buildSectionHeader(
          title: '我的.自我评价'.tr(),
          trailing: _buildChevronActionIcon(
            key: AppTestKeys.actionMyResumeEditorOpenSelfEvaluation,
            onTap: _openSelfEvaluationPage,
          ),
        ),
      ],
    ),
  );
}

// patrol_test/helpers/auth_test_helper.dart
Future<void> ensureJobSeekerAuthenticated(PatrolIntegrationTester $) async {
  final container = readAppProviderContainer($);
  final authSession = container.read(authSessionProvider);
  if (authSession.isAuthenticated && authSession.user?.role == jobSeekerRoleId) {
    return;
  }

  await $(find.byKey(AppTestKeys.loginTestJobSeekerButton)).tap();
  await $.pumpAndSettle();

  final latestSession = container.read(authSessionProvider);
  if (!(latestSession.isAuthenticated && latestSession.user?.role == jobSeekerRoleId)) {
    throw StateError('求职者登录完成后角色校验失败');
  }
}
```

- [ ] **Step 4: 为新增 helper 和测试锚点补中文注释**

```dart
/// 确保 Patrol 用例运行在求职者登录态，优先复用登录页的测试快捷入口。
Future<void> ensureJobSeekerAuthenticated(PatrolIntegrationTester $) async {
  ...
}

/// Patrol 稳定锚点：打开自我评价页，避免测试依赖多语言文案点击箭头图标。
static const Key actionMyResumeEditorOpenSelfEvaluation = Key(
  'action-my-resume-editor-open-self-evaluation',
);
```

- [ ] **Step 5: 跑 Patrol 与相关 Widget 回归**

Run: `flutter test test/shared/widgets/tap_blank_to_dismiss_keyboard_test.dart test/features/me/self_evaluation_page_test.dart`

Run: `/Users/linwei/PUB/bin/patrol test --verbose -d 683FA825-579A-4240-AE46-FABCC5EA7B93 --target patrol_test/me/my_resume_editor_keyboard_test.dart`

Expected: 两层测试都通过；Patrol 用例可稳定完成“登录求职者 -> 进入简历编辑页 -> 打开自我评价页 -> 点击空白失焦 -> 拖动失焦”链路。

- [ ] **Step 6: 提交 Task 3**

```bash
git add \
  lib/shared/ui/test_keys.dart \
  lib/features/auth/presentation/widgets/login_phone_view.dart \
  lib/features/me/presentation/my_resume_editor_page.dart \
  patrol_test/helpers/auth_test_helper.dart \
  patrol_test/me/my_resume_editor_keyboard_test.dart
git commit -m "test(patrol): verify editor keyboard dismiss flow"
```

## Self-Review

- 规格覆盖：页面级统一、滚动级统一、`Widget` 验证、`Patrol` 验证、最小风险改造边界都已映射到 3 个任务。
- 占位符检查：计划中没有 `TODO/TBD/implement later` 等空洞描述，所有任务都给出了文件路径、代码片段和命令。
- 类型一致性：`AppTestKeys`、`ensureJobSeekerAuthenticated()`、`ResumeEditorArgs.create()`、`RoutePaths.myResumeEditor`、`RoutePaths.selfEvaluation` 在任务间保持同名引用。
