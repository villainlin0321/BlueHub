# Unsaved Exit Confirmation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为项目中的编辑页补齐“有实际改动时返回弹出未保存确认弹窗”的统一能力，并完成 `QualificationCertificationStepThreePage`、`QualificationCertificationStepTwoPage` 与 `EditVisaPackagePage` 的接入和模拟器验收。

**Architecture:** 先在公共层补一个基于 `AppDialog` 的未保存返回确认 helper，再在业务页通过“初始快照 vs 当前快照”的方式实现本页脏数据判断。每个页面统一拦截显式返回按钮与系统返回链路，提交成功时通过放行标记绕过拦截，避免误弹窗。

**Tech Stack:** Flutter 3.44.4、Riverpod、go_router、easy_localization、Patrol/Flutter 测试、iOS Simulator

## Global Constraints

- 弹窗必须使用现有 `AppDialog` 承载，视觉样式参考 Figma `Group 16`。
- 统一文案为 `现在退出，内容将不会保存`、`取消`、`确定`。
- 触发条件必须是“页面内容发生实际改动后才弹窗”，不是“页面本来有内容就弹”。
- 必须同时覆盖页面返回按钮与系统级返回链路。
- 提交成功后的正常离页不得再次触发未保存确认。
- 关键函数补函数级中文注释，关键代码处补中文注释。
- 完成实际运行验收时默认使用 iOS 模拟器 UDID `8E3DF829-E72C-4B7D-8157-AAC88A8926B8`。

---

### Task 1: 公共未保存确认 Helper

**Files:**
- Modify: `lib/shared/widgets/app_dialog.dart`
- Create: `lib/shared/widgets/unsaved_changes_exit_guard.dart`
- Test: `test/shared/widgets/unsaved_changes_exit_guard_test.dart`

**Interfaces:**
- Consumes: `showAppDialog<T>()`, `AppDialog`, `AppDialogAction`
- Produces: `Future<bool> showUnsavedChangesExitDialog(BuildContext context)`, `Future<bool> confirmDiscardChangesIfNeeded({required BuildContext context, required bool hasUnsavedChanges})`

- [ ] **Step 1: 写一个失败测试，锁定 helper 的放行规则**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/shared/widgets/unsaved_changes_exit_guard.dart';

