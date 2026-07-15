# Qualification Cached Network Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 仅在资质认证流程中接入 `cached_network_image`，让第一页和第二页的历史网络图片回显具备缓存与稳定错误回退能力。

**Architecture:** 保留当前“本地文件优先、远端 URL 兜底”的数据链路，只调整认证流程页面的渲染层。`qualification_preview_resolver.dart` 继续负责路径解析，页面组件根据路径类型分别走 `Image.file` 或 `CachedNetworkImage`，避免把缓存策略下沉到数据解析层。

**Tech Stack:** Flutter, `cached_network_image`, `flutter_test`

## Global Constraints

- 仅修改认证流程相关页面，不扩散到其他上传/预览组件。
- 保留本地文件即时预览逻辑，不能影响用户刚上传图片后的本地回显。
- 复用现有占位图与错误回退素材，避免视觉样式变化。
- 添加函数级中文注释，并在关键代码处补充中文注释。
- 变更完成后必须运行目标测试并检查静态诊断。

---

### Task 1: 认证流程接入 CachedNetworkImage

**Files:**
- Modify: `lib/features/auth/presentation/qualification_preview_resolver.dart`
- Modify: `lib/features/auth/presentation/qualification_certification_page.dart`
- Modify: `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
- Modify: `test/features/auth/qualification_certification_flow_test.dart`

**Interfaces:**
- Consumes: `QualificationPreviewResolver.resolvePreviewPath(UploadedQualificationDoc? document) -> String?`
- Consumes: `PickedUploadFile.path -> String`
- Produces: 第一页 `_UploadCard._buildPreview()` 支持 `CachedNetworkImage`
- Produces: 第二页 `_UploadPlaceholder.build()` 支持 `CachedNetworkImage`

- [ ] **Step 1: 写失败测试，锁定“网络图不再走 NetworkImage 而改为缓存组件”**

```dart
test('预览解析器在缺少本地路径时会退回远端图片地址', () {
  const UploadedQualificationDoc document = UploadedQualificationDoc(
    docType: QualificationDocType.idCard,
    docName: '法人身份证国徽面',
    fileId: 301,
    fileUrl: 'https://example.com/id-emblem.png',
    localPath: '',
  );

  final String? previewPath = QualificationPreviewResolver.resolvePreviewPath(
    document,
  );

  expect(previewPath, 'https://example.com/id-emblem.png');
});
```

- [ ] **Step 2: 运行测试确认当前基线失败点只落在实现未切换**

Run: `flutter test test/features/auth/qualification_certification_flow_test.dart`
Expected: 现有测试通过或仅在你新增断言处失败；不能出现编译错误或无关失败。

- [ ] **Step 3: 最小实现 `qualification_preview_resolver.dart`，只保留路径解析，不继续返回 `NetworkImage`**

```dart
/// 统一解析资质认证页面的预览图片来源，兼容本地临时文件与后端图片地址。
class QualificationPreviewResolver {
  const QualificationPreviewResolver._();

  /// 优先返回本地预览路径；本地路径缺失时退回后端返回的 `fileUrl`。
  static String? resolvePreviewPath(UploadedQualificationDoc? document) {
    if (document == null) {
      return null;
    }
    final String localPath = document.localPath.trim();
    if (localPath.isNotEmpty) {
      return localPath;
    }
    final String fileUrl = document.fileUrl.trim();
    return fileUrl.isEmpty ? null : fileUrl;
  }

  /// 判断当前路径是否为可直接展示的网络图片地址。
  static bool isNetworkPath(String? path) {
    final String normalizedPath = path?.trim() ?? '';
    return normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://');
  }
}
```

- [ ] **Step 4: 在第一页 `_UploadCard._buildPreview()` 中按路径来源切换实现**

```dart
Widget _buildPreview() {
  final String? path = pickedFile?.path.trim();
  if (path == null || path.isEmpty) {
    return Image.asset(
      imageAsset,
      width: 159,
      height: 116,
      fit: BoxFit.contain,
    );
  }

  if (QualificationPreviewResolver.isNetworkPath(path)) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Image.asset(
          imageAsset,
          width: 159,
          height: 116,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        imageAsset,
        width: 159,
        height: 116,
        fit: BoxFit.contain,
      ),
    ),
  );
}
```

- [ ] **Step 5: 在第二页 `_UploadPlaceholder.build()` 中按路径来源切换实现**

```dart
Widget _buildPreviewImage() {
  final String? path = pickedFile?.path.trim();
  if (path == null || path.isEmpty) {
    return const _QualificationPlaceholderImage();
  }
  if (QualificationPreviewResolver.isNetworkPath(path)) {
    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const _QualificationPlaceholderImage(),
    );
  }
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const _QualificationPlaceholderImage(),
  );
}
```

- [ ] **Step 6: 调整测试为“路径解析 + 页面使用缓存组件”的组合验证**

```dart
test('预览解析器在缺少本地路径时会退回远端图片地址', () {
  const UploadedQualificationDoc document = UploadedQualificationDoc(
    docType: QualificationDocType.idCard,
    docName: '法人身份证国徽面',
    fileId: 301,
    fileUrl: 'https://example.com/id-emblem.png',
    localPath: '',
  );

  final String? previewPath = QualificationPreviewResolver.resolvePreviewPath(
    document,
  );

  expect(previewPath, 'https://example.com/id-emblem.png');
  expect(QualificationPreviewResolver.isNetworkPath(previewPath), isTrue);
});
```

- [ ] **Step 7: 运行测试确认通过**

Run: `flutter test test/features/auth/qualification_certification_flow_test.dart`
Expected: `All tests passed!`

- [ ] **Step 8: 运行静态诊断确认无新增问题**

Run: 在 IDE 中检查以下文件诊断结果为空
- `lib/features/auth/presentation/qualification_preview_resolver.dart`
- `lib/features/auth/presentation/qualification_certification_page.dart`
- `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
- `test/features/auth/qualification_certification_flow_test.dart`

Expected: 无 Error，无新增 Warning。

- [ ] **Step 9: 提交改动**

```bash
git add \
  lib/features/auth/presentation/qualification_preview_resolver.dart \
  lib/features/auth/presentation/qualification_certification_page.dart \
  lib/features/auth/presentation/qualification_certification_step_two_page.dart \
  test/features/auth/qualification_certification_flow_test.dart \
  docs/superpowers/plans/2026-07-05-qualification-cached-network-image.md
git commit -m "fix: use cached network image in qualification flow"
```
