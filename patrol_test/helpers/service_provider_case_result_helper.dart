import '../shared/patrol_test_types.dart';

/// 显式表示“前置条件不足”的信号词，仅命中这些文案时才允许记为阻塞。
const List<String> _qualificationBlockedSignals = <String>[
  '资料缺失',
  '前置条件不足',
  '暂无可选国家',
  '服务商测试账号未配置',
];

/// 为资质管理场景构造失败结果，只在明确前置条件不足时输出 `BLOCKED`。
PatrolCaseResult buildQualificationManagementFailureResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required Object error,
}) {
  final String errorText = _stringifyError(error);
  final bool isBlocked = _qualificationBlockedSignals.any(errorText.contains);

  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: isBlocked ? '未进入资质认证流程，明确前置条件不足：$errorText' : '资质管理执行异常：$errorText',
    status: isBlocked ? PatrolCaseStatus.blocked : PatrolCaseStatus.fail,
    reason: isBlocked
        ? 'qualification_precondition_blocked'
        : 'qualification_unexpected_error',
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}

/// 统一把异常对象转成稳定字符串，便于测试断言与任务报告记录。
String _stringifyError(Object error) {
  return error.toString().trim();
}
