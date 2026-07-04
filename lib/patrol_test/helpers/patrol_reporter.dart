import 'dart:convert';
import 'dart:io';

import '../shared/patrol_test_types.dart';

const Map<String, String> _pageTitles = <String, String>{
  'home': '服务商首页',
  'jobs': '服务商套餐管理',
  'visa': '服务商签证页',
  'me': '服务商我的',
};

const Map<String, String> _featureTitles = <String, String>{
  'publish_package': '发布套餐',
  'order_management': '订单处理',
  'talent_center': '人才中心',
  'finance_settlement': '财务结算',
  'qualification_management': '资质管理',
  'settings': '设置',
};

/// Patrol 报告的内存输出结果，供测试直接断言。
class PatrolReporterOutputs {
  /// 创建内存输出结果。
  const PatrolReporterOutputs({required this.markdown, required this.json});

  final String markdown;
  final String json;
}

/// Patrol 报告器，负责汇总单个用例结果并输出到内存或文件。
class PatrolReporter {
  /// 创建 Patrol 报告器。
  PatrolReporter({
    required this.reportDirectory,
    List<PatrolCaseResult>? seedResults,
  }) : _results = seedResults ?? <PatrolCaseResult>[];

  /// 创建仅用于测试断言的内存报告器。
  factory PatrolReporter.memory() {
    return PatrolReporter(
      reportDirectory: Directory.systemTemp.createTempSync('patrol-reports'),
    );
  }

  final Directory reportDirectory;
  final List<PatrolCaseResult> _results;

  /// 记录单个 Patrol 用例结果。
  Future<void> record(PatrolCaseResult result) async {
    _results.add(result);
  }

  /// 生成内存中的 markdown 与 json，供单元测试直接断言。
  Future<PatrolReporterOutputs> flushToMemory() async {
    final report = _buildRunReport();
    return PatrolReporterOutputs(
      markdown: _buildMarkdown(report.results),
      json: jsonEncode(report.toJson()),
    );
  }

  /// 将报告输出到目标目录，供后续自动化任务复用。
  Future<void> flush() async {
    await reportDirectory.create(recursive: true);
    final outputs = await flushToMemory();

    // 使用固定文件名，便于后续任务直接读取 latest 目录。
    await File(
      '${reportDirectory.path}/service_provider_report.md',
    ).writeAsString(outputs.markdown);
    await File(
      '${reportDirectory.path}/service_provider_report.json',
    ).writeAsString(outputs.json);
  }

  /// 构建带统计摘要的整体执行报告。
  PatrolRunReport _buildRunReport() {
    final passCount = _results
        .where((result) => result.status == PatrolCaseStatus.pass)
        .length;
    final failCount = _results
        .where((result) => result.status == PatrolCaseStatus.fail)
        .length;
    final blockedCount = _results
        .where((result) => result.status == PatrolCaseStatus.blocked)
        .length;

    return PatrolRunReport(
      results: List<PatrolCaseResult>.unmodifiable(_results),
      summary: <String, int>{
        'pass': passCount,
        'fail': failCount,
        'blocked': blockedCount,
      },
    );
  }

  /// 生成面向业务的 Markdown 摘要。
  String _buildMarkdown(List<PatrolCaseResult> results) {
    final buffer = StringBuffer('# 服务商模块自动化验收报告\n\n');
    final groupedResults = <String, List<PatrolCaseResult>>{};

    for (final result in results) {
      groupedResults
          .putIfAbsent(result.page, () => <PatrolCaseResult>[])
          .add(result);
    }

    for (final entry in groupedResults.entries) {
      final page = entry.key;
      final pageResults = entry.value;
      buffer.writeln('## ${_pageTitles[page] ?? page}');

      for (final result in pageResults) {
        final featureTitle = _resolveFeatureTitle(result);
        buffer.writeln(
          '- $featureTitle | ${result.status.name.toUpperCase()} | ${result.actual}',
        );
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 根据 feature 优先生成业务展示名，缺省时回退到 description。
  String _resolveFeatureTitle(PatrolCaseResult result) {
    return _featureTitles[result.feature] ?? result.description;
  }
}
