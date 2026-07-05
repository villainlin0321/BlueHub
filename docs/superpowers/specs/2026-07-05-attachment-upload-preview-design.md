# 附件上传与预览改造设计

## 背景

当前项目已经具备图片上传、文件上传和部分文件下载打开能力，但整体行为仍存在以下问题：

- 图片上传与文件上传入口分散，文件选择未限制为 PDF。
- 图片预览与文件打开没有统一入口，不同页面各自处理，体验不一致。
- 现有依赖中的 `pdf` 包更偏向 PDF 生成与处理，不适合作为应用内 PDF 可视化预览方案。

本次需求要求：

- 文件上传限制为仅允许选择 PDF。
- 图片与 PDF 在列表中点击后都支持预览。
- PDF 使用专门的 Flutter 预览库，不引入 `pdf` 生成库。

## 目标

- 统一“附件选择、类型判断、点击预览”的交互链路。
- 将“文件上传仅允许 PDF”沉淀为公共能力，避免业务页面重复判断。
- 为本地文件路径与远程文件 URL 提供一致的预览入口。
- 在尽量少改动现有业务结构的前提下，覆盖当前已接入文件上传的主要页面。

## 非目标

- 不在本次需求中引入 PDF 生成、编辑、批注等能力。
- 不重构所有上传组件为单一基础组件。
- 不替换当前对象存储上传流程与后端文件接口。
- 不主动新增自动化测试，仅做静态诊断与必要的手动验收设计。

## 方案概览

采用“公共 PDF 选择方法 + 公共附件预览页 + 业务页面最小接入”的方案。

整体分为三层：

1. 选择层：在 `UploadPickerUtils` 中新增 PDF 专用选择能力，只允许从本地文件选择 `.pdf`。
2. 预览层：新增统一附件预览页，根据附件类型在应用内展示图片或 PDF。
3. 业务层：将当前直接调用 `pickFromFiles()` 的页面改为调用新的 PDF 选择能力，并把点击事件接入统一预览页。

该方案可以在保持现有页面结构基本不变的前提下，统一上传约束和预览体验，同时降低后续新增附件场景时的重复实现成本。

## 依赖方案

### 依赖选择

本次不引入 `pdf` 包。

推荐新增 `syncfusion_flutter_pdfviewer` 作为 PDF 预览依赖，原因如下：

- 同时支持网络 URL 与本地文件路径。
- 接入简单，适合现有项目的最小改造。
- 常见预览能力完整，后续若需要翻页、缩放、跳页扩展也较容易。

### 不选 `pdf` 包的原因

- `pdf` 更适合生成 PDF 文档或进行内容绘制。
- 当前需求核心是“应用内预览”，不是“生成 PDF”。
- 若使用 `pdf` 仍需额外引入 viewer 才能完成实际展示，无法直接满足需求。

## 公共选择层设计

### `UploadPickerUtils` 扩展

在现有 `UploadPickerUtils` 中保留图片相关方法不变，并新增 PDF 专用方法：

```dart
static Future<List<PickedUploadFile>> pickPdfFiles() async;
static bool isPdfPath(String path);
```

设计要点：

- `pickPdfFiles()` 内部使用 `file_picker` 的扩展名过滤，仅允许选择 `pdf`。
- 返回结构继续复用 `PickedUploadFile`，避免业务层大规模改造上传逻辑。
- `PickedUploadFile.isImage` 对 PDF 保持 `false`，由新增的 `isPdfPath()` 负责类型判断。
- 若用户取消选择，返回空列表。
- 若底层插件异常，沿用现有页面的 `try/catch + Toast` 处理模式。

### 文件限制规则

本次统一约束为：

- 图片入口：仍然走拍照、相册、多图选择逻辑。
- 文件入口：只允许选择 PDF。
- 非图片文件不再作为“任意文件”进入上传链路。

这样可以明确区分“图片上传”和“PDF 文件上传”两个入口，避免业务页面在上传后再做过滤，减少无效选择与错误提示。

## 公共预览层设计

### 新增统一附件预览页

新增一个公共附件预览页，例如：

- `lib/shared/presentation/attachment_preview_page.dart`

页面职责：

- 接收附件标题、预览地址、附件类型等参数。
- 根据路径判断展示本地文件还是网络文件。
- 根据类型分发到图片预览或 PDF 预览。

建议参数结构：

```dart
class AttachmentPreviewArgs {
  final String path;
  final String? title;
  final bool isImage;
  final bool isPdf;
}
```

类型判断原则：

- 优先使用业务层显式传入的 `isImage` / `isPdf`。
- 仅当业务层未提供可靠类型信息时，才回退到路径扩展名判断。
- 这样可以兼容“远程 URL 不带文件后缀”的场景，避免误判导致无法预览。

### 图片预览规则

图片预览需支持：

- 本地临时文件路径。
- 后端返回的远程图片 URL。

展示策略：

- 网络图片：使用现有缓存图片能力加载。
- 本地图片：使用 `FileImage` 或 `Image.file` 加载。
- 加载失败时展示统一兜底占位。

### PDF 预览规则

PDF 预览使用 `syncfusion_flutter_pdfviewer`：

- 网络 PDF：走 `SfPdfViewer.network(...)`
- 本地 PDF：走 `SfPdfViewer.file(...)`

页面内需提供：

- 顶部标题栏，显示文件名或业务传入标题。
- 加载中状态。
- 加载失败提示与兜底 UI。

### 预览入口封装

为避免业务页面重复写跳转逻辑，建议新增一个公共方法，例如：

```dart
Future<void> openAttachmentPreview(
  BuildContext context, {
  required String path,
  String? title,
});
```

该方法负责：