void main() {
  testWidgets('无改动时直接允许离开', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: false,
    );

    expect(canLeave, isTrue);
    expect(find.text('现在退出，内容将不会保存'), findsNothing);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/shared/widgets/unsaved_changes_exit_guard_test.dart`
Expected: FAIL，提示 `Target of URI doesn't exist` 或 `confirmDiscardChangesIfNeeded` 未定义

- [ ] **Step 3: 先实现最小 helper，让无改动路径直接通过**

```dart
import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// 展示未保存内容返回确认弹窗，统一收口文案和按钮样式。
Future<bool> showUnsavedChangesExitDialog(BuildContext context) {
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppDialog(
        title: '现在退出，内容将不会保存',
        actions: <AppDialogAction>[
          AppDialogAction.secondary(
            label: '取消',
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppDialogAction.primary(
            label: '确定',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  ).then((bool? value) => value ?? false);
}

/// 根据当前页面是否存在未保存改动，决定是否放行离开页面。
Future<bool> confirmDiscardChangesIfNeeded({
  required BuildContext context,
  required bool hasUnsavedChanges,
}) {
  if (!hasUnsavedChanges) {
    return Future<bool>.value(true);
  }
  return showUnsavedChangesExitDialog(context);
}
```

- [ ] **Step 4: 补齐弹窗展示测试并验证按钮行为**

```dart
testWidgets('有改动时弹出确认框并支持取消', (WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    ),
  );

  final BuildContext context = tester.element(find.byType(Scaffold));
  final Future<bool> result = confirmDiscardChangesIfNeeded(
    context: context,
    hasUnsavedChanges: true,
  );

  await tester.pumpAndSettle();

  expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
  expect(find.text('取消'), findsOneWidget);
  expect(find.text('确定'), findsOneWidget);

  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();

  expect(await result, isFalse);
});
```

- [ ] **Step 5: 运行公共 helper 测试**

Run: `flutter test test/shared/widgets/unsaved_changes_exit_guard_test.dart`
Expected: PASS

- [ ] **Step 6: 若 Figma 样式需要，最小增强 `AppDialog` 对“仅主文案”场景的支持**

```dart
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const <AppDialogAction>[],
    this.titleTextAlign = TextAlign.center,
    this.messageTextAlign = TextAlign.center,
    this.titleBottomSpacing = 8,
  }) : assert(message == null || content == null, 'message 与 content 只能提供一个');

  final double titleBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kAppDialogMaxWidth),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kAppDialogRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, textAlign: titleTextAlign),
              if (message != null) ...<Widget>[
                SizedBox(height: titleBottomSpacing),
                Text(message!, textAlign: messageTextAlign),
              ],
              if (content != null) ...<Widget>[
                SizedBox(height: titleBottomSpacing),
                content!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: 提交本任务**

```bash
git add lib/shared/widgets/app_dialog.dart \
  lib/shared/widgets/unsaved_changes_exit_guard.dart \
  test/shared/widgets/unsaved_changes_exit_guard_test.dart
git commit -m "feat: add unsaved exit confirmation helper"
```

### Task 2: 认证第三步接入未保存返回拦截

**Files:**
- Modify: `lib/features/auth/presentation/qualification_certification_step_three_page.dart`
- Test: `test/features/auth/presentation/qualification_certification_step_three_page_test.dart`

**Interfaces:**
- Consumes: `confirmDiscardChangesIfNeeded({required BuildContext context, required bool hasUnsavedChanges})`
- Produces: `_QualificationStepThreeSnapshot`, `_buildCurrentSnapshot()`, `_handleAttemptLeave()`

- [ ] **Step 1: 写一个失败测试，锁定“未改动直接返回、改动后弹窗”**

```dart
testWidgets('认证第三步修改从业年限后返回会弹出确认框', (WidgetTester tester) async {
  await tester.pumpWidget(buildQualificationStepThreeTestApp());

  await tester.enterText(
    find.byKey(AppTestKeys.fieldQualificationYearsOfService),
    '3',
  );
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();

  expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
});
```

- [ ] **Step 2: 运行页面测试确认失败**

Run: `flutter test test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
Expected: FAIL，提示测试工具函数或弹窗行为不存在

- [ ] **Step 3: 在页面内引入快照结构和离页判断**

```dart
class _QualificationStepThreeSnapshot {
  const _QualificationStepThreeSnapshot({
    required this.selectedCountries,
    required this.yearsOfService,
  });

  final List<String> selectedCountries;
  final String yearsOfService;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _QualificationStepThreeSnapshot &&
        listEquals(other.selectedCountries, selectedCountries) &&
        other.yearsOfService == yearsOfService;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(selectedCountries), yearsOfService);
}

late _QualificationStepThreeSnapshot _initialSnapshot;
bool _allowDirectPop = false;

/// 采集当前表单快照，用于判断用户是否修改了服务信息。
_QualificationStepThreeSnapshot _buildCurrentSnapshot() {
  return _QualificationStepThreeSnapshot(
    selectedCountries: List<String>.of(_selectedCountries),
    yearsOfService: _experienceController.text.trim(),
  );
}
```

- [ ] **Step 4: 用 `PopScope` 和返回按钮统一接入拦截**

```dart
Future<void> _handleAttemptLeave() async {
  final bool canLeave = await confirmDiscardChangesIfNeeded(
    context: context,
    hasUnsavedChanges: _buildCurrentSnapshot() != _initialSnapshot,
  );
  if (!mounted || !canLeave) {
    return;
  }

  _allowDirectPop = true;
  Navigator.of(context).pop();
}

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: _allowDirectPop,
    onPopInvokedWithResult: (bool didPop, Object? result) async {
      if (didPop || _allowDirectPop) {
        return;
      }
      await _handleAttemptLeave();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleAttemptLeave,
          icon: const AppSvgIcon(...),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 5: 在提交成功前放行返回，避免成功跳转被误拦截**

```dart
Future<void> _handleSubmit() async {
  if (_isSubmitting) {
    return;
  }
  setState(() {
    _isSubmitting = true;
  });
  try {
    ...
    if (!mounted) {
      return;
    }
    _allowDirectPop = true;
    context.push(
      RoutePaths.appResult,
      extra: AppResultPageArgs(...),
    );
  } finally {
    ...
  }
}
```

- [ ] **Step 6: 运行第三步页面测试**

Run: `flutter test test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
Expected: PASS

- [ ] **Step 7: 提交本任务**

```bash
git add lib/features/auth/presentation/qualification_certification_step_three_page.dart \
  test/features/auth/presentation/qualification_certification_step_three_page_test.dart
git commit -m "feat: guard qualification step three exit"
```

### Task 3: 认证第二步接入未保存返回拦截

**Files:**
- Modify: `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
- Test: `test/features/auth/presentation/qualification_certification_step_two_page_test.dart`

**Interfaces:**
- Consumes: `confirmDiscardChangesIfNeeded({required BuildContext context, required bool hasUnsavedChanges})`
- Produces: `_QualificationStepTwoSnapshot`, `_buildCurrentSnapshot()`, `_handleAttemptLeave()`

- [ ] **Step 1: 写一个失败测试，锁定上传状态变更后返回弹窗**

```dart
testWidgets('认证第二步存在已选资质图片时返回会弹出确认框', (WidgetTester tester) async {
  await tester.pumpWidget(buildQualificationStepTwoTestApp());

  final dynamic state = tester.state(find.byType(QualificationCertificationStepTwoPage));
  state.debugSetBusinessLicenseForTest('mock-path/image.png');
  await tester.pump();

  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();

  expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
});
```

- [ ] **Step 2: 运行页面测试确认失败**

Run: `flutter test test/features/auth/presentation/qualification_certification_step_two_page_test.dart`
Expected: FAIL，提示测试辅助入口或返回拦截未实现

- [ ] **Step 3: 提取第二步页面快照并补统一离页方法**

```dart
class _QualificationStepTwoSnapshot {
  const _QualificationStepTwoSnapshot({
    required this.businessLicensePath,
    required this.specialPermitPath,
  });

  final String businessLicensePath;
  final String specialPermitPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _QualificationStepTwoSnapshot &&
        other.businessLicensePath == businessLicensePath &&
        other.specialPermitPath == specialPermitPath;
  }

  @override
  int get hashCode => Object.hash(businessLicensePath, specialPermitPath);
}

