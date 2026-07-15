# Unsaved Exit Confirmation Verification

## 状态

- 当前验证为部分完成。
- 已完成静态诊断、相关 widget 测试、指定 iOS 模拟器真实启动验证。
- 尚未完成页面级 7 项手测验收矩阵，因此不能声明“完整验收全部通过”。

## 静态诊断

命令：

```bash
flutter analyze lib/shared/widgets/app_dialog.dart lib/shared/widgets/unsaved_changes_exit_guard.dart lib/features/auth/presentation/qualification_certification_step_two_page.dart lib/features/auth/presentation/qualification_certification_step_three_page.dart lib/features/visa/presentation/edit_visa_package_page.dart
```

结果：

```text
Analyzing 5 items...
No issues found!
```

结论：PASS

## 自动化测试

命令：

```bash
flutter test test/shared/widgets/unsaved_changes_exit_guard_test.dart test/features/auth/presentation/qualification_certification_step_two_page_test.dart test/features/auth/presentation/qualification_certification_step_three_page_test.dart test/features/visa/presentation/edit_visa_package_page_test.dart
```

结果：

```text
All tests passed!
```

补充说明：

- 测试期间存在多条 `Easy Localization` 缺失 key warning。
- 这些 warning 未导致失败，本次命令退出码为 `0`。

结论：PASS（带 warning）

## 指定模拟器启动

设备：

- iOS 模拟器 UDID：`8E3DF829-E72C-4B7D-8157-AAC88A8926B8`

命令：

```bash
flutter run -d 8E3DF829-E72C-4B7D-8157-AAC88A8926B8
```

结果摘要：

```text
Launching lib/main.dart on iPhone 16 in debug mode...
Running Xcode build...
APP_BOOTSTRAP_SUCCESS
route: /login/phone
Syncing files to device iPhone 16...
A Dart VM Service on iPhone 16 is available at: http://127.0.0.1:64934/YJknORknI8o=/
```

补充验证：

```bash
xcrun simctl list devices | grep 8E3DF829-E72C-4B7D-8157-AAC88A8926B8
```

结果：

```text
iPhone 16 (8E3DF829-E72C-4B7D-8157-AAC88A8926B8) (Booted)
```

截图证据：

- `/tmp/task5-simulator-launch.png`
- 截图显示应用已启动到“注册/登录”页面。

结论：PASS

## 已完成范围

- 公共未保存返回确认 helper 已落地。
- `QualificationCertificationStepThreePage` 已接入未保存返回拦截。
- `QualificationCertificationStepTwoPage` 已接入未保存返回拦截。
- `EditVisaPackagePage` 已接入未保存返回拦截，并完成快照口径修正。
- 相关 widget 测试均已通过。

## 未完成范围

- 以下 7 项页面级手测验收矩阵尚未执行：
  1. 认证第三步未改动直接返回
  2. 认证第三步修改从业年限后返回，弹窗展示，取消留页，确定离页
  3. 认证第二步新增资质图片后返回，弹窗展示，取消留页，确定离页
  4. 签证编辑页修改服务名后返回，弹窗展示，取消留页，确定离页
  5. 签证编辑页编辑态加载完成后不改动返回，不弹窗
  6. 提交成功后的业务跳转不弹未保存确认
  7. 系统返回手势与顶部返回按钮行为一致

## 结论

- 当前代码改动已通过静态检查和自动化测试。
- 应用已成功在指定模拟器启动。
- 由于缺少直接操控 iOS 模拟器界面的能力，本次未完成手动交互矩阵，故本报告为“部分验收通过”，不是“全部验收通过”。
