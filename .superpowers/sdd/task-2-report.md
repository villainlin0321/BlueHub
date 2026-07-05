状态：已完成

修改文件：
- `lib/features/auth/presentation/qualification_certification_step_three_page.dart`
- `test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
- `.superpowers/sdd/task-2-report.md`

测试命令与结果：
- `flutter test test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
  - 首次运行失败：测试基座缺少 `SharedPreferences` mock，补齐后重新执行
  - 最终结果：通过，`All tests passed!`

提交哈希(若有)：
- 无

concerns：
- `qualification_certification_step_three_page.dart` 在任务开始前已有本地改动，本次仅在现有文件基础上做最小增量接线，未回退或覆盖无关内容。
- 该 widget test 运行时会输出若干 `easy_localization` 的缺失 key warning，但不影响本任务新增的返回拦截行为验证；本次未扩展处理翻译资源问题。

---

状态：已完成

修改文件：
- `lib/features/auth/presentation/qualification_certification_step_three_page.dart`
- `test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
- `.superpowers/sdd/task-2-report.md`

测试命令与结果：
- `flutter test test/features/auth/presentation/qualification_certification_step_three_page_test.dart`
  - 结果：通过，`3` 个 widget test 全部通过，`All tests passed!`

concerns：
- 本次对页面逻辑只做了 Task2 相关的最小修复：确认退出后先通过 `setState` 刷新 `PopScope.canPop`，再等待下一帧执行真实 `pop`，避免同一帧被再次拦截。
- 新增测试已覆盖系统返回触发确认框，以及系统返回后点击“确定”的真实离页链路；但 widget test 仍无法完全替代设备级返回手势/系统导航的端到端验证。
- 测试运行中依旧会出现若干 `easy_localization` 缺失 key warning，本次未扩展处理翻译资源问题。
