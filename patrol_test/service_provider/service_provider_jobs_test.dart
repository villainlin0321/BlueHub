import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_reporter.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';
import '../helpers/service_provider_case_result_helper.dart';
import '../shared/patrol_test_types.dart';

void main() {
  patrolTest('服务商套餐管理 - 页面交互全扫', ($) async {
    final PatrolReporter reporter = PatrolReporter.memory();

    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    final PatrolCaseResult openPageResult = await _openJobsPage($);
    await reporter.record(openPageResult);
    _ensurePassResult(openPageResult, fallbackMessage: '进入套餐管理页失败');

    final List<PatrolCaseResult> results = <PatrolCaseResult>[
      await _runPublishCase($),
      await _runTabSwitchCase($, tabStatus: 'inactive'),
      await _runTabSwitchCase($, tabStatus: 'draft'),
      await _runTabSwitchCase($, tabStatus: 'active'),
      await _runEditCase($),
      await _runDeleteConfirmCase($),
      await _runStatusToggleCase($),
    ];

    for (final PatrolCaseResult result in results) {
      await reporter.record(result);
      _ensureAcceptedResult(result);
    }
  });
}

/// 进入套餐管理页并等待页面锚点稳定。
Future<PatrolCaseResult> _openJobsPage(PatrolIntegrationTester $) async {
  const PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.page.open',
    description: '进入套餐管理页',
    precondition: '已登录为服务商且位于首页',
    expected: '进入套餐管理页并渲染页面根节点',
  );
  final DateTime startedAt = DateTime.now();

  try {
    // 服务商底部导航文案为“套餐”，测试通过页面根节点确认已进入套餐管理页。
    await $('套餐').tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '成功进入套餐管理页并命中页面根节点',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_page_open_failed',
      actualPrefix: '进入套餐管理页失败',
    );
  }
}

/// 校验发布按钮可进入编辑套餐页，并在结束后返回套餐管理页。
Future<PatrolCaseResult> _runPublishCase(PatrolIntegrationTester $) async {
  const PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.publish',
    description: '发布按钮',
    precondition: '已进入套餐管理页',
    expected: '点击发布后进入编辑套餐页并可返回',
  );
  final DateTime startedAt = DateTime.now();

  try {
    await $(find.byKey(AppTestKeys.actionServiceProviderJobsPublish)).tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['editVisaPackage']!);
    await $(find.byKey(AppTestKeys.actionEditVisaPackageBack)).tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '发布按钮成功进入编辑套餐页并返回套餐管理页',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_publish_failed',
      actualPrefix: '发布按钮交互失败',
    );
  }
}

/// 校验 Tab 切换后，对应内容面板能够稳定出现。
Future<PatrolCaseResult> _runTabSwitchCase(
  PatrolIntegrationTester $, {
  required String tabStatus,
}) async {
  final PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.tab.$tabStatus',
    description: '切换到${_tabLabel(tabStatus)}',
    precondition: '已进入套餐管理页',
    expected: '点击后显示对应 Tab 内容面板',
  );
  final DateTime startedAt = DateTime.now();

  try {
    await _tapJobsTab($, tabStatus: tabStatus);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '成功切换到${_tabLabel(tabStatus)}并渲染对应面板',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_tab_switch_failed',
      actualPrefix: 'Tab 切换失败',
    );
  }
}

/// 校验列表首项编辑按钮在有数据时可进入编辑套餐页，无数据时记为阻塞。
Future<PatrolCaseResult> _runEditCase(PatrolIntegrationTester $) async {
  const PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.package.edit',
    description: '列表项编辑',
    precondition: '套餐管理页已上架列表存在至少 1 条数据',
    expected: '点击编辑后进入编辑套餐页并可返回',
  );
  final DateTime startedAt = DateTime.now();

  try {
    await _tapJobsTab($, tabStatus: 'active');
    final PatrolFinder editButton = $(
      find.byKey(AppTestKeys.actionServiceProviderJobsEdit('active', 0)),
    );
    if (!editButton.visible) {
      return _buildBlockedResult(
        definition: definition,
        startedAt: startedAt,
        actual: '未找到可编辑的已上架套餐，当前环境缺少稳定测试数据',
        reason: 'jobs_active_package_missing',
      );
    }

    await editButton.tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['editVisaPackage']!);
    await $(find.byKey(AppTestKeys.actionEditVisaPackageBack)).tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '已上架列表首项成功进入编辑套餐页并返回',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_edit_failed',
      actualPrefix: '列表项编辑失败',
    );
  }
}

/// 校验列表首项删除按钮会拉起确认弹窗，并使用取消避免污染测试数据。
Future<PatrolCaseResult> _runDeleteConfirmCase(
  PatrolIntegrationTester $,
) async {
  const PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.package.delete_confirm',
    description: '列表项删除确认',
    precondition: '套餐管理页已上架列表存在至少 1 条数据',
    expected: '点击删除后弹出确认弹窗，取消后停留在套餐管理页',
  );
  final DateTime startedAt = DateTime.now();

  try {
    await _tapJobsTab($, tabStatus: 'active');
    final PatrolFinder deleteButton = $(
      find.byKey(AppTestKeys.actionServiceProviderJobsDelete('active', 0)),
    );
    if (!deleteButton.visible) {
      return _buildBlockedResult(
        definition: definition,
        startedAt: startedAt,
        actual: '未找到可删除的已上架套餐，当前环境缺少稳定测试数据',
        reason: 'jobs_delete_package_missing',
      );
    }

    await deleteButton.tap();
    await $('删除套餐').waitUntilVisible();
    await $('取消').tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '删除确认弹窗成功弹出，并已取消返回套餐管理页',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_delete_confirm_failed',
      actualPrefix: '删除确认流程失败',
    );
  }
}

