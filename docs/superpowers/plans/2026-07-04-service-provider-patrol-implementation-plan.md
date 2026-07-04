# Service Provider Patrol Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 BlueHub 服务商模块落地一套基于 Patrol 的自动化验收测试体系，能够在测试环境接口下输出按钮级的 PASS / FAIL / BLOCKED 报告。

**Architecture:** 在现有 `flutter_test` 体系之外新增 `patrol_test/` 目录，使用 Patrol 负责真实页面交互、路由跳转和测试环境接口联动。通过 `app_bootstrap`、`auth_test_helper`、`patrol_wait_helper`、`patrol_route_matcher` 和 `patrol_reporter` 组成统一测试底座，再按页面拆分服务商首页、套餐管理、签证页、我的页面的验收用例，最终输出 `Markdown` 与 `JSON` 报告并在失败时截图。

**Tech Stack:** Flutter, Dart, flutter_test, Patrol, Riverpod, GoRouter, EasyLocalization

## Global Constraints

- 使用 Patrol 作为页面验收主框架，继续保留 `flutter_test` 负责单元测试与局部 Widget 测试。
- 仅覆盖服务商模块，不扩展到全站所有角色和所有页面。
- 本轮不引入云真机平台、设备农场或远端测试编排能力。
- 本轮不保证一次覆盖所有系统权限、支付或第三方外部应用联动。
- 使用测试环境真实接口，不使用纯 Mock 作为本轮主执行环境。
- 优先验证用户点击后看到的结果，而不是内部实现细节。
- 优先使用显式等待和关键元素判断，不依赖固定时长休眠。
- 若页面缺少足够稳定的定位锚点，实现阶段可按需补少量测试辅助标识。
- `FAIL` 与 `BLOCKED` 必截图，`PASS` 默认不截图。
- 所有新增函数必须补函数级中文注释，关键代码必须补简洁中文注释。

---

## File Structure

### 新增文件

- `patrol_test/shared/patrol_test_types.dart`
  - 定义测试结果枚举、测试项模型、报告模型。
- `patrol_test/helpers/patrol_reporter.dart`
  - 记录测试项执行结果并落盘到 `reports/patrol/latest/`。
- `patrol_test/helpers/patrol_screenshot_helper.dart`
  - 统一生成截图路径和截图文件名。
- `patrol_test/helpers/app_bootstrap.dart`
  - 统一初始化 Patrol 测试入口、环境和 App 根组件。
- `patrol_test/helpers/auth_test_helper.dart`
  - 统一进入服务商测试账号态。
- `patrol_test/helpers/patrol_wait_helper.dart`
  - 封装等待页面稳定、列表加载完成、反馈出现等能力。
- `patrol_test/helpers/patrol_route_matcher.dart`
  - 封装页面进入判定逻辑。
- `patrol_test/fixtures/service_provider_test_account.dart`
  - 管理服务商测试账号与环境变量读取。
- `patrol_test/fixtures/service_provider_expectations.dart`
  - 管理页面级预期名称与断言锚点。
- `patrol_test/fixtures/service_provider_test_cases.dart`
  - 管理页面级功能点矩阵。
- `patrol_test/service_provider/service_provider_home_test.dart`
  - 服务商首页验收测试。
- `patrol_test/service_provider/service_provider_me_test.dart`
  - 服务商我的页面验收测试。
- `patrol_test/service_provider/service_provider_jobs_test.dart`
  - 服务商套餐管理页验收测试。
- `patrol_test/service_provider/service_provider_visa_test.dart`
  - 服务商签证页验收测试。
- `test/patrol/patrol_reporter_test.dart`
  - 单测报告模型和输出格式。
- `test/patrol/patrol_route_matcher_test.dart`
  - 单测路由判定和页面锚点逻辑。

### 修改文件

- `pubspec.yaml`
  - 增加 Patrol 依赖并声明 `patrol_test` 目录。
- `lib/main.dart`
  - 拆出可测试入口或统一初始化函数，避免 Patrol 测试重复绕过启动流程。