_QualificationStepTwoSnapshot _buildCurrentSnapshot() {
  return _QualificationStepTwoSnapshot(
    businessLicensePath: _businessLicenseImage?.path ?? '',
    specialPermitPath: _specialPermitImage?.path ?? '',
  );
}
```

- [ ] **Step 4: 用 `PopScope` 和返回按钮接入统一 helper**

```dart
Future<void> _handleAttemptLeave() async {
  final bool canLeave = await confirmDiscardChangesIfNeeded(
    context: context,
    hasUnsavedChanges: _buildCurrentSnapshot() != _initialSnapshot,
  );
  if (!mounted || !canLeave) {
    return;
  }
  _allowDirectPop = true;
  Navigator.of(context).pop();
}
```

- [ ] **Step 5: 运行第二步页面测试**

Run: `flutter test test/features/auth/presentation/qualification_certification_step_two_page_test.dart`
Expected: PASS

- [ ] **Step 6: 提交本任务**

```bash
git add lib/features/auth/presentation/qualification_certification_step_two_page.dart \
  test/features/auth/presentation/qualification_certification_step_two_page_test.dart
git commit -m "feat: guard qualification step two exit"
```

### Task 4: 签证套餐编辑页接入未保存返回拦截

**Files:**
- Modify: `lib/features/visa/presentation/edit_visa_package_page.dart`
- Modify: `lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart`
- Test: `test/features/visa/presentation/edit_visa_package_page_test.dart`

**Interfaces:**
- Consumes: `confirmDiscardChangesIfNeeded({required BuildContext context, required bool hasUnsavedChanges})`
- Produces: `_EditVisaPackageSnapshot`, `_buildCurrentSnapshot()`, `_markSavedAndAllowExit()`, `_handleAttemptLeave()`

- [ ] **Step 1: 写一个失败测试，锁定服务名变更后返回弹窗**

```dart
testWidgets('签证套餐编辑页修改服务名后返回会弹出确认框', (WidgetTester tester) async {
  await tester.pumpWidget(buildEditVisaPackageTestApp());

  await tester.enterText(
    find.byKey(AppTestKeys.fieldEditVisaPackageName),
    '新的套餐名',
  );
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();

  expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
});
```

- [ ] **Step 2: 运行页面测试确认失败**

Run: `flutter test test/features/visa/presentation/edit_visa_package_page_test.dart`
Expected: FAIL，提示未实现返回拦截

- [ ] **Step 3: 在页面状态类中实现快照模型与基线记录**

```dart
class _EditVisaPackageSnapshot {
  const _EditVisaPackageSnapshot({
    required this.serviceName,
    required this.duration,
    required this.countryCode,
    required this.visaTypeCode,
    required this.currency,
    required this.coverImageId,
    required this.tiers,
  });

