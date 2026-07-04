# Task 5 Report

## 任务结论

- 已完成岗位发布页面与控制器的关键日志链路补齐，覆盖页面进入、首帧、点击发布、校验开始、校验失败、请求开始、请求失败等高价值节点。
- 保持本地排障模式，日志继续输出到控制台和本地文件。
- 未新增第三方依赖，沿用现有 `ActionLog`、`StateLog`、`AppLogScope`、`AppLogger` 能力。

## 修改文件

- `lib/features/jobs/presentation/post_job_page.dart`
- `lib/features/jobs/application/post_job/post_job_controller.dart`
- `test/features/jobs/post_job_logging_test.dart`

## 实现说明

### 1. 页面日志链路

- 在岗位发布页 `initState()` 中补充 `POST_JOB_PAGE_ENTER`，记录页面进入事件。
- 在首帧 `addPostFrameCallback` 中补充 `POST_JOB_FIRST_FRAME`，用于区分首屏渲染慢还是后续异步加载慢。
- 点击“发布”时，先通过 `AppLogScope.run()` 建立包含 `traceId`、`route`、`module`、`feature`、`action` 的作用域，再输出 `POST_JOB_SUBMIT_TAP`，确保后续控制器日志和请求链路自动继承同一组上下文。

### 2. 控制器日志链路

- 发布入口新增 `POST_JOB_VALIDATE_START`，用于标记表单校验阶段开始。
- 表单校验失败时新增 `POST_JOB_VALIDATE_FAIL`，仅记录安全上下文，例如 `mode`、`editingJobId`、`reason`、`field` 和必要的填写状态，不落表单原文。
- 请求开始前新增 `POST_JOB_SUBMIT_REQUEST_START`，用于标记真正进入发布/更新接口调用阶段。
- 请求失败时新增 `POST_JOB_SUBMIT_REQUEST_FAIL`，记录编辑态、模式和异常堆栈，便于本地排障。
- 上下文字段统一通过 `_buildPublishLogContext()` 生成，继续遵守脱敏、裁剪与频控链路，不输出岗位标题、地点、描述等表单原文。

### 3. 高价值测试

- 新增 `test/features/jobs/post_job_logging_test.dart`。
- 测试通过 `ActionLog + AppLogScope` 模拟真实页面点击入口，并直接读取 `AppLogger` 结构化日志文件断言：
  - 成功发布时，`POST_JOB_SUBMIT_TAP` 与 `POST_JOB_SUBMIT_REQUEST_START` 复用同一条 `traceId` 链路。
  - 校验失败时，只输出 `POST_JOB_VALIDATE_FAIL`，不会进入请求阶段。
  - 请求失败时，会输出 `POST_JOB_SUBMIT_REQUEST_START` 与 `POST_JOB_SUBMIT_REQUEST_FAIL`，且状态正确回落。

## 验证结果

### 测试

```bash
flutter test test/features/jobs/post_job_logging_test.dart
```

- 结果：通过

### 静态检查

```bash
flutter analyze lib/features/jobs/application/post_job/post_job_controller.dart lib/features/jobs/presentation/post_job_page.dart test/features/jobs/post_job_logging_test.dart
```

- 结果：`No issues found!`

### 诊断

- `post_job_controller.dart`：无诊断问题
- `post_job_page.dart`：无诊断问题
- `post_job_logging_test.dart`：无诊断问题

## 顾虑

- 单测运行时 `easy_localization` 会提示部分中文 key 未命中，这来自测试环境未完整挂载应用级翻译容器，不影响日志链路断言和业务代码行为。

## 2026-07-05 审查修复补充

### 本次修复范围

- 仅修改 `test/features/jobs/post_job_logging_test.dart`，未扩展到 Task 5 之外的文件。
- 生产代码保持本地排障模式、控制台与本地文件双写、详细日志保留且继续脱敏/裁剪/频控，不新增任何依赖。

### 修复内容

- 新增真实挂载 `PostJobPage` 的页面级测试，直接验证 `POST_JOB_PAGE_ENTER` 与 `POST_JOB_FIRST_FRAME` 各输出一次。
- 页面级测试校验了 `route`、`mode`、`isEdit`、`editingJobId` 等上下文字段，并使用编辑态 `jobId=99` 场景避免“只测 create 模式”的盲区。
- 成功发布、校验失败、请求失败三条既有链路测试改为读取结构化控制台日志块，避免 `testWidgets` 场景下文件刷盘时机波动带来的假阴性。
- 三条链路补充了高价值安全断言：确认日志中不存在 `title`、`countryOrCity`、`description` 等原始字段名，也不会泄露 `焊工`、`电工`、`德国`、`测试描述` 等表单原文。
- 三条链路同时确认仅保留 `titleFilled`、`locationFilled`、`headcountFilled`、`salaryRangeFilled`、`descriptionLength` 等安全摘要字段，满足审查对“脱敏但仍可排障”的要求。
- 测试收尾阶段对 `AppLogger.dispose()` 与临时目录删除做了容错，规避 `testWidgets` 结束时 `IOSink` 仍有写队列附着导致的清理期偶发异常。

### 本次验证

```bash
flutter test test/features/jobs/post_job_logging_test.dart
flutter analyze test/features/jobs/post_job_logging_test.dart lib/features/jobs/presentation/post_job_page.dart lib/features/jobs/application/post_job/post_job_controller.dart
```

- 结果：通过

### 本次顾虑

- 页面级测试为了稳定性改为断言结构化控制台输出，而非继续依赖 `testWidgets` 场景下的实时文件读取；这不影响“控制台+本地文件双写”的生产行为，但若后续 `PrettyPrinter` 输出格式变化，需要同步更新测试的日志块解析逻辑。