- 判断当前路径是图片还是 PDF。
- 对不支持的类型弹出统一提示。
- 使用现有路由方式打开附件预览页。

## 业务接入范围

### 首批接入页面

根据当前代码扫描结果，优先接入以下直接调用文件选择能力的页面：

- `lib/features/order/presentation/order_detail_page.dart`
- `lib/features/visa/presentation/edit_visa_package_page.dart`

接入方式：

- 将文件选择入口从 `pickFromFiles()` 替换为 `pickPdfFiles()`。
- 保持原有上传流程不变，继续复用 `PickedUploadFile` 与 `FileService.uploadFile(...)`。
- 点击图片或 PDF 附件时，统一改为调用公共预览入口。

### 已有下载打开逻辑的兼容策略

当前部分页面已经具备“下载到本地后调用 `OpenFilex.open(...)` 打开”的逻辑。

本次改造后：

- 普通点击预览优先走应用内预览。
- 原有“下载并打开”逻辑保留为兜底能力，避免某些特殊场景需要导出到本地时失效。
- 仅当应用内预览明确失败或业务上需要下载时，再继续复用原下载能力。

## 路由与参数设计

### 路由接入方式

优先沿用现有应用的统一路由体系：

- 在 `RoutePaths` 中新增附件预览页路由常量。
- 在 `app_router.dart` 中注册附件预览页。
- 业务页面通过统一入口跳转，避免散落的直接 `Navigator.push(...)`。

### 参数传递原则

预览页所需参数应尽量保持轻量，只传展示必需信息：

- `path`
- `title`
- `isImage`
- `isPdf`

不直接把业务对象整包传入，避免预览页与订单、签证、简历等业务模型耦合。

## 错误处理

### 选择阶段

- 用户取消选择：静默返回，不提示错误。
- 插件调用失败：由调用页使用现有 toast 文案提示“选择文件失败”。

### 预览阶段

- 路径为空或无效：提示“文件地址无效”。
- 非图片且非 PDF：提示“暂不支持预览该文件类型”。
- PDF 加载失败：预览页展示失败态，并允许用户返回上一级。
- 图片加载失败：展示统一占位图，不让页面崩溃。

### 上传阶段

上传逻辑仍沿用现有 `FileService`：

- 不改变 MIME 推断逻辑。
- PDF 继续以 `application/pdf` 上传。
- 失败提示文案沿用各业务页面已有文案。

## 兼容性与边界

### 本地路径与远程 URL

预览能力必须同时兼容：

- 用户刚选择、尚未上传完成的本地文件路径。
- 上传成功后后端返回的远程 `fileUrl`。

因此类型判断优先基于路径扩展名，而不是仅依赖后端字段。

如果业务对象已经持有稳定类型信息，例如图片标识、文件 MIME 或明确的 PDF 标记，则优先由业务层显式传入，路径扩展名只作为兜底。

### 文件名缺失场景

部分业务对象可能只有 URL、没有独立文件名字段。

处理规则：

- 优先使用业务层显式传入的标题。
- 若标题为空，则使用路径或 URL 的最后一段作为默认标题。

### 图片与 PDF 混合列表

如果同一个业务列表中同时存在图片和 PDF：

- 图片点击进入图片预览。
- PDF 点击进入 PDF 预览。
- 图标、缩略区和点击事件均保持与附件类型一致。

## 代码改动范围

预计涉及以下文件：

- `pubspec.yaml`
- `lib/utils/upload_picker_utils.dart`
- `lib/app/router/route_paths.dart`
- `lib/app/router/app_router.dart`
- `lib/features/order/presentation/order_detail_page.dart`
- `lib/features/visa/presentation/edit_visa_package_page.dart`

预计新增以下公共文件：

- `lib/shared/presentation/attachment_preview_page.dart`
- 可选：`lib/shared/utils/attachment_preview_utils.dart`

若在接入过程中发现其他页面已具备同类附件点击行为，可在不扩大需求范围的前提下同步接入统一预览入口。

## 验收标准

- 文件上传入口只能选择 PDF 文件。
- 图片上传逻辑不受影响，仍可正常选择和上传。
- 订单页中的图片与 PDF 点击后均进入应用内预览。
- 签证编辑页中的图片与 PDF 点击后均进入应用内预览。
- 预览支持本地文件路径与远程 URL 两种来源。
- 生产代码无新增静态诊断错误。

## 手动验收建议

1. 在支持文件上传的页面点击“本地文件”，确认文件选择器只允许选择 PDF。
2. 选择一个本地 PDF，确认能够正常加入上传队列并上传成功。
3. 点击未上传完成或刚选择的本地 PDF，确认可在应用内预览。
4. 点击上传完成后的远程 PDF，确认仍可在应用内预览。
5. 点击图片附件，确认进入图片预览且不受 PDF 改造影响。
6. 对错误地址或异常文件执行预览，确认页面能展示失败态而不是崩溃。

## 风险

- 新增 PDF viewer 后，iOS/Android 平台可能需要关注原生依赖集成情况。
- 某些后端返回的文件 URL 若不包含扩展名，可能需要业务层额外补充 MIME 或类型信息。
- 若现有页面的附件点击逻辑分散较多，首批接入后可能仍有遗漏页面需要后续补齐。

## 推荐实施顺序

1. 在 `pubspec.yaml` 中接入 PDF 预览依赖。
2. 扩展 `UploadPickerUtils`，新增 PDF 专用选择与类型判断方法。
3. 新增统一附件预览页与公共打开方法。
4. 接入 `order_detail_page.dart` 的文件选择与附件点击预览。
5. 接入 `edit_visa_package_page.dart` 的文件选择与附件点击预览。
6. 完成静态诊断检查，并进行关键路径手动验收。