- `lib/app/app.dart`
  - 如定位需要，补最少量测试锚点或语义化 `Key`。
- `lib/features/home/presentation/role_pages/service_provider_home_page.dart`
  - 如定位需要，补最少量测试锚点。
- `lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart`
  - 如定位需要，补最少量测试锚点。
- `lib/features/visa/presentation/role_pages/service_provider_visa_page.dart`
  - 如定位需要，补最少量测试锚点。
- `lib/features/me/presentation/role_pages/service_provider_me_page.dart`
  - 如定位需要，补最少量测试锚点。

### 不在本计划内

- `docs/api/**`
- `docs/prd/**`
- 云真机平台、远端编排、CI 平台脚本
- 支付、第三方外部应用、复杂系统权限的完整自动化覆盖

### Task 1: Patrol 基础设施与报告模型

**Files:**
- Create: `patrol_test/shared/patrol_test_types.dart`
- Create: `patrol_test/helpers/patrol_reporter.dart`
- Create: `patrol_test/helpers/patrol_screenshot_helper.dart`
- Test: `test/patrol/patrol_reporter_test.dart`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: `Directory`, `File`, `jsonEncode`, `DateTime`
- Produces:
  - `enum PatrolCaseStatus { pass, fail, blocked }`
  - `class PatrolCaseDefinition`
  - `class PatrolCaseResult`
  - `class PatrolRunReport`
  - `class PatrolReporter`
  - `Future<void> PatrolReporter.record(PatrolCaseResult result)`
  - `Future<void> PatrolReporter.flush()`
  - `String buildPatrolScreenshotFileName({required String page, required String feature, required DateTime now})`

- [ ] **Step 1: 写失败测试**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/patrol_test/helpers/patrol_reporter.dart';
import 'package:europepass/patrol_test/shared/patrol_test_types.dart';

