import 'package:europepass/app/router/app_router.dart';
import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import 'patrol_wait_helper.dart';

/// 确保当前用例处于服务商登录态，优先复用登录页现有“测试登录服务商”快捷入口。
Future<void> ensureServiceProviderAuthenticated(
  PatrolIntegrationTester $,
  ServiceProviderTestAccount account,
) async {
  final container = _readProviderContainer($);
  final authSession = container.read(authSessionProvider);
  if (authSession.isAuthenticated && !authSession.needSelectRole) {
    return;
  }

  // 读取当前路由，便于把异常信息限定在真正的登录入口场景中。
  final currentRoute = container.read(routerProvider).state.matchedLocation;
  if (currentRoute != RoutePaths.loginPhone) {
    throw StateError('当前不在登录页，无法执行服务商登录前置：$currentRoute');
  }

  try {
    // 优先走项目现有的测试快捷登录入口，减少对输入框结构的依赖。
    await $('测试登录服务商').tap();
  } catch (_) {
    if (!account.isValid) {
      throw StateError('服务商测试账号未配置，且当前页面缺少快捷登录入口');
    }

    // 兜底逻辑：切换到邮箱模式后手工输入 email + code。
    await $('邮箱').tap();
    await $(find.byType(EditableText).first).enterText(account.email);
    await $(find.byType(EditableText).last).enterText(account.code);
    await $('登录').tap();
  }

  await expectRouteReady(
    $,
    routePath: RoutePaths.home,
    fallbackFinder: find.text('首页'),
  );
}

/// 读取应用根节点对应的 Riverpod 容器，供 Patrol helper 访问共享状态。
ProviderContainer _readProviderContainer(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byKey(const Key('app-root')));
  return ProviderScope.containerOf(context, listen: false);
}