  final String serviceName;
  final String duration;
  final String? countryCode;
  final String? visaTypeCode;
  final String currency;
  final String coverImageId;
  final List<Map<String, Object?>> tiers;
}

late _EditVisaPackageSnapshot _initialSnapshot;
bool _hasInitialSnapshot = false;
bool _allowDirectPop = false;

/// 汇总页面当前所有会影响提交结果的字段，作为未保存判断基线。
_EditVisaPackageSnapshot _buildCurrentSnapshot() {
  final EditVisaPackageState state = ref.read(editVisaPackageControllerProvider);
  return _EditVisaPackageSnapshot(
    serviceName: _serviceNameController.text.trim(),
    duration: _durationController.text.trim(),
    countryCode: state.selectedCountryCode,
    visaTypeCode: state.selectedVisaTypeCode,
    currency: state.selectedCurrency.apiValue,
    coverImageId: '${_coverImage?.uploadedFileId ?? ''}|${_coverImage?.path ?? ''}',
    tiers: _tiers.map((EditVisaPackageTierViewDraft tier) {
      return <String, Object?>{
        'tierId': tier.tierId,
        'name': tier.nameController.text.trim(),
        'price': tier.priceController.text.trim(),
        'description': tier.descriptionController.text.trim(),
      };
    }).toList(growable: false),
  );
}
```

- [ ] **Step 4: 在新建态和编辑态完成基线初始化**

```dart
@override
void initState() {
  super.initState();
  _serviceNameController = TextEditingController();
  _durationController = TextEditingController();
  _tiers = <EditVisaPackageTierViewDraft>[_createTierDraft()];
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      return;
    }
    ref.read(editVisaPackageControllerProvider.notifier).loadServiceTags();
    if (_isEditMode) {
      _loadPackageDetail();
      return;
    }
    _initialSnapshot = _buildCurrentSnapshot();
    _hasInitialSnapshot = true;
  });
}

Future<void> _loadPackageDetail() async {
  ...
  setState(() {
    _coverImage = coverImage;
    _isLoadingPackageDetail = false;
    _initialSnapshot = _buildCurrentSnapshot();
    _hasInitialSnapshot = true;
  });
}
```

- [ ] **Step 5: 统一拦截 header 返回与系统返回**

```dart
Future<void> _handleAttemptLeave() async {
  final bool hasUnsavedChanges =
      _hasInitialSnapshot && _buildCurrentSnapshot() != _initialSnapshot;
  final bool canLeave = await confirmDiscardChangesIfNeeded(
    context: context,
    hasUnsavedChanges: hasUnsavedChanges,
  );
  if (!mounted || !canLeave) {
    return;
  }
  _allowDirectPop = true;
  Navigator.of(context).pop();
}

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: _allowDirectPop,
    onPopInvokedWithResult: (bool didPop, Object? result) async {
      if (didPop || _allowDirectPop) {
        return;
      }
      await _handleAttemptLeave();
    },
    child: EditVisaPackagePageView(
      onBackTap: _handleAttemptLeave,
      ...
    ),
  );
}
```

- [ ] **Step 6: 在保存草稿/发布成功后重置基线并放行返回**

```dart
void _markSavedAndAllowExit() {
  _initialSnapshot = _buildCurrentSnapshot();
  _hasInitialSnapshot = true;
  _allowDirectPop = true;
}

