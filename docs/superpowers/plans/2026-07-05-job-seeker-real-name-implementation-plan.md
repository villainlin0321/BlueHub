# Job Seeker Real Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为求职者“我的”页补齐实名认证入口，并新增求职者专用实名认证页，使用现有 `real-name-verify` 接口完成提交。

**Architecture:** 保持企业/服务商现有资质认证流不动，新增一条求职者专用实名页面与路由。页面复用现有上传工具、`UserService.realNameVerify()` 与登录态刷新能力，通过 `isVerified` 驱动“我的”页展示。

**Tech Stack:** Flutter, Riverpod, go_router, EasyLocalization, 现有 `UserService`/`UploadPickerUtils`

## Global Constraints

- 仅使用现有 `isVerified` 作为实名状态来源，不扩展审核中、驳回等更多状态。
- 不改造企业/服务商的资质认证流。
- 不新增“实名认证详情查询”接口。
- 不新增第三方依赖。
- 沿用现有页面风格、路由方案、上传工具和 Toast 能力。
- 新增函数补函数级中文注释，关键代码补简洁中文注释。
- 优先补高价值测试，避免低价值铺量。

---

## File Structure

- Create: `lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
  - 求职者实名认证页，负责表单输入、图片选择/上传、校验、提交与成功回流。
- Modify: `lib/app/router/route_paths.dart`
  - 新增求职者实名认证路由常量。
- Modify: `lib/app/router/app_router.dart`
  - 注册求职者实名认证页面路由。
- Modify: `lib/features/me/presentation/role_pages/job_seeker_me_page.dart`
  - 在资料卡中补实名认证提示区，并把点击导向求职者实名认证页。
- Modify: `assets/translations/zh.json`
  - 补求职者实名认证文案。
- Modify: `assets/translations/en.json`
  - 补求职者实名认证文案。
- Test: `test/features/me/job_seeker_real_name_page_test.dart`
  - 验证入口展示、跳转、表单校验与提交。

### Task 1: Add Route And Me Entry

**Files:**
- Create: `test/features/me/job_seeker_real_name_page_test.dart`
- Modify: `lib/app/router/route_paths.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/me/presentation/role_pages/job_seeker_me_page.dart`
- Modify: `assets/translations/zh.json`
- Modify: `assets/translations/en.json`

**Interfaces:**
- Consumes: `CurrentUserViewData.isVerified`, `context.push(String location)`
- Produces: `RoutePaths.jobSeekerRealNameVerification`, `_ProfileCard(onRealNameTap: VoidCallback)`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('求职者我的页会展示实名认证入口并跳转到实名页', (WidgetTester tester) async {
  await tester.pumpWidget(
    TestApp(
      initialLocation: RoutePaths.me,
      overrides: <Override>[
        authSessionProvider.overrideWith(() {
          return FakeAuthSessionNotifier.verified(false);
        }),
      ],
    ),
  );

  expect(find.text('您还未实名，点击去实名认证'), findsOneWidget);

  await tester.tap(find.text('您还未实名，点击去实名认证'));
  await tester.pumpAndSettle();

  expect(find.text('实名认证'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: FAIL，提示找不到实名页路由或入口文案。

- [ ] **Step 3: Add route path and router registration**

```dart
// lib/app/router/route_paths.dart
static const jobSeekerRealNameVerification = '/me/real-name-verification';
```

```dart
// lib/app/router/app_router.dart
GoRoute(
  path: RoutePaths.jobSeekerRealNameVerification,
  builder: (context, state) => const JobSeekerRealNameVerificationPage(),
),
```

- [ ] **Step 4: Add me-page entry with isVerified copy**

```dart
// lib/features/me/presentation/role_pages/job_seeker_me_page.dart
_ProfileCard(
  userViewData: userViewData,
  stats: stats,
  onTap: () => context.push(RoutePaths.myInfo),
  onRealNameTap: () => context.push(RoutePaths.jobSeekerRealNameVerification),
  onOrderTap: () => context.push(RoutePaths.myOrders),
  onResumeTap: () => context.push(RoutePaths.myResume),
  onApplicationTap: () => context.push(RoutePaths.myApplications),
  onFavoriteTap: () => context.push(RoutePaths.myFavorites),
)
```

```dart
// lib/features/me/presentation/role_pages/job_seeker_me_page.dart
Text(
  userViewData.isVerified ? '我的.已完成实名认证'.tr() : '我的.点击去实名认证'.tr(),
  style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
)
```

- [ ] **Step 5: Add translation keys**

```json
{
  "我的": {
    "已完成实名认证": "已完成实名认证",
    "点击去实名认证": "您还未实名，点击去实名认证",
    "实名认证": "实名认证"
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: PASS，且可以从“我的”页跳到实名页标题。

- [ ] **Step 7: Commit**

```bash
git add lib/app/router/route_paths.dart lib/app/router/app_router.dart lib/features/me/presentation/role_pages/job_seeker_me_page.dart assets/translations/zh.json assets/translations/en.json test/features/me/job_seeker_real_name_page_test.dart
git commit -m "feat(me): add job seeker real-name entry"
```

### Task 2: Build Real Name Page UI And Validation

**Files:**
- Modify: `test/features/me/job_seeker_real_name_page_test.dart`
- Create: `lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
- Modify: `assets/translations/zh.json`
- Modify: `assets/translations/en.json`

**Interfaces:**
- Consumes: `UploadPickerUtils.pickImagesWithSourceSheet({required BuildContext context})`, `PickedUploadFile`
- Produces: `JobSeekerRealNameVerificationPage`, `_handleSubmit()`, `_pickImage({required bool isFrontSide})`

- [ ] **Step 1: Extend test with validation expectations**

```dart
testWidgets('实名页缺少必填项时会提示并阻止提交', (WidgetTester tester) async {
  await tester.pumpWidget(
    TestApp(initialLocation: RoutePaths.jobSeekerRealNameVerification),
  );

  await tester.tap(find.text('同意并提交'));
  await tester.pump();

  expect(find.text('请填写姓名'), findsOneWidget);
  expect(find.text('请填写身份证号'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: FAIL，提示实名页缺少表单和校验文案。

- [ ] **Step 3: Implement the page skeleton**

```dart
class JobSeekerRealNameVerificationPage extends ConsumerStatefulWidget {
  const JobSeekerRealNameVerificationPage({super.key});

  @override
  ConsumerState<JobSeekerRealNameVerificationPage> createState() =>
      _JobSeekerRealNameVerificationPageState();
}
```

```dart
final TextEditingController _nameController = TextEditingController();
final TextEditingController _idCardController = TextEditingController();
PickedUploadFile? _frontImage;
PickedUploadFile? _backImage;
bool _isSubmitting = false;
```

- [ ] **Step 4: Add minimal form UI matching the spec**

```dart
_FormRow(label: '我的.实名认证姓名'.tr(), controller: _nameController)
_FormRow(label: '我的.实名认证身份证号'.tr(), controller: _idCardController)
_UploadSection(
  title: '我的.身份证验证'.tr(),
  subtitle: '我的.请上传本人的身份证照片'.tr(),
  frontLabel: '我的.上传国徽面'.tr(),
  backLabel: '我的.上传人像面'.tr(),
)
FilledButton(
  onPressed: _isSubmitting ? null : _handleSubmit,
  child: Text('我的.实名认证提交'.tr()),
)
```

- [ ] **Step 5: Add minimal validation**

```dart
bool _validate() {
  if (_nameController.text.trim().isEmpty) {
    AppToast.show('我的.请填写姓名'.tr());
    return false;
  }
  if (_idCardController.text.trim().isEmpty) {
    AppToast.show('我的.请填写身份证号'.tr());
    return false;
  }
  if (_frontImage == null) {
    AppToast.show('我的.请上传身份证国徽面'.tr());
    return false;
  }
  if (_backImage == null) {
    AppToast.show('我的.请上传身份证人像面'.tr());
    return false;
  }
  return true;
}
```

- [ ] **Step 6: Wire image picking**

```dart
Future<void> _pickImage({required bool isFrontSide}) async {
  final List<PickedUploadFile> images =
      await UploadPickerUtils.pickImagesWithSourceSheet(context: context);
  if (images.isEmpty || !mounted) {
    return;
  }
  setState(() {
    if (isFrontSide) {
      _frontImage = images.first;
    } else {
      _backImage = images.first;
    }
  });
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: PASS，点击提交时能看到缺项提示。

- [ ] **Step 8: Commit**

```bash
git add lib/features/me/presentation/job_seeker_real_name_verification_page.dart assets/translations/zh.json assets/translations/en.json test/features/me/job_seeker_real_name_page_test.dart
git commit -m "feat(me): add job seeker real-name form page"
```

### Task 3: Submit Real Name Verification And Refresh Session

**Files:**
- Modify: `lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
- Modify: `test/features/me/job_seeker_real_name_page_test.dart`
- Modify: `assets/translations/zh.json`
- Modify: `assets/translations/en.json`

**Interfaces:**
- Consumes: `UserService.realNameVerify({required RealNameVerifyBO request})`, `authSessionProvider.notifier`
- Produces: `_submitVerification()`, success pop + session refresh behavior

- [ ] **Step 1: Add failing test for successful submit**

```dart
testWidgets('实名表单完整时会提交并刷新登录态', (WidgetTester tester) async {
  final FakeUserService userService = FakeUserService();
  final FakeAuthSessionNotifier authNotifier = FakeAuthSessionNotifier.verified(false);

  await tester.pumpWidget(
    TestApp(
      initialLocation: RoutePaths.jobSeekerRealNameVerification,
      overrides: <Override>[
        userServiceProvider.overrideWithValue(userService),
        authSessionProvider.overrideWith(() => authNotifier),
      ],
    ),
  );

  await tester.enterText(find.byKey(const Key('real-name-input')), '张三');
  await tester.enterText(find.byKey(const Key('id-card-input')), '110101199003047777');
  userService.seedUploadedUrls(
    frontUrl: 'https://example.com/front.png',
    backUrl: 'https://example.com/back.png',
  );

  await tester.tap(find.text('同意并提交'));
  await tester.pumpAndSettle();

  expect(userService.lastRealNameRequest?.realName, '张三');
  expect(authNotifier.refreshMeCallCount, 1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: FAIL，提示未调用 `realNameVerify` 或未刷新用户信息。

- [ ] **Step 3: Implement submit flow**

```dart
Future<void> _handleSubmit() async {
  if (!_validate()) {
    return;
  }
  setState(() => _isSubmitting = true);
  try {
    await ref.read(userServiceProvider).realNameVerify(
      request: RealNameVerifyBO(
        realName: _nameController.text.trim(),
        idCardNumber: _idCardController.text.trim(),
        idCardFrontUrl: _frontImage!.uploadedFileUrl ?? _frontImage!.path,
        idCardBackUrl: _backImage!.uploadedFileUrl ?? _backImage!.path,
      ),
    );
    await ref.read(authSessionProvider.notifier).refreshUserProfile();
    if (!mounted) {
      return;
    }
    AppToast.show('我的.实名认证提交成功'.tr());
    Navigator.of(context).pop(true);
  } catch (error) {
    if (!mounted) {
      return;
    }
    AppToast.show(_resolveSubmitError(error));
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
```

- [ ] **Step 4: Ensure notifier exposes a refresh method or reuse an existing one**

```dart
Future<void> refreshUserProfile() async {
  final profile = await ref.read(userServiceProvider).getMe();
  state = state.copyWith(user: AuthUser.fromUserVO(profile));
}
```

- [ ] **Step 5: Add success copy and error fallback strings**

```json
{
  "我的": {
    "实名认证提交": "同意并提交",
    "实名认证提交成功": "实名认证提交成功",
    "实名认证提交失败": "实名认证提交失败",
    "请填写姓名": "请填写姓名",
    "请填写身份证号": "请填写身份证号",
    "请上传身份证国徽面": "请上传身份证国徽面",
    "请上传身份证人像面": "请上传身份证人像面"
  }
}
```

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/features/me/job_seeker_real_name_page_test.dart`

Expected: PASS，成功提交后调用接口并刷新登录态。

- [ ] **Step 7: Run analyze**

Run: `flutter analyze lib/features/me/presentation/job_seeker_real_name_verification_page.dart lib/features/me/presentation/role_pages/job_seeker_me_page.dart lib/app/router/app_router.dart lib/app/router/route_paths.dart test/features/me/job_seeker_real_name_page_test.dart`

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/me/presentation/job_seeker_real_name_verification_page.dart lib/features/me/presentation/role_pages/job_seeker_me_page.dart lib/app/router/app_router.dart lib/app/router/route_paths.dart assets/translations/zh.json assets/translations/en.json test/features/me/job_seeker_real_name_page_test.dart
git commit -m "feat(me): add job seeker real-name verification flow"
```

## Self-Review

- Spec coverage：已覆盖“我的”页入口、独立页面、路由、上传、提交、成功回流和测试。
- Placeholder scan：无 `TODO/TBD`，每个任务都给出文件、代码片段、命令和期望结果。
- Type consistency：路由常量、页面类名、`RealNameVerifyBO`、`refreshUserProfile()` 等名称在任务间保持一致。