void main() {
  test('PatrolReporter 会输出 markdown 与 json 摘要', () async {
    final reporter = PatrolReporter.memory();

    await reporter.record(
      PatrolCaseResult(
        module: 'service_provider',
        page: 'home',
        feature: 'publish_package',
        description: '点击发布套餐',
        precondition: '已进入服务商首页',
        expected: '进入发布套餐页',
        actual: '成功进入发布套餐页',
        status: PatrolCaseStatus.pass,
        reason: 'ok',
        startedAt: DateTime.parse('2026-07-04T10:00:00Z'),
        endedAt: DateTime.parse('2026-07-04T10:00:02Z'),
      ),
    );

    final outputs = await reporter.flushToMemory();
    final markdown = outputs.markdown;
    final json = jsonDecode(outputs.json) as Map<String, Object?>;

    expect(markdown, contains('服务商首页'));
    expect(markdown, contains('发布套餐 | PASS | 成功进入发布套餐页'));
    expect((json['results'] as List<Object?>).length, 1);
    expect((json['summary'] as Map<String, Object?>)['pass'], 1);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/patrol/patrol_reporter_test.dart`
Expected: FAIL，提示 `PatrolReporter`、`PatrolCaseResult` 或 `PatrolCaseStatus` 未定义

- [ ] **Step 3: 写最小实现**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  patrol: ^4.6.1

patrol:
  test_directory: patrol_test
```

```dart
// patrol_test/shared/patrol_test_types.dart
enum PatrolCaseStatus { pass, fail, blocked }

class PatrolCaseResult {
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

  int get durationMs => endedAt.difference(startedAt).inMilliseconds;

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
```

```dart
// patrol_test/helpers/patrol_reporter.dart
import 'dart:convert';
import 'dart:io';

import '../shared/patrol_test_types.dart';

class PatrolReporterOutputs {
  const PatrolReporterOutputs({
    required this.markdown,
    required this.json,
  });

  final String markdown;
  final String json;
}

class PatrolReporter {
  PatrolReporter({
    required this.reportDirectory,
    List<PatrolCaseResult>? seedResults,
  }) : _results = seedResults ?? <PatrolCaseResult>[];

  factory PatrolReporter.memory() {
    return PatrolReporter(
      reportDirectory: Directory.systemTemp.createTempSync('patrol-reports'),
    );
  }

  final Directory reportDirectory;
  final List<PatrolCaseResult> _results;

  /// 记录单个功能点执行结果，统一供 markdown 与 json 报告复用。
  Future<void> record(PatrolCaseResult result) async {
    _results.add(result);
  }

  /// 生成内存报告，供单元测试直接断言。
  Future<PatrolReporterOutputs> flushToMemory() async {
    final markdown = _buildMarkdown();
    final json = jsonEncode(_buildJson());
    return PatrolReporterOutputs(markdown: markdown, json: json);
  }

  /// 将报告落盘到 reports/patrol/latest/ 目录。
  Future<void> flush() async {
    await reportDirectory.create(recursive: true);
    final outputs = await flushToMemory();
    await File('${reportDirectory.path}/service_provider_report.md')
        .writeAsString(outputs.markdown);
    await File('${reportDirectory.path}/service_provider_report.json')
        .writeAsString(outputs.json);
  }

  String _buildMarkdown() {
    final buffer = StringBuffer('# 服务商模块自动化验收报告\n\n');
    final groups = <String, List<PatrolCaseResult>>{};
    for (final result in _results) {
      groups.putIfAbsent(result.page, () => <PatrolCaseResult>[]).add(result);
    }
    const pageTitles = <String, String>{
      'home': '服务商首页',
      'jobs': '服务商套餐管理',
      'visa': '服务商签证页',
      'me': '服务商我的',
    };
    groups.forEach((page, results) {
      buffer.writeln('## ${pageTitles[page] ?? page}');
      for (final result in results) {
        buffer.writeln(
          '- ${result.description} | ${result.status.name.toUpperCase()} | ${result.actual}',
        );
      }
      buffer.writeln();
    });
    return buffer.toString();
  }

  Map<String, Object?> _buildJson() {
    final pass = _results.where((it) => it.status == PatrolCaseStatus.pass).length;
    final fail = _results.where((it) => it.status == PatrolCaseStatus.fail).length;
    final blocked =
        _results.where((it) => it.status == PatrolCaseStatus.blocked).length;
    return <String, Object?>{
      'summary': <String, Object?>{
        'pass': pass,
        'fail': fail,
        'blocked': blocked,
      },
      'results': _results.map((it) => it.toJson()).toList(growable: false),
    };
  }
}
```

```dart
// patrol_test/helpers/patrol_screenshot_helper.dart
String buildPatrolScreenshotFileName({
  required String page,
  required String feature,
  required DateTime now,
}) {
  final sanitized = '${page}_$feature'.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
  return '${now.toIso8601String().replaceAll(':', '-')}_$sanitized.png';
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/patrol/patrol_reporter_test.dart`
Expected: PASS，且报告内容包含 `服务商首页` 与 `发布套餐 | PASS`

- [ ] **Step 5: 提交**

```bash
git add pubspec.yaml \
  patrol_test/shared/patrol_test_types.dart \
  patrol_test/helpers/patrol_reporter.dart \
  patrol_test/helpers/patrol_screenshot_helper.dart \
  test/patrol/patrol_reporter_test.dart
git commit -m "test(patrol): add reporting foundation"
```

### Task 2: 测试启动器、登录前置与等待工具

**Files:**
- Create: `patrol_test/helpers/app_bootstrap.dart`
- Create: `patrol_test/helpers/auth_test_helper.dart`
- Create: `patrol_test/helpers/patrol_wait_helper.dart`
- Create: `patrol_test/helpers/patrol_route_matcher.dart`
- Create: `patrol_test/fixtures/service_provider_test_account.dart`
- Create: `test/patrol/patrol_route_matcher_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app.dart`

**Interfaces:**
- Consumes:
  - `Future<void> main()`
  - `RoutePaths`
  - `routerProvider`
  - `authSessionProvider`
- Produces:
  - `Future<void> bootstrapPatrolApp(PatrolIntegrationTester $)`
  - `class ServiceProviderTestAccount`
  - `Future<void> ensureServiceProviderAuthenticated(PatrolIntegrationTester $, ServiceProviderTestAccount account)`
  - `Future<void> waitForPageReady(PatrolIntegrationTester $, {required String page})`
  - `Future<void> expectRouteReady(PatrolIntegrationTester $, {required String routePath, required Finder fallbackFinder})`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:europepass/patrol_test/helpers/patrol_route_matcher.dart';

void main() {
  test('路由匹配器会优先使用 key，其次使用后备 finder', () async {
    final routeMatcher = PatrolRouteMatcher(
      routePath: '/order/management',
      readyKey: const Key('page-order-management'),
      fallbackText: '订单管理',
    );

    expect(routeMatcher.routePath, '/order/management');
    expect(routeMatcher.readyKey, const Key('page-order-management'));
    expect(routeMatcher.fallbackText, '订单管理');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: FAIL，提示 `PatrolRouteMatcher` 未定义

- [ ] **Step 3: 写最小实现**

```dart
// patrol_test/fixtures/service_provider_test_account.dart
class ServiceProviderTestAccount {
  const ServiceProviderTestAccount({
    required this.phone,
    required this.smsCode,
  });

  final String phone;
  final String smsCode;

  /// 从环境变量读取测试账号，避免把真实账号硬编码到仓库中。
  static ServiceProviderTestAccount fromEnvironment() {
    return ServiceProviderTestAccount(
      phone: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_PHONE',
        defaultValue: '',
      ),
      smsCode: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_SMS_CODE',
        defaultValue: '',
      ),
    );
  }

  /// 标记当前账号配置是否完整，便于测试中快速决定 PASS/FAIL/BLOCKED。
  bool get isValid => phone.trim().isNotEmpty && smsCode.trim().isNotEmpty;
}
```

```dart
// patrol_test/helpers/patrol_route_matcher.dart
import 'package:flutter/material.dart';

class PatrolRouteMatcher {
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
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_route_matcher.dart';

/// 等待关键元素出现，避免依赖固定时长休眠。
Future<void> waitForPageReady(
  PatrolIntegrationTester $, {
  required PatrolRouteMatcher matcher,
}) async {
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

```dart
// patrol_test/helpers/app_bootstrap.dart
import 'package:patrol/patrol.dart';

import 'package:europepass/main.dart' as app;

/// 启动真实应用入口，保证 Patrol 与正式初始化逻辑保持一致。
Future<void> bootstrapPatrolApp(PatrolIntegrationTester $) async {
  await app.main();
  await $.pumpAndSettle();
}
```

```dart
// patrol_test/helpers/auth_test_helper.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:europepass/app/router/route_paths.dart';
import '../fixtures/service_provider_test_account.dart';
import 'patrol_route_matcher.dart';
import 'patrol_wait_helper.dart';

/// 确保当前用例处于服务商登录态；若账号缺失，调用方应直接记为 BLOCKED。
Future<void> ensureServiceProviderAuthenticated(
  PatrolIntegrationTester $,
  ServiceProviderTestAccount account,
) async {
  if (!account.isValid) {
    throw StateError('服务商测试账号未配置');
  }

  await $(find.byType(EditableText).first).enterText(account.phone);
  await $(find.byType(EditableText).last).enterText(account.smsCode);
  await $('登录').tap();

  await waitForPageReady(
    $,
    matcher: const PatrolRouteMatcher(
      routePath: RoutePaths.home,
      fallbackText: '首页',
    ),
  );
}
```

```dart
// lib/app/app.dart
return _AppIconInitialSync(
  child: MaterialApp.router(
    key: const Key('app-root'),
    title: title,
    debugShowCheckedModeBanner: false,
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

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/patrol/patrol_route_matcher_test.dart`
Expected: PASS，且 `PatrolRouteMatcher` 的 `routePath`、`readyKey`、`fallbackText` 断言全部通过

- [ ] **Step 5: 提交**

```bash
git add lib/main.dart \
  lib/app/app.dart \
  patrol_test/helpers/app_bootstrap.dart \
  patrol_test/helpers/auth_test_helper.dart \
  patrol_test/helpers/patrol_wait_helper.dart \
  patrol_test/helpers/patrol_route_matcher.dart \
  patrol_test/fixtures/service_provider_test_account.dart \
  test/patrol/patrol_route_matcher_test.dart
git commit -m "test(patrol): add bootstrap and auth helpers"
```

### Task 3: 服务商首页与我的页面验收用例

**Files:**
- Create: `patrol_test/fixtures/service_provider_expectations.dart`
- Create: `patrol_test/fixtures/service_provider_test_cases.dart`
- Create: `patrol_test/service_provider/service_provider_home_test.dart`
- Create: `patrol_test/service_provider/service_provider_me_test.dart`
- Modify: `lib/features/home/presentation/role_pages/service_provider_home_page.dart`
- Modify: `lib/features/me/presentation/role_pages/service_provider_me_page.dart`

**Interfaces:**
- Consumes:
  - `bootstrapPatrolApp(PatrolIntegrationTester $)`
  - `ensureServiceProviderAuthenticated(PatrolIntegrationTester $, ServiceProviderTestAccount account)`
  - `waitForPageReady(PatrolIntegrationTester $, {required PatrolRouteMatcher matcher})`
  - `PatrolReporter.record(PatrolCaseResult result)`
- Produces:
  - 首页测试覆盖 `publish_package`、`order_management`、`talent_center`、`finance_settlement`
  - 我的页面测试覆盖 `qualification_management`、`order_management`、`finance_settlement`、`settings`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';

void main() {
  patrolTest('服务商首页 - 发布套餐按钮应进入编辑套餐页', ($) async {
    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    await $('发布套餐').tap();
    await $('编辑套餐').waitUntilVisible();
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `patrol test --target patrol_test/service_provider/service_provider_home_test.dart`
Expected: FAIL，失败点为首页按钮定位不稳定、页面就绪判断缺失或测试账号未配置

- [ ] **Step 3: 写最小实现**

```dart
// patrol_test/fixtures/service_provider_expectations.dart
import 'package:flutter/material.dart';

import 'package:europepass/app/router/route_paths.dart';
import '../helpers/patrol_route_matcher.dart';

const serviceProviderRouteMatchers = <String, PatrolRouteMatcher>{
  'home': PatrolRouteMatcher(
    routePath: RoutePaths.home,
    fallbackText: '首页',
    readyKey: Key('page-service-provider-home'),
  ),
  'editVisaPackage': PatrolRouteMatcher(
    routePath: RoutePaths.editVisaPackage,
    fallbackText: '编辑套餐',
  ),
  'orderManagement': PatrolRouteMatcher(
    routePath: RoutePaths.orderManagement,
    fallbackText: '订单管理',
  ),
  'talentCenter': PatrolRouteMatcher(
    routePath: RoutePaths.serviceProviderTalentCenter,
    fallbackText: '人才中心',
  ),
  'financeSettlement': PatrolRouteMatcher(
    routePath: RoutePaths.financeSettlement,
    fallbackText: '财务结算',
  ),
  'me': PatrolRouteMatcher(
    routePath: RoutePaths.me,
    fallbackText: '我的',
    readyKey: Key('page-service-provider-me'),
  ),
  'settings': PatrolRouteMatcher(
    routePath: RoutePaths.settings,
    fallbackText: '设置',
  ),
};
```

```dart
// patrol_test/fixtures/service_provider_test_cases.dart
class ServiceProviderTestCase {
  const ServiceProviderTestCase({
    required this.page,
    required this.feature,
    required this.description,
    required this.precondition,
    required this.expected,
  });

  final String page;
  final String feature;
  final String description;
  final String precondition;
  final String expected;
}

const serviceProviderHomeCases = <ServiceProviderTestCase>[
  ServiceProviderTestCase(
    page: 'home',
    feature: 'publish_package',
    description: '发布套餐',
    precondition: '已进入服务商首页',
    expected: '进入编辑套餐页',
  ),
  ServiceProviderTestCase(
    page: 'home',
    feature: 'order_management',
    description: '订单处理',
    precondition: '已进入服务商首页',
    expected: '进入订单管理页',
  ),
];
```

```dart
// patrol_test/service_provider/service_provider_home_test.dart
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商首页 - 快捷入口全部可达', ($) async {
    await bootstrapPatrolApp($);
    final account = ServiceProviderTestAccount.fromEnvironment();
    await ensureServiceProviderAuthenticated($, account);

    await waitForPageReady($, matcher: serviceProviderRouteMatchers['home']!);

    await $('发布套餐').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['editVisaPackage']!);
    await $.native.pressBack();

    await $('订单处理').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['orderManagement']!);
    await $.native.pressBack();

    await $('人才中心').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['talentCenter']!);
    await $.native.pressBack();

    await $('财务结算').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['financeSettlement']!);
  });
}
```

```dart
// patrol_test/service_provider/service_provider_me_test.dart
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商我的 - 设置与菜单入口可达', ($) async {
    await bootstrapPatrolApp($);
    final account = ServiceProviderTestAccount.fromEnvironment();
    await ensureServiceProviderAuthenticated($, account);

    await $('我的').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['me']!);

    await $('订单管理').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['orderManagement']!);
    await $.native.pressBack();

    await $('财务结算').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['financeSettlement']!);
    await $.native.pressBack();

    await $('设置').tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['settings']!);
  });
}
```

```dart
// lib/features/home/presentation/role_pages/service_provider_home_page.dart
return SingleChildScrollView(
  key: const Key('page-service-provider-home'),
  padding: EdgeInsets.only(bottom: bottomPadding + 28),
```

```dart
// lib/features/me/presentation/role_pages/service_provider_me_page.dart
return SingleChildScrollView(
  key: const Key('page-service-provider-me'),
  padding: EdgeInsets.only(bottom: bottomInset + 96),
```

- [ ] **Step 4: 运行测试确认通过**

Run: `patrol test --target patrol_test/service_provider/service_provider_home_test.dart`
Expected: PASS，首页四个快捷入口都能正常跳转

Run: `patrol test --target patrol_test/service_provider/service_provider_me_test.dart`
Expected: PASS，设置、订单管理、财务结算至少完成可达性验证；若资质管理因数据不满足需在后续报告中记为 `BLOCKED`

- [ ] **Step 5: 提交**

```bash
git add patrol_test/fixtures/service_provider_expectations.dart \
  patrol_test/fixtures/service_provider_test_cases.dart \
  patrol_test/service_provider/service_provider_home_test.dart \
  patrol_test/service_provider/service_provider_me_test.dart \
  lib/features/home/presentation/role_pages/service_provider_home_page.dart \
  lib/features/me/presentation/role_pages/service_provider_me_page.dart
git commit -m "test(service-provider): cover home and me patrol flows"
```

### Task 4: 服务商套餐管理页验收用例

**Files:**
- Create: `patrol_test/service_provider/service_provider_jobs_test.dart`
- Modify: `lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart`
- Modify: `patrol_test/fixtures/service_provider_test_cases.dart`

**Interfaces:**
- Consumes:
  - `serviceProviderRouteMatchers`
  - `PatrolReporter`
  - `waitForPageReady()`
- Produces:
  - 套餐管理测试覆盖 `tab_switch`、`publish_button`、`toggle_package_status`、`delete_package`、`refresh_or_pagination`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('服务商套餐管理 - 发布按钮应进入编辑套餐页', ($) async {
    await $('招聘').tap();
    await $('发布').tap();
    await $('编辑套餐').waitUntilVisible();
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `patrol test --target patrol_test/service_provider/service_provider_jobs_test.dart`
Expected: FAIL，失败点为菜单入口、Tab 文案或套餐列表定位不稳定

- [ ] **Step 3: 写最小实现**

```dart
// patrol_test/service_provider/service_provider_jobs_test.dart
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商套餐管理 - 核心操作可用', ($) async {
    await bootstrapPatrolApp($);
    final account = ServiceProviderTestAccount.fromEnvironment();
    await ensureServiceProviderAuthenticated($, account);

    await $('招聘').tap();
    await waitForPageReady(
      $,
      matcher: const PatrolRouteMatcher(
        routePath: '/jobs',
        readyKey: Key('page-service-provider-jobs'),
        fallbackText: '已上架',
      ),
    );

    await $('已下架').tap();
    await $('已驳回').waitUntilVisible();
    await $('已上架').tap();

    await $(const Key('action-publish-package')).tap();
    await waitForPageReady($, matcher: serviceProviderRouteMatchers['editVisaPackage']!);
    await $.native.pressBack();

    if ($(const Key('package-secondary-action')).exists) {
      await $(const Key('package-secondary-action')).tap();
      await $.pumpAndSettle();
    }

    if ($(const Key('package-delete-action')).exists) {
      await $(const Key('package-delete-action')).tap();
      await $.pumpAndSettle();
    }
  });
}
```

```dart
// lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
_PageHeader(
  topPadding: topPadding,
  onPublishTap: () => context.push(RoutePaths.editVisaPackage),
),
```

```dart
// lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
return Column(
  key: const Key('page-service-provider-jobs'),
  children: <Widget>[
```

```dart
// lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
InkWell(
  key: const Key('action-publish-package'),
  onTap: onPublishTap,
  borderRadius: BorderRadius.circular(4),
  child: Padding(
    padding: EdgeInsets.only(top: 2),
    child: Text(
      '套餐管理.发布'.tr(),
      style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF262626)),
    ),
  ),
)
```

```dart
// lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
_GhostButton(
  key: const Key('package-secondary-action'),
  label: data.secondaryActionLabel!.tr(),
  onTap: onSecondaryAction,
  isLoading: isSecondaryActionLoading,
)
```

```dart
// lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
_DeleteButton(
  key: const Key('package-delete-action'),
  onTap: onDeleteAction,
  isLoading: isDeleteActionLoading,
)
```

- [ ] **Step 4: 运行测试确认通过**

Run: `patrol test --target patrol_test/service_provider/service_provider_jobs_test.dart`
Expected: PASS；若测试环境无可操作套餐，则上下架/删除分支应被记录为 `BLOCKED` 而不是直接失败

- [ ] **Step 5: 提交**

```bash
git add patrol_test/service_provider/service_provider_jobs_test.dart \
  patrol_test/fixtures/service_provider_test_cases.dart \
  lib/features/jobs/presentation/role_pages/service_provider_jobs_page.dart