/// 校验列表首项上下架按钮在有数据时可触发状态切换，无数据时记为阻塞。
Future<PatrolCaseResult> _runStatusToggleCase(PatrolIntegrationTester $) async {
  const PatrolCaseDefinition definition = PatrolCaseDefinition(
    module: 'service_provider',
    page: 'jobs',
    feature: 'jobs.package.status_toggle',
    description: '列表项上下架',
    precondition: '套餐管理页已上架或已下架列表存在至少 1 条数据',
    expected: '点击上下架按钮后显示成功提示',
  );
  final DateTime startedAt = DateTime.now();

  try {
    final _ToggleCandidate? candidate = await _findToggleCandidate($);
    if (candidate == null) {
      return _buildBlockedResult(
        definition: definition,
        startedAt: startedAt,
        actual: '已上架和已下架列表都没有可切换状态的套餐，当前环境缺少稳定测试数据',
        reason: 'jobs_toggle_package_missing',
      );
    }

    await candidate.finder.tap();
    await $(candidate.successToastText).waitUntilVisible();
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual: '已在${_tabLabel(candidate.tabStatus)}列表触发状态切换并看到成功提示',
    );
  } catch (error) {
    return buildServiceProviderFailureResult(
      definition: definition,
      startedAt: startedAt,
      error: error,
      reason: 'jobs_status_toggle_failed',
      actualPrefix: '上下架切换失败',
    );
  }
}

/// 依次尝试已上架和已下架列表，寻找可执行上下架动作的首项按钮。
Future<_ToggleCandidate?> _findToggleCandidate(
  PatrolIntegrationTester $,
) async {
  const List<_ToggleCandidateSeed> seeds = <_ToggleCandidateSeed>[
    _ToggleCandidateSeed(tabStatus: 'active', successToastText: '套餐已下架'),
    _ToggleCandidateSeed(tabStatus: 'inactive', successToastText: '套餐已上架'),
  ];

  for (final _ToggleCandidateSeed seed in seeds) {
    await _tapJobsTab($, tabStatus: seed.tabStatus);
    final PatrolFinder finder = $(
      find.byKey(
        AppTestKeys.actionServiceProviderJobsStatusToggle(seed.tabStatus, 0),
      ),
    );
    if (finder.visible) {
      return _ToggleCandidate(
        tabStatus: seed.tabStatus,
        successToastText: seed.successToastText,
        finder: finder,
      );
    }
  }
  return null;
}

/// 切换套餐管理页 Tab，并等待对应面板稳定出现。
Future<void> _tapJobsTab(
  PatrolIntegrationTester $, {
  required String tabStatus,
}) async {
  await $(find.byKey(AppTestKeys.tabServiceProviderJobs(tabStatus))).tap();
  await $(
    find.byKey(AppTestKeys.sectionServiceProviderJobsPanel(tabStatus)),
  ).waitUntilVisible();
}

/// 根据统一 matcher 定义等待目标路由或关键锚点出现。
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

/// 数据依赖型用例允许在明确缺少测试数据时记为阻塞。
bool _isAcceptedStatus(PatrolCaseResult result) {
  const Set<String> blockedFeatures = <String>{
    'jobs.package.edit',
    'jobs.package.delete_confirm',
    'jobs.package.status_toggle',
  };
  if (blockedFeatures.contains(result.feature)) {
    return result.status == PatrolCaseStatus.pass ||
        result.status == PatrolCaseStatus.blocked;
  }
  return result.status == PatrolCaseStatus.pass;
}

/// 对必须通过的结果做显式校验，避免 Patrol 对 `expect()` 失败信息透传不完整。
void _ensurePassResult(
  PatrolCaseResult result, {
  required String fallbackMessage,
}) {
  if (result.status == PatrolCaseStatus.pass) {
    return;
  }
  throw StateError('$fallbackMessage：${result.actual}');
}

/// 对数据依赖型结果执行显式校验，仅在 `FAIL` 时抛出详细错误。
void _ensureAcceptedResult(PatrolCaseResult result) {
  if (_isAcceptedStatus(result)) {
    return;
  }
  throw StateError('${result.description} 未达到预期：${result.actual}');
}

/// 构造通过结果，统一描述成功实际输出。
PatrolCaseResult _buildPassResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required String actual,
}) {
  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: actual,
    status: PatrolCaseStatus.pass,
    reason: 'ok',
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}

/// 构造阻塞结果，仅在环境缺少稳定测试数据时使用。
PatrolCaseResult _buildBlockedResult({
  required PatrolCaseDefinition definition,
  required DateTime startedAt,
  required String actual,
  required String reason,
}) {
  return PatrolCaseResult(
    module: definition.module,
    page: definition.page,
    feature: definition.feature,
    description: definition.description,
    precondition: definition.precondition,
    expected: definition.expected,
    actual: actual,
    status: PatrolCaseStatus.blocked,
    reason: reason,
    startedAt: startedAt,
    endedAt: DateTime.now(),
  );
}

/// 将 Tab 状态值转换为业务文案，便于输出稳定报告。
String _tabLabel(String tabStatus) {
  switch (tabStatus) {
    case 'active':
      return '已上架';
    case 'inactive':
      return '已下架';
    case 'draft':
      return '已驳回';
  }
  throw ArgumentError.value(tabStatus, 'tabStatus', '未注册的套餐管理 Tab');
}

class _ToggleCandidateSeed {
  const _ToggleCandidateSeed({
    required this.tabStatus,
    required this.successToastText,
  });

  final String tabStatus;
  final String successToastText;
}

class _ToggleCandidate {
  const _ToggleCandidate({
    required this.tabStatus,
    required this.successToastText,
    required this.finder,
  });

  final String tabStatus;
  final String successToastText;
  final PatrolFinder finder;
}
