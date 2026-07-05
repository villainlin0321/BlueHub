import 'dart:async';

import 'package:europepass/features/visa/data/visa_package_models.dart';
import 'package:europepass/features/visa/data/visa_package_providers.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/network/services/visa_package_service.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
// ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart';

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
    final _PatrolFrameworkProbe frameworkProbe = _attachPatrolFrameworkProbe();
    addTearDown(frameworkProbe.dispose);

    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    final PatrolCaseResult openPageResult = await _openJobsPage($);
    await reporter.record(openPageResult);
    expect(
      openPageResult.status,
      PatrolCaseStatus.pass,
      reason: '进入套餐管理页失败：${openPageResult.actual}',
    );

    await _recordAndAssertAcceptedResult(
      reporter,
      await _runPublishCase($),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runTabSwitchCase($, tabStatus: 'inactive'),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runTabSwitchCase($, tabStatus: 'draft'),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runTabSwitchCase($, tabStatus: 'active'),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runEditCase($),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runDeleteConfirmCase($),
    );
    await _recordAndAssertAcceptedResult(
      reporter,
      await _runStatusToggleCase($),
    );
    await frameworkProbe.logSnapshot(stage: 'before_test_end');
  });
}

/// 挂接 Patrol 当前 live test 的状态与错误日志，定位业务步骤全通过后仍被框架判失败的来源。
_PatrolFrameworkProbe _attachPatrolFrameworkProbe() {
  final liveTest = Invoker.current!.liveTest;
  final StreamSubscription stateSubscription = liveTest.onStateChange.listen((_) {
    AppLogger.instance.info(
      'PATROL_JOBS_FRAMEWORK',
      'Patrol live test 状态发生变化',
      context: <String, Object?>{
        'stage': 'state_change',
        'test': liveTest.individualName,
        'state': liveTest.state.toString(),
        'status': liveTest.state.status.name,
        'result': liveTest.state.result.name,
        'errorCount': liveTest.errors.length,
      },
    );
  });
  final StreamSubscription errorSubscription = liveTest.onError.listen((asyncError) {
    final AsyncError typedAsyncError = asyncError as AsyncError;
    AppLogger.instance.error(
      'PATROL_JOBS_FRAMEWORK',
      'Patrol live test 捕获到异步错误',
      error: typedAsyncError.error,
      stackTrace: typedAsyncError.stackTrace,
      context: <String, Object?>{
        'stage': 'live_test_error',
        'test': liveTest.individualName,
        'state': liveTest.state.toString(),
        'status': liveTest.state.status.name,
        'result': liveTest.state.result.name,
        'errorCount': liveTest.errors.length,
      },
    );
  });
  return _PatrolFrameworkProbe(
    stateSubscription: stateSubscription,
    errorSubscription: errorSubscription,
    readSnapshot: () => <String, Object?>{
      'test': liveTest.individualName,
      'state': liveTest.state.toString(),
      'status': liveTest.state.status.name,
      'result': liveTest.state.result.name,
      'errorCount': liveTest.errors.length,
    },
  );
}