ref.listen<EditVisaPackageState>(editVisaPackageControllerProvider, (
  EditVisaPackageState? previous,
  EditVisaPackageState next,
) {
  if (previous?.submitSuccessId != next.submitSuccessId &&
      next.submitSuccessId > 0) {
    _markSavedAndAllowExit();
    if (Navigator.of(context).canPop()) {
      context.pop(true);
    } else {
      context.go(RoutePaths.jobs);
    }
  }
});
```

- [ ] **Step 7: 运行签证编辑页测试**

Run: `flutter test test/features/visa/presentation/edit_visa_package_page_test.dart`
Expected: PASS

- [ ] **Step 8: 提交本任务**

```bash
git add lib/features/visa/presentation/edit_visa_package_page.dart \
  lib/features/visa/presentation/widgets/edit_visa_package_page_view.dart \
  test/features/visa/presentation/edit_visa_package_page_test.dart
git commit -m "feat: guard visa package editor exit"
```

### Task 5: 诊断与模拟器验收

**Files:**
- Modify: `docs/superpowers/reports/2026-07-05-unsaved-exit-confirmation-verification.md`

**Interfaces:**
- Consumes: Task 1-4 的实现结果
- Produces: 验证报告，记录静态检查与模拟器验收结果

- [ ] **Step 1: 运行静态诊断**

Run: `flutter analyze lib/shared/widgets/app_dialog.dart lib/shared/widgets/unsaved_changes_exit_guard.dart lib/features/auth/presentation/qualification_certification_step_two_page.dart lib/features/auth/presentation/qualification_certification_step_three_page.dart lib/features/visa/presentation/edit_visa_package_page.dart`
Expected: No issues found

- [ ] **Step 2: 运行相关测试**

Run: `flutter test test/shared/widgets/unsaved_changes_exit_guard_test.dart test/features/auth/presentation/qualification_certification_step_two_page_test.dart test/features/auth/presentation/qualification_certification_step_three_page_test.dart test/features/visa/presentation/edit_visa_package_page_test.dart`
Expected: PASS

- [ ] **Step 3: 启动指定模拟器并运行应用**

Run: `flutter run -d 8E3DF829-E72C-4B7D-8157-AAC88A8926B8`
Expected: 应用成功启动到指定 iOS 模拟器

- [ ] **Step 4: 按验收矩阵逐项手测**

```text
1. 认证第三步未改动直接返回
2. 认证第三步修改从业年限后返回，弹窗展示，取消留页，确定离页
3. 认证第二步新增资质图片后返回，弹窗展示，取消留页，确定离页
4. 签证编辑页修改服务名后返回，弹窗展示，取消留页，确定离页
5. 签证编辑编辑态加载完成后不改动返回，不弹窗
6. 提交成功后的业务跳转不弹未保存确认
7. 系统返回手势与顶部返回按钮行为一致
```

- [ ] **Step 5: 写验证报告**

```md
# Unsaved Exit Confirmation Verification

- `flutter analyze`：PASS
- 相关 `flutter test`：PASS
- 设备：`8E3DF829-E72C-4B7D-8157-AAC88A8926B8`
- 手测结果：
  - 认证第三步：PASS
  - 认证第二步：PASS
  - 签证编辑页：PASS
  - 系统返回链路：PASS
```

- [ ] **Step 6: 提交本任务**

```bash
git add docs/superpowers/reports/2026-07-05-unsaved-exit-confirmation-verification.md
git commit -m "docs: add unsaved exit confirmation verification report"
```
