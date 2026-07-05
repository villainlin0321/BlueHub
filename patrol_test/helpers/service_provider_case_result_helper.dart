import '../shared/patrol_test_types.dart';

/// 显式表示“前置条件不足”的信号词，仅命中这些文案时才允许记为阻塞。
const List<String> _qualificationBlockedSignals = <String>[
  '资料缺失',
  '前置条件不足',
  '暂无可选国家',
  '服务商测试账号未配置',
];

/// 构建服务商 Patrol 的统一失败结果，避免首页和“我的”页重复拼接失败原因。
PatrolCaseResult buildServiceProviderFailureResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required Object error,
  String reason = 'interaction_failed',
  String actualPrefix = '交互未达到预期',
}) {
  final String errorText = _stringifyError(error);

  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: '$actualPrefix：$errorText',
    status: PatrolCaseStatus.fail,
    reason: reason,
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}

/// 为资质管理场景构造失败结果，只在明确前置条件不足时输出 `BLOCKED`。
PatrolCaseResult buildQualificationManagementFailureResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required Object error,
}) {
  final String errorText = _stringifyError(error);
  final bool isBlocked = _qualificationBlockedSignals.any(errorText.contains);

  // 只有明确命中前置条件不足信号时才输出 BLOCKED，其余异常一律按 FAIL 记录。
  if (!isBlocked) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'qualification_unexpected_error',
      actualPrefix: '资质管理执行异常',
    );
  }

  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: '未进入资质认证流程，明确前置条件不足：$errorText',
    status: PatrolCaseStatus.blocked,
    reason: 'qualification_precondition_blocked',
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}

/// 统一把异常对象转成稳定字符串，便于测试断言与任务报告记录。
String _stringifyError(Object error) {
  return error.toString().trim();
}
