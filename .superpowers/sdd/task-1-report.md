# Task 1 Report: 图片压缩服务与规则测试

## what you implemented

- 在 `pubspec.yaml` 新增依赖 `flutter_image_compress: ^2.4.0`，并通过 `flutter pub get` 更新 `pubspec.lock`。
- 新增 `lib/shared/network/services/image_upload_compress_service.dart`，实现：
  - `PreparedUploadPayload`
  - `ImageInfoForCompress`
  - `ImageCompressionEngine`
  - `FlutterImageCompressionEngine`
  - `ImageUploadCompressService`
  - `ImageUploadCompressService.resolveTargetDimensions(...)`
  - `ImageUploadCompressService.prepareForUpload(...)`
- 新增 `test/shared/network/services/image_upload_compress_service_test.dart`，覆盖：
  - 宽高异常兜底到 `1920x1920`
  - 长边未超限保留原尺寸
  - 短边未超限保留原尺寸
  - 同时超过长短边限制时按任务要求等比缩放
  - 非图片文件跳过压缩并保留原始内容
  - 多轮压缩后仍超限时返回最后一轮结果

## tests run and results

1. `flutter pub get`
   - 结果：成功
   - 关键输出：新增 `flutter_image_compress 2.4.0` 及其平台依赖

2. `flutter test test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：RED，符合预期
   - 原因：`image_upload_compress_service.dart` 不存在，相关类型未定义

3. `flutter test test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：RED，符合预期
   - 原因：首轮最小实现后，`同时超过长短边限制时按参考公式等比缩放` 用例失败，实际为 `1920`，期望为 `1440`

4. `flutter test test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：GREEN
   - 关键输出：`00:00 +5: All tests passed!`

5. `flutter test test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：RED，符合预期
   - 原因：新增“多轮压缩后仍超限时返回最后一轮结果”后，`payload.isCompressed` 实际为 `false`，期望为 `true`

6. `dart format lib/shared/network/services/image_upload_compress_service.dart test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：成功

7. `flutter test test/shared/network/services/image_upload_compress_service_test.dart`
   - 结果：GREEN
   - 关键输出：`00:00 +6: All tests passed!`

## TDD evidence with RED and GREEN commands + relevant output

### RED 1

Command:

```bash
flutter test test/shared/network/services/image_upload_compress_service_test.dart
```

Relevant output:

```text
Error when reading 'lib/shared/network/services/image_upload_compress_service.dart': No such file or directory
Type 'ImageCompressionEngine' not found.
Undefined name 'ImageUploadCompressService'.
Some tests failed.
```

### GREEN 1

Command:

```bash
flutter test test/shared/network/services/image_upload_compress_service_test.dart
```

Relevant output:

```text
00:00 +5: All tests passed!
```

### RED 2

Command:

```bash
flutter test test/shared/network/services/image_upload_compress_service_test.dart
```

Relevant output:

```text
多轮压缩后仍超限时返回最后一轮结果 [E]
Expected: <true>
  Actual: <false>
Some tests failed.
```

### GREEN 2

Command:

```bash
flutter test test/shared/network/services/image_upload_compress_service_test.dart
```

Relevant output:

```text
00:00 +6: All tests passed!
```

## files changed

- `pubspec.yaml`
- `pubspec.lock`
- `lib/shared/network/services/image_upload_compress_service.dart`
- `test/shared/network/services/image_upload_compress_service_test.dart`
- `.superpowers/sdd/task-1-report.md`

## self-review findings

- 服务实现保持在 Task 1 范围内，没有改动 `FileService` 或其他调用方。
- 压缩逻辑通过依赖注入暴露文件读取、图片信息读取、压缩引擎，便于后续 Task 2 集成和补更多测试。
- 第二轮实现只补了“返回最后一轮压缩结果”的缺口，没有顺手扩范围。
- `_shouldCompress` 目前仅明确跳过非图片和 `.svg`，这是保守实现；更细的图片格式策略应由后续集成任务根据真实上传入口补齐。

## any concerns

- brief 中给出的缩放示例代码片段与断言值存在差异：按片段里的比例选择会得到 `1920x1440`，但任务要求的测试断言是 `1440x1080`。实现最终以任务中的“精确断言值”和测试为准。
