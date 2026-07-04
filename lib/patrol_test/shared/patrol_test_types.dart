/// Patrol 用例执行状态。
enum PatrolCaseStatus { pass, fail, blocked }

/// Patrol 用例定义，用于描述页面功能点的基础信息。
class PatrolCaseDefinition {
  /// 创建 Patrol 用例定义。
  const PatrolCaseDefinition({
    required this.module,
    required this.page,
    required this.feature,
    required this.description,
    required this.precondition,
    required this.expected,
  });

  final String module;
  final String page;
  final String feature;
  final String description;
  final String precondition;
  final String expected;
}

/// Patrol 单个用例执行结果。
class PatrolCaseResult {
  /// 创建 Patrol 用例结果。
  const PatrolCaseResult({
    required this.module,
    required this.page,
    required this.feature,
    required this.description,
    required this.precondition,
    required this.expected,
    required this.actual,
    required this.status,
    required this.reason,
    required this.startedAt,
    required this.endedAt,
    this.screenshotPath,
  });

  final String module;
  final String page;
  final String feature;
  final String description;
  final String precondition;
  final String expected;
  final String actual;
  final PatrolCaseStatus status;
  final String reason;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? screenshotPath;

  /// 返回当前用例耗时，单位毫秒。
  int get durationMs => endedAt.difference(startedAt).inMilliseconds;

  /// 将结果序列化为 JSON 结构，供报告输出复用。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'module': module,
      'page': page,
      'feature': feature,
      'description': description,
      'precondition': precondition,
      'expected': expected,
      'actual': actual,
      'status': status.name.toUpperCase(),
      'reason': reason,
      'screenshotPath': screenshotPath,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationMs': durationMs,
    };
  }
}

/// Patrol 整体执行报告。
class PatrolRunReport {
  /// 创建 Patrol 执行报告。
  const PatrolRunReport({required this.results, required this.summary});

  final List<PatrolCaseResult> results;
  final Map<String, int> summary;

  /// 将整体报告序列化为 JSON 结构。
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'summary': summary,
      'results': results
          .map((result) => result.toJson())
          .toList(growable: false),
    };
  }
}
