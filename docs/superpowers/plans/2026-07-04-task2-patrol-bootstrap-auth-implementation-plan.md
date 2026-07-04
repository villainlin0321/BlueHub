# Task 2 Patrol Bootstrap Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Patrol 测试补齐应用启动、服务商登录前置、页面等待与路由匹配工具，并记录 Task2 交付结果。

**Architecture:** 通过一个纯数据的 `PatrolRouteMatcher` 承载路由与页面就绪锚点；通过 `patrol_wait_helper.dart` 统一等待页面；通过 `auth_test_helper.dart` 优先复用登录页现有“测试登录服务商”快捷入口，并在需要时支持 `email + code` 兜底；通过 `lib/main.dart` 抽取公共启动入口，让正式应用与 Patrol 复用同一初始化逻辑。

**Tech Stack:** Flutter, Dart, flutter_test, Patrol, Riverpod, GoRouter, EasyLocalization

## Global Constraints

- 按当前项目实际登录流实现，使用 `email + code`，优先复用“测试登录服务商”快捷入口。
- 不改业务登录逻辑，只新增或抽取测试辅助能力。
- 严格按 TDD 推进：先写测试，确认失败，再写最小实现。
- 所有新增函数必须补函数级中文注释，关键代码必须补简洁中文注释。
- 报告写入 `.superpowers/sdd/task-2-report.md`。

---

### Task 1: 路由匹配与等待基础

**Files:**
- Create: `test/patrol/patrol_route_matcher_test.dart`
- Create: `patrol_test/helpers/patrol_route_matcher.dart`
- Create: `patrol_test/helpers/patrol_wait_helper.dart`

**Interfaces:**
- Consumes:
  - `PatrolIntegrationTester`
  - `Finder`
- Produces:
  - `class PatrolRouteMatcher`
  - `Future<void> waitForPageReady(PatrolIntegrationTester $, {required String page})`
  - `Future<void> expectRouteReady(PatrolIntegrationTester $, {required String routePath, required Finder fallbackFinder})`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/patrol_test/helpers/patrol_route_matcher.dart';

