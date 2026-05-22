---
name: "bluehub-page-architecture"
description: "统一 BlueHub Flutter 页面分层规范（Page/View + Riverpod Controller/State）。当新增页面、重构页面或需要拆分 UI 与业务逻辑时调用。"
---

# BlueHub Page Architecture

## 目的

为 BlueHub Flutter 页面提供统一的开发框架，确保后续新增页面、重构页面、拆分复杂页面时都遵循一致的目录结构、职责边界、状态管理和 UI 组织方式。

这套规范特别适用于：

- 需要把页面布局与业务逻辑拆开的页面
- 需要表单、标签、列表、异步加载、提交发布等交互的页面
- 需要与 API 对接并保持可维护性的页面

## 何时调用

- 新增一个功能页面，需要先搭页面骨架时
- 现有页面逻辑堆在 `StatefulWidget` / `build()` 中，需要重构时
- 页面包含接口加载、表单校验、提交、反馈提示、跳转等完整交互时
- 想确认当前实现是否符合 BlueHub 既有分层规范时

## 总体原则

- 页面结构优先遵循：`presentation` 负责展示，`application` 负责业务状态与交互编排，`data` 负责接口与模型
- UI 和业务逻辑必须分离：Widget 不直接承担复杂校验、请求拼装、接口调用
- 页面容器要尽量薄：只做控制器持有、provider 监听、页面生命周期处理、导航和消息展示
- 纯展示组件保持无副作用：通过参数渲染，通过回调上抛事件
- 表单输入控制器属于页面层，不下沉到 Riverpod state
- 可序列化、可测试、可复用的状态放到 `State` 中，由 `Notifier` 管理

## 推荐目录结构

以 `features/<feature>/` 为单位，优先采用如下结构：

```text
features/<feature>/
  application/
    <page_name>/
      <page_name>_controller.dart
      <page_name>_state.dart
  data/
    <feature>_models.dart
    <feature>_service.dart
    <feature>_providers.dart
  presentation/
    <page_name>.dart
    <page_name>_styles.dart
    widgets/
      <page_name>_view.dart
      <sub_section_widgets>.dart
```

例如岗位发布页：

```text
features/jobs/
  application/
    post_job/
      post_job_controller.dart
      post_job_state.dart
  data/
    job_models.dart
    job_service.dart
    job_providers.dart
  presentation/
    post_job_page.dart
    post_job_page_styles.dart
    widgets/
      post_job_page_view.dart
      post_job_form_widgets.dart
```

## 各层职责

### `presentation/<page>.dart`

页面容器，建议保留为 `ConsumerStatefulWidget` 当页面需要：

- `TextEditingController`
- `FocusNode`
- `AnimationController`
- 生命周期触发首次加载

容器页只负责：

- 创建和释放输入控制器
- 在 `initState` 触发首次加载
- 使用 `ref.listen` 监听一次性副作用
- 处理 `SnackBar`、`Dialog`、路由跳转
- 收集输入值，构造成轻量表单草稿对象
- 将 state 和回调传给 view

不应在容器页中直接编写：

- 接口调用
- 请求体拼装
- 复杂校验
- 业务状态切换
- 大量 UI 细节渲染

### `application/<page>/<page>_controller.dart`

业务逻辑入口，推荐使用：

```dart
final xxxControllerProvider =
    NotifierProvider<XxxController, XxxState>(XxxController.new);
```

Controller 负责：

- 调用 service / provider
- 维护页面业务状态
- 处理标签切换、选项切换、加载、重试、提交
- 表单业务校验
- 拼装 BO / 请求对象
- 触发一次性反馈消息和提交成功标记

Controller 不负责：

- 直接操作 `TextEditingController`
- 直接调用 `ScaffoldMessenger`
- 直接做导航
- 直接拼 Widget

### `application/<page>/<page>_state.dart`

状态对象负责存放：

- 当前选项值
- 异步加载状态
- 提交状态
- 数据列表
- 错误文案
- 一次性反馈消息
- 成功事件计数器

推荐设计：

- 使用不可变对象
- 提供 `copyWith`
- 对可空字段使用 sentinel 处理清空逻辑
- 把“一次性事件”设计为 `feedbackId` / `successId` 这类递增标记

### `presentation/widgets/<page>_view.dart`

纯展示组件，负责：

- 页面布局
- Section 组织
- 表单控件拼装
- loading / empty / error 的视图表现

View 的约束：

- 不直接读取 provider
- 不直接调用 service
- 不直接写业务判断
- 不直接做路由和 snackbar

## 输入与状态边界

BlueHub 页面推荐这样划分输入状态：

### 放在页面层的内容

- `TextEditingController`
- `FocusNode`
- 本地动画对象

原因：

- 它们依赖 Flutter Widget 生命周期
- 不适合放进 Riverpod 的纯状态对象中

### 放在 Riverpod state 的内容

- 当前选中的标签
- 当前选中的单选项
- 已添加的自定义标签
- 接口返回的数据列表
- 加载中 / 提交中
- 错误文案
- 提交成功事件

