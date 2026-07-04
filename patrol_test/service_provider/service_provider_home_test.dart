import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:europepass/shared/ui/test_keys.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../fixtures/service_provider_test_cases.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_reporter.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';
import '../helpers/service_provider_case_result_helper.dart';
import '../shared/patrol_test_types.dart';

void main() {
  test('服务商首页 - 首页交互结果应细化到交互点级别', () {
    expect(_homeFeatureLabel('home.quick_action.publish_package'), '发布套餐');
    expect(
      _homeTargetMatcher('home.quick_action.publish_package'),
      serviceProviderRouteMatchers['editVisaPackage'],
    );
  });

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
        await _returnToHome($, feature: definition.feature);
        // 每次返回后重新等待首页根节点稳定，避免后续点击命中旧页面动画。
        await waitForPageReady($, page: 'serviceProviderHome');
      }
    }
  });
}

/// 按功能点选择最稳定的返回方式，避免 iOS 自定义导航页卡在原生返回手势上。
Future<void> _returnToHome(
  PatrolIntegrationTester $, {
  required String feature,
}) async {
  switch (feature) {
    case 'home.quick_action.publish_package':
      // 编辑套餐页使用自定义返回按钮，优先点击业务返回键避免原生返回手势不稳定。
      await $(find.byKey(AppTestKeys.actionEditVisaPackageBack)).tap();
      return;
    default:
      await $.native.pressBack();
  }
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
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'route_mismatch',
      actualPrefix: '点击后未达到预期页面',
    );
  }
}

/// 根据首页功能点返回对应的点击文案，保持测试定义与页面文案解耦。
String _homeFeatureLabel(String feature) {
  switch (feature) {
    case 'home.quick_action.publish_package':
      return '发布套餐';
    case 'home.quick_action.order_management':
      return '订单处理';
    case 'home.quick_action.talent_center':
      return '人才中心';
    case 'home.quick_action.finance_settlement':
      return '财务结算';
  }
  throw ArgumentError.value(feature, 'feature', '未注册的服务商首页功能点');
}

/// 根据首页功能点返回目标页面 matcher，统一复用夹具中的路由定义。
PatrolRouteMatcher _homeTargetMatcher(String feature) {
  switch (feature) {
    case 'home.quick_action.publish_package':
      return serviceProviderRouteMatchers['editVisaPackage']!;
    case 'home.quick_action.order_management':
      return serviceProviderRouteMatchers['orderManagement']!;
    case 'home.quick_action.talent_center':
      return serviceProviderRouteMatchers['talentCenter']!;
    case 'home.quick_action.finance_settlement':
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
