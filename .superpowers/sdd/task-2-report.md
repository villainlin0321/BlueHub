# Task 2 Report

## What I implemented

- 在 `FileService` 构造函数中新增可注入的 `ImageUploadCompressService`，默认仍使用生产实现。
- 将 `uploadFile()` 的上传前准备改为调用 `prepareForUpload()`，统一使用 `PreparedUploadPayload` 提供的：
  - `bytes`
  - `mimeType`
  - `fileSize`
- 将上传链路中的 `presign`、`putToUploadUrl`、`confirmUpload` 以及相关日志字段，全部切换为使用实际上传载荷元数据。
- 新增 `file_service_test.dart`，覆盖：
  - 非图片上传沿用原始 `mimeType` / `fileSize`
  - 图片上传使用压缩后 `mimeType` / `fileSize`

## Tests run and results

1. `flutter test test/shared/network/services/file_service_test.dart`
   - 结果：PASS（2 tests passed）
2. `flutter test test/shared/network/services/auth_service_test.dart`
   - 结果：PASS（2 tests passed）

## TDD evidence

### RED

Command:

```bash
flutter test test/shared/network/services/file_service_test.dart
```

Relevant output:

```text
test/shared/network/services/file_service_test.dart:73:20: Error: The super constructor has no corresponding named parameter.
    required super.imageUploadCompressService,
                   ^
00:00 +0 -1: Some tests failed.
```

结论：测试先失败，失败原因符合预期，说明 `FileService` 尚未支持压缩服务注入。

### GREEN

Command:

```bash
flutter test test/shared/network/services/file_service_test.dart
```

Relevant output:

```text
00:00 +0: 非图片上传沿用原始 mimeType 和 fileSize
00:00 +1: 图片上传使用压缩后的 mimeType 和 fileSize
00:00 +2: All tests passed!
```

### Regression

Command:

```bash
flutter test test/shared/network/services/auth_service_test.dart
```

Relevant output:

```text
00:00 +0: 邮箱验证码登录时空密码不会写入请求体
00:00 +1: 邮箱验证码登录时 null 密码不会写入请求体
00:00 +2: All tests passed!
```

## Files changed

- `lib/shared/network/services/file_service.dart`
- `test/shared/network/services/file_service_test.dart`
- `.superpowers/sdd/task-2-report.md`

## Self-review findings

- 接入范围保持在任务要求内，没有修改 `ImageUploadCompressService` 的既有行为。
- 上传链路三个关键阶段现在都使用同一份 `PreparedUploadPayload` 元数据，避免了压缩后仍上报原始文件大小或 MIME 的不一致。
- 测试通过重写 `presign` / `putToUploadUrl` / `confirmUpload` 记录参数，直接验证了链路元数据传递，而不是只验证最终返回值。

## Concerns

- 运行 `file_service_test.dart` 时会输出 `Easy Localization` 的缺失 key warning：`上传.文件上传失败`。这次任务未改动该行为，且不影响测试通过，但它说明当前测试环境没有对应本地化文案加载。
