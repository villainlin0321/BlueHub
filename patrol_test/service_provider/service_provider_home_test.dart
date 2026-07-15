import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../fixtures/service_provider_test_cases.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  for (final definition in serviceProviderHomeCases) {
    patrolTest('服务商首页 - ${definition.description} 可达', ($) async {
      await bootstrapPatrolApp($);
      await ensureServiceProviderAuthenticated(
        $,
        ServiceProviderTestAccount.fromEnvironment(),
      );
      await waitForPageReady($, page: 'serviceProviderHome');

      await $(_homeFeatureLabel(definition.feature)).tap();
      await _waitForMatcher($, _homeTargetMatcher(definition.feature));
    });
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