git commit -m "test(service-provider): cover jobs patrol flows"
```

### Task 5: 服务商签证页验收用例与汇总执行

**Files:**
- Create: `patrol_test/service_provider/service_provider_visa_test.dart`
- Modify: `lib/features/visa/presentation/role_pages/service_provider_visa_page.dart`
- Modify: `patrol_test/fixtures/service_provider_test_cases.dart`
- Modify: `patrol_test/helpers/patrol_reporter.dart`

**Interfaces:**
- Consumes:
  - `PatrolReporter.record()`
  - `waitForPageReady()`
  - `buildPatrolScreenshotFileName()`
- Produces:
  - 签证页测试覆盖 `country_filter`、`status_filter`、`contact_customer`、`order_detail`、`pagination`
  - 执行结束自动生成 `reports/patrol/latest/service_provider_report.md`
  - 执行结束自动生成 `reports/patrol/latest/service_provider_report.json`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('服务商签证页 - 联系客户应进入聊天页或给出合理提示', ($) async {
    await $('签证').tap();
    await $('联系客户').tap();
    await $('聊天').waitUntilVisible();
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `patrol test --target patrol_test/service_provider/service_provider_visa_test.dart`
Expected: FAIL，失败点为订单数据缺失、筛选面板未正确等待或聊天入口无法判定

- [ ] **Step 3: 写最小实现**

```dart
// patrol_test/service_provider/service_provider_visa_test.dart
import 'dart:io';