void main() {
  test('路由匹配器会保存 routePath、readyKey 与 fallbackText', () {
    const matcher = PatrolRouteMatcher(
      routePath: '/order/management',
      readyKey: Key('page-order-management'),
      fallbackText: '订单管理',
    );

    expect(matcher.routePath, '/order/management');
    expect(matcher.readyKey, const Key('page-order-management'));
    expect(matcher.fallbackText, '订单管理');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: FAIL，提示 `PatrolRouteMatcher` 未定义或目标文件不存在

- [ ] **Step 3: 写最小实现**

```dart
// patrol_test/helpers/patrol_route_matcher.dart
import 'package:flutter/material.dart';

/// 描述一个路由在 Patrol 场景下如何判断“页面已就绪”。
class PatrolRouteMatcher {
  /// 创建路由匹配描述，支持优先用稳定 Key，再退回文本锚点。
  const PatrolRouteMatcher({
    required this.routePath,
    this.readyKey,
    this.fallbackText,
  });

  final String routePath;
  final Key? readyKey;
  final String? fallbackText;
}
```

```dart
// patrol_test/helpers/patrol_wait_helper.dart
import 'package:europepass/app/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_route_matcher.dart';

const Map<String, PatrolRouteMatcher> _pageMatchers = <String, PatrolRouteMatcher>{
  'home': PatrolRouteMatcher(
    routePath: RoutePaths.home,
    fallbackText: '首页',
  ),
};

/// 按页面别名等待目标页面完成渲染，避免在测试中直接写固定休眠。
Future<void> waitForPageReady(
  PatrolIntegrationTester $, {
  required String page,
}) async {
  final matcher = _pageMatchers[page];
  if (matcher == null) {
    throw ArgumentError.value(page, 'page', '未注册的 Patrol 页面别名');
  }
  await _waitByMatcher($, matcher);
}

/// 等待指定路由对应的关键元素出现，优先使用稳定 Key，失败时再依赖兜底 Finder。
Future<void> expectRouteReady(
  PatrolIntegrationTester $, {
  required String routePath,
  required Finder fallbackFinder,
}) async {
  final matcher = _pageMatchers.values.where((it) => it.routePath == routePath).firstOrNull;
  if (matcher?.readyKey != null) {
    await $(find.byKey(matcher!.readyKey!)).waitUntilVisible();
    return;
  }
  await $(fallbackFinder).waitUntilVisible();
}

/// 按 matcher 定义的优先级等待页面锚点出现。
Future<void> _waitByMatcher(
  PatrolIntegrationTester $,
  PatrolRouteMatcher matcher,
) async {
  if (matcher.readyKey != null) {
    await $(find.byKey(matcher.readyKey!)).waitUntilVisible();
    return;
  }
  if (matcher.fallbackText != null) {
    await $(matcher.fallbackText!).waitUntilVisible();
    return;
  }
  throw ArgumentError('matcher.readyKey 和 matcher.fallbackText 不能同时为空');
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: PASS

### Task 2: 启动器、登录前置与应用入口

**Files:**
- Create: `patrol_test/fixtures/service_provider_test_account.dart`
- Create: `patrol_test/helpers/app_bootstrap.dart`
- Create: `patrol_test/helpers/auth_test_helper.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app.dart`

**Interfaces:**
- Consumes:
  - `main()`
  - `RoutePaths`
  - `routerProvider`
  - `authSessionProvider`
- Produces:
  - `Future<void> bootstrapApplication()`
  - `Future<void> bootstrapPatrolApp(PatrolIntegrationTester $)`
  - `class ServiceProviderTestAccount`
  - `Future<void> ensureServiceProviderAuthenticated(PatrolIntegrationTester $, ServiceProviderTestAccount account)`

- [ ] **Step 1: 写失败测试**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: PASS，作为继续改动前的回归基线

- [ ] **Step 2: 写最小实现**

```dart
// patrol_test/fixtures/service_provider_test_account.dart
class ServiceProviderTestAccount {
  const ServiceProviderTestAccount({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  /// 从环境变量读取服务商测试账号，避免把真实数据写入仓库。
  static ServiceProviderTestAccount fromEnvironment() {
    return ServiceProviderTestAccount(
      email: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_EMAIL',
        defaultValue: '',
      ),
      code: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_CODE',
        defaultValue: '',
      ),
    );
  }

  /// 标记当前环境变量是否可用于手工兜底登录。
  bool get isValid => email.trim().isNotEmpty && code.trim().isNotEmpty;
}
```

```dart
// patrol_test/helpers/app_bootstrap.dart
import 'package:patrol/patrol.dart';

import 'package:europepass/main.dart' as app;

/// 启动真实应用入口，并等待首帧稳定，保证 Patrol 与正式启动流程一致。
Future<void> bootstrapPatrolApp(PatrolIntegrationTester $) async {
  await app.main();
  await $.pumpAndSettle();
}
```

```dart
// patrol_test/helpers/auth_test_helper.dart
import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/app/router/app_router.dart';
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

  final currentRoute = container.read(routerProvider).state.matchedLocation;
  if (currentRoute != RoutePaths.loginPhone) {
    await expectRouteReady(
      $,
      routePath: currentRoute,
      fallbackFinder: find.byKey(const Key('app-root')),
    );
  }

  final quickLoginButton = $('测试登录服务商');
  if (await quickLoginButton.visible) {
    await quickLoginButton.tap();
    await waitForPageReady($, page: 'home');
    return;
  }

  if (!account.isValid) {
    throw StateError('服务商测试账号未配置，且当前页面缺少快捷登录入口');
  }

  // 兜底逻辑：当快捷入口不存在时，切换到邮箱模式并手动输入账号信息。
  await $('邮箱').tap();
  await $(find.byType(EditableText).first).enterText(account.email);
  await $(find.byType(EditableText).last).enterText(account.code);
  await $('登录').tap();
  await waitForPageReady($, page: 'home');
}

/// 读取应用根节点对应的 Riverpod 容器，供 Patrol helper 访问共享状态。
ProviderContainer _readProviderContainer(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byKey(const Key('app-root')));
  return ProviderScope.containerOf(context, listen: false);
}
```

```dart
// lib/main.dart
/// 供正式启动与 Patrol 测试共用的应用初始化入口。
Future<void> bootstrapApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppLogger.instance.init();
  await PaymentLauncher.instance.initialize(
    config: PaymentChannelConfig.fromEnvironment(),
  );
}
```

```dart
// lib/app/app.dart
MaterialApp.router(
  key: const Key('app-root'),
```

- [ ] **Step 3: 运行测试确认通过**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: PASS

### Task 3: 报告、诊断与提交

**Files:**
- Create: `.superpowers/sdd/task-2-report.md`

**Interfaces:**
- Consumes:
  - `git status`
  - `flutter test test/patrol/patrol_route_matcher_test.dart`
  - `GetDiagnostics`
- Produces:
  - Task2 执行报告
  - git commit

- [ ] **Step 1: 写报告**

```md
# Task 2 Report

- 状态：完成
- 登录流：按项目实际使用 `email + code`，并优先复用“测试登录服务商”快捷入口
- TDD：先写 `test/patrol/patrol_route_matcher_test.dart`，确认失败后补最小实现
- 测试：
  - `flutter test test/patrol/patrol_route_matcher_test.dart`
- 提交：
  - `test(patrol): add bootstrap and auth helpers`
```

- [ ] **Step 2: 运行诊断与测试**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: PASS

- [ ] **Step 3: 提交**

```bash
git add lib/main.dart \
  lib/app/app.dart \
  patrol_test/helpers/app_bootstrap.dart \
  patrol_test/helpers/auth_test_helper.dart \
  patrol_test/helpers/patrol_wait_helper.dart \
  patrol_test/helpers/patrol_route_matcher.dart \
  patrol_test/fixtures/service_provider_test_account.dart \
  test/patrol/patrol_route_matcher_test.dart \
  .superpowers/sdd/task-2-report.md \
  docs/superpowers/plans/2026-07-04-task2-patrol-bootstrap-auth-implementation-plan.md
git commit -m "test(patrol): add bootstrap and auth helpers"
```
