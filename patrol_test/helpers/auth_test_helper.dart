import 'package:europepass/app/router/app_router.dart';
import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/features/auth/application/auth_role_mapper.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';
import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import 'patrol_wait_helper.dart';

/// 确保当前用例处于求职者登录态，优先复用登录页现有“测试登录求职者”快捷入口。
Future<void> ensureJobSeekerAuthenticated(PatrolIntegrationTester $) async {
  final container = readAppProviderContainer($);
  final authSession = container.read(authSessionProvider);
  if (isJobSeekerAuthenticatedSession(authSession)) {
    return;
  }
  if (authSession.isAuthenticated && !authSession.needSelectRole) {
    throw StateError('当前登录态不是求职者角色：${authSession.user?.role ?? 'unknown'}');
  }

  final currentRoute = safeReadCurrentRoute(
    fallbackLocation: RoutePaths.loginPhone,
    readLocation: () => container.read(routerProvider).state.uri.toString(),
  );
  if (currentRoute != RoutePaths.loginPhone) {
    throw StateError('当前不在登录页，无法执行求职者登录前置：$currentRoute');
  }

  await $(find.byKey(AppTestKeys.loginTestJobSeekerButton)).tap();
  await waitForPageReady($, page: 'jobSeekerHome');
  _assertJobSeekerSession(container.read(authSessionProvider));
}

/// 确保当前用例处于服务商登录态，优先复用登录页现有“测试登录服务商”快捷入口。
Future<void> ensureServiceProviderAuthenticated(
  PatrolIntegrationTester $,
  ServiceProviderTestAccount account,
) async {
  final container = readAppProviderContainer($);
  final authSession = container.read(authSessionProvider);
  if (isServiceProviderAuthenticatedSession(authSession)) {
    return;
  }
  if (authSession.isAuthenticated && !authSession.needSelectRole) {
    throw StateError('当前登录态不是服务商角色：${authSession.user?.role ?? 'unknown'}');
  }

  // 安全读取当前路由，避免 go_router 首轮匹配未完成时直接抛出 StateError。
  final currentRoute = safeReadCurrentRoute(
    fallbackLocation: RoutePaths.loginPhone,
    readLocation: () => container.read(routerProvider).state.uri.toString(),
  );
  if (currentRoute != RoutePaths.loginPhone) {
    throw StateError('当前不在登录页，无法执行服务商登录前置：$currentRoute');
  }

  final quickLoginButton = $(
    find.byKey(AppTestKeys.loginTestServiceProviderButton),
  );
  if (quickLoginButton.visible) {
    // 优先走稳定 Key 对应的测试快捷登录入口，避免依赖中文文案。
    await quickLoginButton.tap();
  } else {
    if (!account.isValid) {
      throw StateError('服务商测试账号未配置，且当前页面缺少快捷登录入口');
    }

    // 兜底逻辑：切换到邮箱模式后手工输入 email + code。
    await $('邮箱').tap();
    await $(find.byType(EditableText).first).enterText(account.email);
    await $(find.byType(EditableText).last).enterText(account.code);
    await $('登录').tap();
  }

  await waitForPageReady($, page: 'serviceProviderHome');
  _assertServiceProviderSession(container.read(authSessionProvider));
}

/// 读取应用根节点对应的 Riverpod 容器，供 Patrol helper 访问共享状态。
ProviderContainer readAppProviderContainer(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byKey(const Key('app-root')));
  return ProviderScope.containerOf(context, listen: false);
}

/// 判断当前会话是否已经是可复用的服务商登录态。
bool isServiceProviderAuthenticatedSession(AuthSessionState authSession) {
  final role = authSession.user?.role.trim() ?? '';
  return authSession.isAuthenticated &&
      !authSession.needSelectRole &&
      role == visaProviderRoleId;
}

/// 判断当前会话是否已经是可复用的求职者登录态。
bool isJobSeekerAuthenticatedSession(AuthSessionState authSession) {
  final role = authSession.user?.role.trim() ?? '';
  return authSession.isAuthenticated &&
      !authSession.needSelectRole &&
      role != visaProviderRoleId &&
      role != employerRoleId;
}

/// 在登录流程结束后再次校验角色，避免误复用到企业或求职者会话。
void _assertServiceProviderSession(AuthSessionState authSession) {
  if (isServiceProviderAuthenticatedSession(authSession)) {
    return;
  }
  throw StateError('服务商登录完成后角色校验失败：${authSession.user?.role ?? 'unknown'}');
}

/// 在登录流程结束后再次校验角色，避免误复用到企业或服务商会话。
void _assertJobSeekerSession(AuthSessionState authSession) {
  if (isJobSeekerAuthenticatedSession(authSession)) {
    return;
  }
  throw StateError('求职者登录完成后角色校验失败：${authSession.user?.role ?? 'unknown'}');
}

/// 安全读取当前路由；若路由状态尚未就绪，则回退到调用方提供的默认地址。
String safeReadCurrentRoute({
  required String fallbackLocation,
  required String Function() readLocation,
}) {
  try {
    return readLocation();
  } on StateError {
    return fallbackLocation;
  }
}
