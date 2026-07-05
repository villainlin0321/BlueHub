# 求职者实名认证 Task 2 报告

## 任务结论

已完成求职者实名认证 Task 2：

- 将占位页扩展为接近 Figma 的实名表单页
- 保留并完善本地校验，点击 `同意并提交` 时会阻止缺项继续提交
- 继续复用 `UploadPickerUtils` 与 `PickedUploadFile`，完成本地选图与页面展示
- 未接入最终提交接口，保持 Task 2 边界清晰

## 本次改动

### 页面视觉

- 按 `/Users/linwei/BlueHub/.figma/image/screenshot_129_16461.png` 收敛整体层级
- 顶部改为白底标题区，保留居中标题与返回按钮
- 主体改为单张白色表单卡片，而不是此前的双卡片块状布局
- 姓名、身份证号字段改为更贴近设计稿的行式输入
- 身份证验证区改为标题/副文案在上、双示意图在中、上传标签在下的结构
- 空态示意图改为现有资源：
  - `assets/images/qualification_id_emblem.png`
  - `assets/images/qualification_id_portrait.png`
- 底部新增与设计稿一致的实名说明文案，并保留固定底部按钮区

### 交互与校验

- 保留 Task 2 既有的本地校验逻辑
- 姓名、身份证号、国徽面、人像面四项均缺失时，会在页面内显示错误文案
- 用户开始输入或重新选择图片后，对应错误文案会即时清除
- 点击上传区继续复用 `UploadPickerUtils.pickImagesWithSourceSheet()`
- 选图后优先显示本地图片预览；若本地文件不可读，则回退到设计稿示意图

### 测试

- 保留入口跳转与已实名/未实名展示测试
- 保留缺项阻止提交测试
- 新增页面说明文案和上传标签的可见性断言，覆盖本轮 Figma 对齐后的关键结构

## 涉及文件

- 修改：`lib/features/me/presentation/job_seeker_real_name_verification_page.dart`
- 修改：`test/features/me/job_seeker_real_name_page_test.dart`
- 修改：`assets/translations/zh.json`
- 修改：`assets/translations/en.json`
- 修改：`docs/superpowers/specs/2026-07-05-job-seeker-real-name-design.md`
- 新增：`.superpowers/sdd/reports/job-seeker-real-name-task-2-report.md`

## 自检结果

- `flutter test test/features/me/job_seeker_real_name_page_test.dart`
  - 通过
- `flutter analyze lib/features/me/presentation/job_seeker_real_name_verification_page.dart test/features/me/job_seeker_real_name_page_test.dart`
  - 通过
- VS Code diagnostics
  - 本次修改文件无新增诊断问题

## 风险与顾虑

- 当前按钮点击在校验通过后仍未接最终提交流程，这属于 Task 2 的既定范围，不是遗漏
- Figma 视觉已尽量按截图收敛，但 Flutter 原生 `AppBar`、字体渲染与测试环境尺寸和导出稿仍存在细微像素差异
- 用户已明确要求保留工作区内无关改动不动，本次提交仅选择 Task 2 相关文件