/// 记录单个子场景结果并立即断言，避免所有步骤跑完后才在收尾阶段丢失失败定位信息。
Future<void> _recordAndAssertAcceptedResult(
  PatrolReporter reporter,
  PatrolCaseResult result,
) async {
  await reporter.record(result);
  // 通过应用日志落盘每个子场景结果，便于 native 汇总失败但未携带 details 时回查。
  AppLogger.instance.info(
    'PATROL_JOBS_CASE',
    '记录套餐管理子场景执行结果',
    context: <String, Object?>{
      'feature': result.feature,
      'status': result.status.name,
      'reason': result.reason,
      'actual': result.actual,
    },
  );
  expect(
    _isAcceptedStatus(result),
    isTrue,
    reason: '${result.description} 未达到预期：${result.actual}',
  );
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
    final int? packageId = await _findFirstPackageId($, tabStatus: 'active');
    if (packageId == null) {
      return _buildBlockedResult(
        definition: definition,
        startedAt: startedAt,
        actual: '未找到可编辑的已上架套餐，当前环境缺少稳定测试数据',
        reason: 'jobs_active_package_missing',
      );
    }
    final PatrolFinder editButton = $(
      find.byKey(
        AppTestKeys.actionServiceProviderJobsEdit('active', packageId),
      ),
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
    final int? packageId = await _findFirstPackageId($, tabStatus: 'active');
    if (packageId == null) {
      return _buildBlockedResult(
        definition: definition,
        startedAt: startedAt,
        actual: '未找到可删除的已上架套餐，当前环境缺少稳定测试数据',
        reason: 'jobs_delete_package_missing',
      );
    }
    final PatrolFinder deleteButton = $(
      find.byKey(
        AppTestKeys.actionServiceProviderJobsDelete('active', packageId),
      ),
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
    await _rollbackStatusToggle(candidate, $);
    await _waitForMatcher($, serviceProviderRouteMatchers['jobs']!);
    return _buildPassResult(
      definition: definition,
      startedAt: startedAt,
      actual:
          '已在${_tabLabel(candidate.tabStatus)}列表触发状态切换、看到成功提示，并回滚套餐 ${candidate.packageId} 到原状态',
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
    _ToggleCandidateSeed(
      tabStatus: 'active',
      successToastText: '套餐已下架',
      rollbackStatus: 'active',
    ),
    _ToggleCandidateSeed(
      tabStatus: 'inactive',
      successToastText: '套餐已上架',
      rollbackStatus: 'inactive',
    ),
  ];

  for (final _ToggleCandidateSeed seed in seeds) {
    final int? packageId = await _findFirstPackageId(
      $,
      tabStatus: seed.tabStatus,
    );
    if (packageId == null) {
      continue;
    }
    await _tapJobsTab($, tabStatus: seed.tabStatus);
    final PatrolFinder finder = $(
      find.byKey(
        AppTestKeys.actionServiceProviderJobsStatusToggle(
          seed.tabStatus,
          packageId,
        ),
      ),
    );
    if (finder.visible) {
      return _ToggleCandidate(
        tabStatus: seed.tabStatus,
        successToastText: seed.successToastText,
        rollbackStatus: seed.rollbackStatus,
        packageId: packageId,
        finder: finder,
      );
    }
  }
  return null;
}

/// 读取指定状态列表中的首个套餐 ID，供精确命中页面操作 Key 与回滚动作复用。
Future<int?> _findFirstPackageId(
  PatrolIntegrationTester $, {
  required String tabStatus,
}) async {
  final List<VisaPackageVO> packages = await _listPackagesByStatus(
    $,
    tabStatus: tabStatus,
  );
  if (packages.isEmpty) {
    return null;
  }
  return packages.first.packageId;
}

/// 通过应用内共享 Provider 容器读取真实服务，避免测试重新维护一套鉴权上下文。
Future<List<VisaPackageVO>> _listPackagesByStatus(
  PatrolIntegrationTester $, {
  required String tabStatus,
}) async {
  final service = _readVisaPackageService($);
  final pageResult = await service.listMyPackages(
    page: 1,
    pageSize: 20,
    status: tabStatus,
  );
  return pageResult.list;
}

/// 使用同一个 `packageId` 直接回滚套餐状态，确保用例不污染测试账号数据。
Future<void> _rollbackStatusToggle(
  _ToggleCandidate candidate,
  PatrolIntegrationTester $,
) async {
  final service = _readVisaPackageService($);
  await service.updatePackageStatus(
    packageId: candidate.packageId,
    request: UpdatePackageStatusBO(status: candidate.rollbackStatus),
  );
  await _assertPackageRestored(
    service,
    packageId: candidate.packageId,
    restoredStatus: candidate.rollbackStatus,
  );
}

/// 轮询确认套餐已回到原始状态列表，避免接口成功返回但列表仍短暂未刷新的假阳性。
Future<void> _assertPackageRestored(
  VisaPackageService service, {
  required int packageId,
  required String restoredStatus,
}) async {
  for (int attempt = 0; attempt < 5; attempt++) {
    final pageResult = await service.listMyPackages(
      page: 1,
      pageSize: 20,
      status: restoredStatus,
    );
    final bool restored = pageResult.list.any(
      (VisaPackageVO item) => item.packageId == packageId,
    );
    if (restored) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('套餐 $packageId 回滚后未回到${_tabLabel(restoredStatus)}列表');
}

/// 从应用根节点读取共享 Provider 容器中的签证套餐服务，复用真实登录态和网络配置。
VisaPackageService _readVisaPackageService(PatrolIntegrationTester $) {
  final ProviderContainer container = readAppProviderContainer($);
  return container.read(visaPackageServiceProvider);
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
    required this.rollbackStatus,
  });

  final String tabStatus;
  final String successToastText;
  final String rollbackStatus;
}

class _ToggleCandidate {
  const _ToggleCandidate({
    required this.tabStatus,
    required this.successToastText,
    required this.rollbackStatus,
    required this.packageId,
    required this.finder,
  });

  final String tabStatus;
  final String successToastText;
  final String rollbackStatus;
  final int packageId;
  final PatrolFinder finder;
}

/// 收口 Patrol framework 级订阅，避免诊断监听本身污染测试生命周期。
class _PatrolFrameworkProbe {
  const _PatrolFrameworkProbe({
    required this.stateSubscription,
    required this.errorSubscription,
    required this.readSnapshot,
  });

  final StreamSubscription stateSubscription;
  final StreamSubscription errorSubscription;
  final Map<String, Object?> Function() readSnapshot;

  /// 在关键收尾节点主动记录一次快照，补齐仅靠异步监听时可能缺失的最终状态。
  Future<void> logSnapshot({required String stage}) async {
    AppLogger.instance.info(
      'PATROL_JOBS_FRAMEWORK',
      '记录 Patrol live test 快照',
      context: <String, Object?>{
        'stage': stage,
        ...readSnapshot(),
      },
    );
  }

  /// 释放状态与错误监听，避免跨用例残留订阅。
  Future<void> dispose() async {
    await stateSubscription.cancel();
    await errorSubscription.cancel();
  }
}
