import 'package:europepass/shared/ui/test_keys.dart';
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
  patrolTest('服务商我的 - 菜单入口与设置可达', ($) async {
    final reporter = PatrolReporter.memory();

    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    await $('我的').tap();
    await waitForPageReady($, page: 'serviceProviderMe');

    for (int index = 0; index < serviceProviderMeCases.length; index++) {
      final definition = serviceProviderMeCases[index];
      final result = await _runMeCase($, definition);
      await reporter.record(result);

      expect(
        _isAcceptedStatus(result, definition),
        isTrue,
        reason: '${definition.description} 未达到预期：${result.actual}',
      );

      if (_shouldReturnToMePage(result, definition, index)) {
        await $.native.pressBack();
        // 每次返回后重新等待“我的”页稳定，避免后续操作跑到上个页面。
        await waitForPageReady($, page: 'serviceProviderMe');
      }
    }
  });
}

/// 执行服务商“我的”页单个用例，资质管理按用户要求允许记为阻塞。
Future<PatrolCaseResult> _runMeCase(
  PatrolIntegrationTester $,
  PatrolCaseDefinition definition,
) async {
  final startedAt = DateTime.now();

  try {
    switch (definition.feature) {
      case 'qualification_management':
        await $('资质管理').tap();
        await _waitForMatcher(
          $,
          serviceProviderRouteMatchers['qualificationCertification']!,
        );
        break;
      case 'order_management':
        await $('订单管理').tap();
        await _waitForMatcher(
          $,
          serviceProviderRouteMatchers['orderManagement']!,
        );
        break;
      case 'finance_settlement':
        await $('财务结算').tap();
        await _waitForMatcher(
          $,
          serviceProviderRouteMatchers['financeSettlement']!,
        );
        break;
      case 'settings':
        await $(find.byKey(AppTestKeys.actionServiceProviderMeSettings)).tap();
        await _waitForMatcher($, serviceProviderRouteMatchers['settings']!);
        break;
      default:
        throw ArgumentError.value(definition.feature, 'feature', '未注册的我的页功能点');
    }

    return PatrolCaseResult(
      module: definition.module,
      page: definition.page,
      feature: definition.feature,
      description: definition.description,
      precondition: definition.precondition,
      expected: definition.expected,
      actual: '成功完成${definition.description}可达性验证',
      status: PatrolCaseStatus.pass,
      reason: 'ok',
      startedAt: startedAt,
      endedAt: DateTime.now(),
    );
  } catch (error) {
    if (definition.feature == 'qualification_management') {
      return PatrolCaseResult(
        module: definition.module,
        page: definition.page,
        feature: definition.feature,
        description: definition.description,
        precondition: definition.precondition,
        expected: definition.expected,
        actual: '未进入资质认证流程，按资料或接口阻塞处理：$error',
        status: PatrolCaseStatus.blocked,
        reason: 'profile_or_api_blocked',
        startedAt: startedAt,
        endedAt: DateTime.now(),
      );
    }

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

/// 校验当前结果是否符合 Task3 的验收口径。
bool _isAcceptedStatus(
  PatrolCaseResult result,
  PatrolCaseDefinition definition,
) {
  if (definition.feature == 'qualification_management') {
    return result.status == PatrolCaseStatus.pass ||
        result.status == PatrolCaseStatus.blocked;
  }
  return result.status == PatrolCaseStatus.pass;
}

/// 仅在实际已跳转到子页面且后续仍有用例待执行时返回上一页。
bool _shouldReturnToMePage(
  PatrolCaseResult result,
  PatrolCaseDefinition definition,
  int index,
) {
  if (index >= serviceProviderMeCases.length - 1) {
    return false;
  }
  if (definition.feature == 'qualification_management') {
    return result.status == PatrolCaseStatus.pass;
  }
  return result.status == PatrolCaseStatus.pass;
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