## 页面布局拆分建议

复杂页面不要把全部 UI 写在一个 `build()` 中，建议按层拆：

1. 页面容器：`post_job_page.dart`
2. 页面视图：`post_job_page_view.dart`
3. 复用表单组件：`post_job_form_widgets.dart`
4. 如果一个 section 超过约 80-120 行，再继续拆成：
   - `basic_info_section.dart`
   - `requirement_section.dart`
   - `description_section.dart`

拆分判断标准：

- 一个 widget 同时包含布局、接口态、交互态、列表映射时，应继续拆
- 同一个 section 在多个页面复用时，应独立成 widget
- 同一份样式逻辑在多个控件重复时，应抽公共组件

## 页面交互模式

推荐统一采用下面的交互约定：

### 首次加载

- 在 `initState()` 中触发 `controller.loadXxx()`
- 页面通过 `ref.watch()` 渲染加载态
- 重试操作由 view 回调到 controller

### 一次性提示

- controller 只发出 `feedbackMessage + feedbackId`
- page 容器通过 `ref.listen()` 监听并展示 `SnackBar`
- 展示完成后调用 `clearFeedback()`

### 成功跳转

- controller 只更新 `publishSuccessId` / `submitSuccessId`
- page 容器通过 `ref.listen()` 响应成功事件并跳转
- 不在 controller 内直接 `go` / `pop`

### 表单提交

- page 先从 `TextEditingController` 收集文本
- 组装成 `FormDraft` 之类的轻量对象
- 调用 `controller.submit(draft)` / `controller.publish(draft)`
- controller 内完成校验和 BO 拼装

## 请求拼装规范

接口请求体的组装放在 controller 中，不放在页面里。

推荐模式：

1. 页面只收集原始输入
2. controller 校验输入合法性
3. controller 将原始输入转换为 API 需要的数据结构
4. controller 调用 service 完成提交

例如：

- 页面拿到文本输入 `title`、`country`、`salary`
- controller 转换成 `CreateJobBO`
- 选中的系统标签传编码值
- 自定义标签传文本列表

## UI 规范

- 样式常量集中放在 `<page>_styles.dart`
- 通用输入组件、Section 卡片、单选项、标签 chip 放在 `presentation/widgets/`
- 页面 view 不直接写魔法数字，优先复用 styles 常量
- loading、empty、error 要有明确的展示，不要只有空白页
- 提交按钮在提交中状态下禁用，并显示 loading

## 推荐代码模板

### Page 容器模板

```dart
class XxxPage extends ConsumerStatefulWidget {
  const XxxPage({super.key});

  @override
  ConsumerState<XxxPage> createState() => _XxxPageState();
}

class _XxxPageState extends ConsumerState<XxxPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(xxxControllerProvider.notifier).loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<XxxState>(xxxControllerProvider, (previous, next) {
      // snackbar / dialog / navigation
    });

    final state = ref.watch(xxxControllerProvider);
    final controller = ref.read(xxxControllerProvider.notifier);

    return XxxPageView(
      nameController: _nameController,
      state: state,
      onSubmit: () {
        controller.submit(
          XxxFormDraft(name: _nameController.text),
        );
      },
    );
  }
}
```

### Controller 模板

```dart
final xxxControllerProvider =
    NotifierProvider<XxxController, XxxState>(XxxController.new);

class XxxController extends Notifier<XxxState> {
  @override
  XxxState build() => const XxxState();

  Future<void> loadInitialData() async {}

  Future<void> submit(XxxFormDraft draft) async {}
}
```

### State 模板

```dart
class XxxState {
  const XxxState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackId = 0,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? feedbackMessage;
  final int feedbackId;

  XxxState copyWith(...) { ... }
}
```

## 反模式

以下写法应避免：

- 在 `build()` 里直接发请求
- 在页面 Widget 中拼接复杂请求体
- 在 `StatefulWidget` 里堆大量校验逻辑
- 在 controller 里直接调用 `Navigator`
- 在 view 中直接 `ref.read(serviceProvider)`
- 把 `TextEditingController` 放进 Riverpod state
- 把所有 UI 都堆在单个页面文件中超过数百行

## 验收清单

写完一个页面后，至少检查：

- 页面容器是否足够薄
- view 是否只负责渲染
- controller 是否承担了业务逻辑
- state 是否表达完整页面状态
- 输入控制器是否仍留在页面层
- 一次性反馈是否通过 `ref.listen` 处理
- 提交请求体是否由 controller 统一拼装
- loading / empty / error / submitting 是否完整
- 文件命名和目录结构是否符合本规范

## 适用于岗位发布页的参考结论

岗位发布页已经验证了这套结构的可用性：

- `post_job_page.dart` 作为容器页
- `post_job_controller.dart` 处理标签加载、表单校验、请求组装、发布
- `post_job_state.dart` 承载选中项、标签列表、提交态、反馈态
- `post_job_page_view.dart` 只承接布局和参数渲染

后续新增类似“创建资料”“发布服务”“编辑简历”“编辑企业信息”页面时，优先直接复用这套模式。
