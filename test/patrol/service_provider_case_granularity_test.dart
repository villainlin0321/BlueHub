import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/fixtures/service_provider_test_cases.dart';
import '../../patrol_test/helpers/service_provider_case_result_helper.dart';

/// 稳定验证服务商 Patrol 的交互点级结果命名，并确保 Patrol 文件只保留集成测试入口。
void main() {
  test('服务商 Patrol 文件不混用纯 test 与 patrolTest', () {
    final homeFile = _readRepoFile(
      'patrol_test/service_provider/service_provider_home_test.dart',
    );
    final meFile = _readRepoFile(
      'patrol_test/service_provider/service_provider_me_test.dart',
    );

    // 纯单测应迁到 test 目录，避免 flutter test 误触 Patrol 初始化链路。
    expect(_containsPureTest(homeFile), isFalse);
    expect(_containsPureTest(meFile), isFalse);
  });

  test('服务商首页用例使用 quick action 级别 feature 命名', () {
    expect(
      serviceProviderHomeCases.map((caseItem) => caseItem.feature).toList(),
      <String>[
        'home.quick_action.publish_package',
        'home.quick_action.order_management',
        'home.quick_action.talent_center',
        'home.quick_action.finance_settlement',
      ],
    );
  });

  test('服务商我的页用例使用 menu 级别 feature 命名', () {
    expect(
      serviceProviderMeCases.map((caseItem) => caseItem.feature).toList(),
      <String>[
        'me.menu.qualification_management',
        'me.menu.order_management',
        'me.menu.finance_settlement',
        'me.menu.settings',
      ],
    );
  });

  test('统一失败结果会透传交互点级 feature', () {
    final result = buildServiceProviderFailureResult(
      definition: serviceProviderHomeCases.first,
      startedAt: DateTime.parse('2026-07-05T02:00:00Z'),
      error: StateError('页面未跳转'),
      reason: 'route_mismatch',
      actualPrefix: '点击后未达到预期页面',
    );

    expect(result.feature, 'home.quick_action.publish_package');
    expect(result.reason, 'route_mismatch');
  });
}

/// 读取仓库内测试文件内容，供结构性约束断言复用。
String _readRepoFile(String relativePath) {
  return File(relativePath).readAsStringSync();
}

/// 判断文件是否仍包含纯单元测试定义，避免与 patrolTest 混在同一文件。
bool _containsPureTest(String content) {
  return RegExp(r'^\s*test\(', multiLine: true).hasMatch(content);
}
