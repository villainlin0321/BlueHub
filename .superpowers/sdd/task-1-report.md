# Task 1 报告

## 任务目标
- 将认证流程中的远端图片预览从 `NetworkImage` 切换为 `CachedNetworkImage`。
- 保留本地文件预览能力，并让回填场景统一通过路径解析器判断来源。

## 实现摘要
- 在 `qualification_preview_resolver.dart` 中移除 `ImageProvider` 构造职责，仅保留预览路径解析与网络路径判断。
- 在第一页 `qualification_certification_page.dart` 的 `_UploadCard._buildPreview()` 中按路径来源切换：
  - 远端地址使用 `CachedNetworkImage`
  - 本地路径继续使用 `Image.file`
  - 空态与异常回退到原有占位图
- 在第二页 `qualification_certification_step_two_page.dart` 的 `_UploadPlaceholder` 中同步完成同样的切换。
- 在 `qualification_certification_flow_test.dart` 中补充了远端图片回填场景的 Widget 测试，直接断言第一页和第二页都使用 `CachedNetworkImage`。
- 按要求补充了函数级中文注释，并在关键切换逻辑处增加中文说明注释。

## 修改文件
- `lib/features/auth/presentation/qualification_preview_resolver.dart`
- `lib/features/auth/presentation/qualification_certification_page.dart`
- `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
- `test/features/auth/qualification_certification_flow_test.dart`

## 测试记录
1. 红灯验证
   - 命令：`flutter test test/features/auth/qualification_certification_flow_test.dart`
   - 结果：新增测试先失败，报错 `Member not found: 'QualificationPreviewResolver.isNetworkPath'`，证明当前实现尚未切到新的路径判断与缓存图片方案。

2. 绿灯验证
   - 命令：`flutter test test/features/auth/qualification_certification_flow_test.dart`
   - 结果：`5` 个测试全部通过，覆盖：
     - 服务商资料历史图片回填
     - 企业资料历史图片回填
     - 预览路径解析回退到远端地址
     - 第一页远端身份证图片使用 `CachedNetworkImage`
     - 第二页远端营业执照图片使用 `CachedNetworkImage`

3. 诊断检查
   - 检查文件：
     - `lib/features/auth/presentation/qualification_preview_resolver.dart`
     - `lib/features/auth/presentation/qualification_certification_page.dart`
     - `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
     - `test/features/auth/qualification_certification_flow_test.dart`
   - 结果：无新增 Error，无新增 Warning。

## 自检结论
- 本次改动仅覆盖 Task1 指定的 4 个代码文件和本报告文件。
- 远端图片回填不再依赖 `NetworkImage`，符合 Task1 目标。
- 本地图片预览与占位回退逻辑保持可用，没有扩散到无关页面。

## 追加：认证第二页空态/错误态双相机修复

### 问题根因
- 第二页上传区的外层 `Stack` 会始终叠加一层相机按钮。
- 空态和文件加载失败态回退到 `_QualificationPlaceholderImage` 时，该占位组件内部又额外绘制了一层相机按钮。
- 两层相机同时存在，导致认证第二页在空态/错误态出现“双相机叠加”。

### 本次修复
- 仅修改认证流程相关文件：
  - `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
  - `test/features/auth/qualification_certification_flow_test.dart`
- 将 `_QualificationPlaceholderImage` 调整为只负责渲染占位背景图，不再自行绘制相机按钮。
- 保留外层上传容器的统一相机叠加层，让空态、错误态和正常预览态都复用同一套入口样式。
- 在关键修复处补充中文注释，说明去重原因与职责边界。

### 追加测试记录
1. 红灯验证
   - 命令：`flutter test test/features/auth/qualification_certification_flow_test.dart`
   - 新增测试：
     - `第二页空态上传区只显示一层相机按钮`
     - `第二页文件预览失败后仍只显示一层相机按钮`
   - 初始结果：两个新增测试失败，分别统计到 `4` 个和 `3` 个 `qualification_camera.svg`，与双相机叠加根因一致。

2. 绿灯验证
   - 命令：`flutter test test/features/auth/qualification_certification_flow_test.dart`
   - 结果：`7` 个测试全部通过，覆盖远端图片回填、第一页/第二页缓存图预览，以及第二页空态/错误态的单相机展示。

3. 诊断检查
   - 检查文件：
     - `lib/features/auth/presentation/qualification_certification_step_two_page.dart`
     - `test/features/auth/qualification_certification_flow_test.dart`
   - 结果：无新增 Error，无新增 Warning。

### 追加自检结论
- 修复范围限定在认证第二页上传区与其对应测试，没有改动非认证流程文件。
- 第二页空态与错误态现在都只保留一层相机按钮，消除了视觉叠加问题。
