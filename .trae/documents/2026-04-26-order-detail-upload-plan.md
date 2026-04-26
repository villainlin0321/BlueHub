# 订单详情上传交互实现计划

## Summary

- 目标：为 `lib/features/order/presentation/order_detail_page.dart` 的材料上传区增加真实本地选择交互，包括上传类型底部弹窗、图片/文件选择、回显列表，以及按 Figma 还原的默认态、上传中多文件态、成功态、失败态。
- 交互入口：点击当前 `_UploadPlaceholder` 的“上传文件”区域时，弹出底部 `bottomSheet`，其视觉严格参考 Figma 节点 `59:187469`。
- 选择能力：相机、相册使用 `image_picker: ^1.2.1`；本地文件使用 `file_picker: ^11.0.2`。相册和文件入口支持一次多选；相机单次拍摄一个。
- 状态策略：无后端接口时，所选文件默认都进入成功态；但代码结构需要完整支持默认态、上传中多文件态、成功态、失败态 4 种展示，以便严格映射 Figma 设计。

## Current State Analysis

- 当前页面文件是 `lib/features/order/presentation/order_detail_page.dart`，页面仍为 `StatelessWidget`，上传区只支持静态占位点击，尚无真实文件选择与状态存储。
- 当前材料区结构为：
  - `_MaterialUploadCard`：渲染 3 个材料项容器。
  - `_MaterialUploadItem`：单个材料项标题、必填标记、“查看样例”和底部 `_UploadPlaceholder`。
  - `_UploadPlaceholder`：固定 48 高的浅灰色上传入口。
- 现有上传入口仅回调 `onUploadTap`，没有文件模型、状态模型、底部弹窗、回显列表和失败/进度处理。
- `pubspec.yaml` 当前已经包含 `image_picker: ^1.2.1`，但尚未包含 `file_picker: ^11.0.2`。
- `pubspec.yaml` 当前 `flutter.assets` 中已经声明 `assets/images/`，且存在重复项；这次应沿用 `assets/images/` 作为切图目录并顺手去重。
- 当前项目实际资源目录是 `assets/images/`，并不存在 `lib/assets/images/` 的既有使用约定，因此本次资源应落到 `assets/images/`。
- 当前已能稳定解析到的 Figma 节点包括：
  - `59:187469`：上传类型底部弹窗。
  - `59:191129`：上传中且允许继续添加多个文件的场景。
  - `59:190970`：补充节点，包含上传成功 / 上传失败相关上传卡片变体。
- 目前 Figma 结构化读取对另外几个节点不稳定，因此实现时应以已成功读取的 3 个节点为主，并把状态模型设计成可兼容这些变体。

## Proposed Changes

### 1. 将订单详情页改为可持有上传状态的页面

- 修改 `lib/features/order/presentation/order_detail_page.dart`。
- 将 `OrderDetailPage` 从 `StatelessWidget` 调整为 `StatefulWidget`，因为需要持有：
  - 每个材料项的上传文件列表。
  - 每个文件的本地来源类型。
  - 每个文件的展示状态，如默认、上传中、成功、失败。
- 在页面内部建立轻量本地状态，不引入 Riverpod/Provider，因为本次交互只在当前页面内使用。

### 2. 引入上传数据模型与状态枚举

- 仍在 `order_detail_page.dart` 内定义私有模型，避免为本次局部交互额外扩散文件。
- 计划新增：
  - `_UploadSourceType`：`camera / gallery / file`
  - `_UploadItemState`：`uploading / success / failure`
  - `_PickedUploadFile`：描述单个已选文件，包含：
    - `id`
    - `name`
    - `path`
    - `sourceType`
    - `state`
    - `isImage`
    - 可选 `errorMessage`
- 计划将 `_MaterialRequirement` 扩展为可关联一个 `key/id`，用于把 3 个材料项和各自上传列表稳定映射起来。

### 3. 实现上传类型底部弹窗

- 在 `order_detail_page.dart` 中新增私有方法，例如 `_showUploadTypeSheet(...)`，点击 `_UploadPlaceholder` 时调用。
- 弹窗严格参考 Figma 节点 `59:187469`：
  - 总体为底部圆角弹层。
  - 顶部标题为“上传类型”。
  - 右上角有关闭按钮。
  - 中间横向 3 个入口卡片：
    - 拍照上传
    - 本地相册
    - 本地文件
  - 底部有 Home Indicator 风格拖杆区域。
- 图标资源需要从 Figma 切出并落到 `assets/images/`：
  - 相机图标
  - 相册图标
  - 文件图标
- 交互绑定：
  - 拍照上传：`ImagePicker().pickImage(source: ImageSource.camera)`
  - 本地相册：`ImagePicker().pickMultiImage()`
  - 本地文件：`FilePicker.platform.pickFiles(allowMultiple: true)`