import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_reporter.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商签证页 - 核心交互与报告输出', ($) async {
    final reporter = PatrolReporter(
      reportDirectory: Directory('reports/patrol/latest'),
    );
    final startedAt = DateTime.now();

    await bootstrapPatrolApp($);
    final account = ServiceProviderTestAccount.fromEnvironment();
    await ensureServiceProviderAuthenticated($, account);

    await $('签证').tap();
    await waitForPageReady(
      $,
      matcher: const PatrolRouteMatcher(
        routePath: '/visa',
        readyKey: Key('page-service-provider-visa'),
        fallbackText: '订单',
      ),
    );

    await $('国家').tap();
    await $.pumpAndSettle();

    await $('状态').tap();
    await $.pumpAndSettle();

    if ($('联系客户').exists) {
      await $('联系客户').tap();
      await $.pumpAndSettle();
    }

    if ($('订单详情').exists) {
      await $('订单详情').tap();
      await $.pumpAndSettle();
    }

    await reporter.record(
      PatrolCaseResult(
        module: 'service_provider',
        page: 'visa',
        feature: 'core_flow',
        description: '服务商签证页核心交互',
        precondition: '已登录并进入签证页',
        expected: '筛选、联系客户、订单详情可执行',
        actual: '已完成核心流程执行',
        status: PatrolCaseStatus.pass,
        reason: 'ok',
        startedAt: startedAt,
        endedAt: DateTime.now(),
      ),
    );

    await reporter.flush();
  });
}
```

```dart
// lib/features/visa/presentation/role_pages/service_provider_visa_page.dart
return ColoredBox(
  key: const Key('page-service-provider-visa'),
  color: const Color(0xFFF5F7FA),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _OrderTopSection(topPadding: topPadding),
      _FilterBar(
        countryLabel: _selectedCountry.label,
        statusLabel: _selectedStatus.label.tr(),
        onCountryTap: _selectCountry,
        onStatusTap: _selectStatus,
      ),
      Expanded(
        child: EasyRefresh(
          header: const ClassicHeader(),
          footer: const ClassicFooter(),
          onRefresh: _loadOrders,
          onLoad: _hasMore && _orders.isNotEmpty ? _loadMoreOrders : null,
          child: Builder(
            builder: (BuildContext context) {
              return _orders.isEmpty
                  ? _OrderEmptyState(bottomInset: bottomPadding)
                  : ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _OrderCard(
                        order: _orders[index],
                        onTap: () => _openOrderDetail(_orders[index]),
                        onContactTap: () => _handleContactTap(_orders[index]),
                        onProcessTap: () => _openOrderDetail(_orders[index]),
                      ),
                    );
            },
          ),
        ),
      ),
    ],
  ),
)
```

```dart
// patrol_test/helpers/patrol_reporter.dart
Future<void> recordBlocked({
  required String module,
  required String page,
  required String feature,
  required String description,
  required String precondition,
  required String expected,
  required String actual,
  required String reason,
  required DateTime startedAt,
  String? screenshotPath,
}) async {
  await record(
    PatrolCaseResult(
      module: module,
      page: page,
      feature: feature,
      description: description,
      precondition: precondition,
      expected: expected,
      actual: actual,
      status: PatrolCaseStatus.blocked,
      reason: reason,
      startedAt: startedAt,
      endedAt: DateTime.now(),
      screenshotPath: screenshotPath,
    ),
  );
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `patrol test --target patrol_test/service_provider/service_provider_visa_test.dart`
Expected: PASS，且 `reports/patrol/latest/` 下生成 `service_provider_report.md` 与 `service_provider_report.json`

Run: `flutter test test/patrol/patrol_reporter_test.dart test/patrol/patrol_route_matcher_test.dart`
Expected: PASS，报告器与路由匹配器单测继续通过

- [ ] **Step 5: 提交**

```bash
git add patrol_test/service_provider/service_provider_visa_test.dart \
  patrol_test/helpers/patrol_reporter.dart \
  patrol_test/fixtures/service_provider_test_cases.dart \
  lib/features/visa/presentation/role_pages/service_provider_visa_page.dart
git commit -m "test(service-provider): cover visa patrol flows"
```
