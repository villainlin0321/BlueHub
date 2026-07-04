import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../fixtures/service_provider_test_cases.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_reporter.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';
import '../shared/patrol_test_types.dart';

void main() {
  patrolTest('服务商首页 - 快捷入口全部可达', ($) async {
    final reporter = PatrolReporter.memory();

    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );
    await waitForPageReady($, page: 'serviceProviderHome');

    for (int index = 0; index < serviceProviderHomeCases.length; index++) {
      final definition = serviceProviderHomeCases[index];
      final result = await _runHomeCase($, definition);
      await reporter.record(result);

      expect(
        result.status,
        PatrolCaseStatus.pass,
        reason: '${definition.description} 未通过：${result.actual}',
      );

      if (index < serviceProviderHomeCases.length - 1) {
        await $.native.pressBack();
        // 每次返回后重新等待首页根节点稳定，避免后续点击命中旧页面动画。
        await waitForPageReady($, page: 'serviceProviderHome');
      }
    }
  });
}

/// 执行单个首页快捷入口用例，并把跳转结果转换为统一的报告结构。
Future<PatrolCaseResult> _runHomeCase(
  PatrolIntegrationTester $,
  PatrolCaseDefinition definition,
) async {
  final startedAt = DateTime.now();

  try {
    await $(_homeFeatureLabel(definition.feature)).tap();
    await _waitForMatcher($, _homeTargetMatcher(definition.feature));

    return PatrolCaseResult(
      module: definition.module,
      page: definition.page,
      feature: definition.feature,
      description: definition.description,
      precondition: definition.precondition,
      expected: definition.expected,
      actual: '成功${definition.expected}',
      status: PatrolCaseStatus.pass,
      reason: 'ok',
      startedAt: startedAt,
      endedAt: DateTime.now(),
    );
  } catch (error) {
    return PatrolCaseResult(
      module: definition.module,
      page: definition.page,
      feature: definition.feature,
      description: definition.description,
      precondition: definition.precondition,
      expected: definition.expected,
      actual: '点击后未达到预期页面：$error',
      status: PatrolCaseStatus.fail,
      reason: 'route_mismatch',
      startedAt: startedAt,
      endedAt: DateTime.now(),
    );
  }
}

/// 根据首页功能点返回对应的点击文案，保持测试定义与页面文案解耦。
String _homeFeatureLabel(String feature) {
  switch (feature) {
    case 'publish_package':
      return '发布套餐';
    case 'order_management':
      return '订单处理';
    case 'talent_center':
      return '人才中心';
    case 'finance_settlement':
      return '财务结算';
  }
  throw ArgumentError.value(feature, 'feature', '未注册的服务商首页功能点');
}

/// 根据首页功能点返回目标页面 matcher，统一复用夹具中的路由定义。
PatrolRouteMatcher _homeTargetMatcher(String feature) {
  switch (feature) {
    case 'publish_package':
      return serviceProviderRouteMatchers['editVisaPackage']!;
    case 'order_management':
      return serviceProviderRouteMatchers['orderManagement']!;
    case 'talent_center':
      return serviceProviderRouteMatchers['talentCenter']!;
    case 'finance_settlement':
      return serviceProviderRouteMatchers['financeSettlement']!;
  }
  throw ArgumentError.value(feature, 'feature', '未注册的服务商首页目标页面');
}

/// 按统一 matcher 定义等待路由就绪，优先复用 Task2 已完成的等待 helper。
Future<void> _waitForMatcher(
  PatrolIntegrationTester $,
  PatrolRouteMatcher matcher,
) async {
  await expectRouteReady(
    $,
    routePath: matcher.routePath,
    fallbackFinder: matcher.readyKey != null
        ? find.byKey(matcher.readyKey!)
        : find.text(matcher.fallbackText!),
  );
}