### 4. 将上传入口替换为“回显列表 + 底部继续添加”

- 修改 `_MaterialUploadItem` 与 `_UploadPlaceholder` 的关系。
- 目标是让当前 `L473` 的位置从“固定占位组件”变成“根据状态切换的内容区域”：
  - 无文件时：显示默认 `_UploadPlaceholder`
  - 有文件时：显示已选文件列表 + 底部继续添加占位
- 视觉依据：
  - 整体区域设计参考 `59:191046`
  - 多文件上传中态参考 `59:191129`
  - 成功/失败变体以 `59:190970` 为主进行映射
- 结构计划：
  - `_MaterialUploadContent`
  - `_UploadFileCard`
  - `_AddMoreUploadPlaceholder`
- 当已有文件存在时，底部仍保留一个 48 高的“上传文件”继续添加区域，支持追加多文件。

### 5. 严格实现 4 类上传展示态

- 在 `order_detail_page.dart` 中新增按状态渲染的文件卡片 UI。
- 参考节点与计划映射如下：

- 默认态
  - 仍使用当前浅灰底 48 高上传入口
  - 文案“上传文件”，左侧加号图标

- 上传中态
  - 参考 `59:191129`
  - 单个上传中卡片包含：
    - 左侧 32x32 PDF/图片文件类型图标
    - 文件名
    - 进度条
  - 当前无后端时不需要真实分片上传，但代码中保留该渲染能力

- 成功态
  - 参考 `59:190970` 中的成功变体
  - 需要根据文件类型渲染：
    - 图片文件：照片类样式
    - 非图片文件：PDF/文件类样式
  - 成功态通常包含文件缩略/图标、文件名，以及可删除或状态标记区域

- 失败态
  - 参考 `59:190970` 中的失败变体
  - 需要展示失败视觉态，并提供重试或重新上传入口
  - 虽然本次默认成功，不主动进入失败，但结构上必须可渲染

### 6. 文件选择与状态流设计

- 本次无真实上传接口时，状态流固定如下：
  - 相机：选择 1 个文件后直接进入成功态
  - 相册：可多选，所选图片直接批量追加到成功态
  - 本地文件：可多选，所选文件直接批量追加到成功态
- 但实现时保留一个清晰的本地状态流接口，便于后续接入真实上传：
  - 新增文件
  - 标记上传中
  - 标记成功
  - 标记失败
  - 删除文件
  - 重试失败文件
- 这样可以在后续接 API 时复用当前页面结构，而无需重做 UI。

### 7. 资源与依赖更新

- 修改 `pubspec.yaml`
  - 新增 `file_picker: ^11.0.2`
  - 保留 `image_picker: ^1.2.1`
  - 清理 `flutter.assets` 中重复的 `assets/images/`
- 从 Figma 下载以下资源到 `assets/images/`
  - 上传弹窗相机图标
  - 上传弹窗相册图标
  - 上传弹窗文件图标
  - 若成功/失败态中的 PDF/照片图标与当前已有资源不一致，则一并导出
  - 若关闭按钮需要严格还原，也一并导出

## Assumptions & Decisions

- 决策：上传交互完全在 `order_detail_page.dart` 内完成，本次不抽离成单独 feature 模块。
- 决策：资源目录使用当前项目既有的 `assets/images/`，不使用 `lib/assets/images/`。
- 决策：相机使用 `image_picker` 单选；相册使用 `pickMultiImage()` 多选；文件使用 `file_picker` 多选。
- 决策：无后端接口时，真实选择后的文件默认全部进入成功态。
- 决策：虽然默认成功，但 UI 结构必须支持上传中和失败态，以严格覆盖 Figma 场景。
- 决策：上传区回显采用“每个材料项自己维护一个文件列表”的本地状态模型。
- 假设：`59:190970` 中的成功/失败变体足够代表 `59:191123` 与 `59:191140` 的最终视觉，不再单独等待这两个节点恢复读取。
- 假设：本次不实现真实网络上传，也不实现文件权限失败后的复杂异常引导，只做合理的本地错误提示。

## Verification Steps

- 点击任一材料项“上传文件”时，弹出与 `59:187469` 对齐的底部弹窗。
- 弹窗中 3 个入口均可点击：
  - 拍照上传能拉起相机
  - 本地相册能一次选择多张图片
  - 本地文件能一次选择多个文件
- 选择完成后，文件会回显到对应材料项区域，而不是全局混放。
- 单个材料项已有文件后，仍显示底部“继续添加”上传入口，支持追加多个文件。
- 图片文件与非图片文件在回显 UI 中使用各自对应的图标/缩略风格。
- 成功态、上传中态、失败态组件都能被正确渲染；默认交互流下实际进入成功态。
- `pubspec.yaml` 中依赖和资源声明正确，无重复无缺失。
- 实现后运行 `flutter pub get`、`flutter analyze`，确认无静态分析错误。
