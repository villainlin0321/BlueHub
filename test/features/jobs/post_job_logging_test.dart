import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/features/config/data/config_models.dart';
import 'package:europepass/features/jobs/application/post_job/post_job_controller.dart';
import 'package:europepass/features/jobs/application/post_job/post_job_state.dart';
import 'package:europepass/features/jobs/data/job_models.dart';
import 'package:europepass/features/jobs/data/job_providers.dart';
import 'package:europepass/features/jobs/presentation/post_job_page.dart';
import 'package:europepass/shared/logging/app_log_facade.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/job_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 验证岗位发布关键日志会复用同一条链路上下文，并覆盖成功与失败分支。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  Directory? tempDirectory;

  /// 等待异步日志刷盘，避免测试在日志尚未落盘时提前读取。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 断言日志中保留的是安全摘要字段，便于确认脱敏后的排障信息仍然完整。
  void expectSafeDraftSummary(
    Map<String, Object?> context, {
    required bool titleFilled,
    required bool locationFilled,
    required bool headcountFilled,
    required bool salaryRangeFilled,
    required int descriptionLength,
  }) {
    expect(context['titleFilled'], titleFilled.toString());
    expect(context['locationFilled'], locationFilled.toString());
    expect(context['headcountFilled'], headcountFilled.toString());
    expect(context['salaryRangeFilled'], salaryRangeFilled.toString());
    expect(context['descriptionLength'], descriptionLength.toString());
  }

  /// 挂载真实的岗位发布页，验证页面级生命周期日志而不是仅验证控制器行为。
  Future<void> pumpPostJobPage(
    WidgetTester tester, {
    required PostJobPageArgs args,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: PostJobPage(args: args)),
      ),
    );
    // 这里不能用 pumpAndSettle，页面子树里存在持续动画，会导致测试一直等待。
    // 只推进到首帧回调和编辑态同步回填完成即可满足日志断言。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// 从控制台日志文本里截取指定事件对应的 PrettyPrinter 输出块。
  String readConsoleEventBlock(List<String> consoleLines, String event) {
    final String consoleText = consoleLines.join('\n');
    final String marker = '"event": "$event"';
    final int markerIndex = consoleText.indexOf(marker);
    if (markerIndex < 0) {
      return '';
    }
    final int blockStart = consoleText.lastIndexOf('┌', markerIndex);
    final int blockEnd = consoleText.indexOf('└', markerIndex);
    if (blockStart >= 0 && blockEnd >= 0) {
      return consoleText.substring(blockStart, blockEnd);
    }
    return consoleText.substring(markerIndex);
  }

  /// 捕获一次测试动作期间的结构化控制台日志，便于断言事件顺序与字段内容。
  Future<List<String>> captureConsoleLogs(Future<void> Function() action) async {
    final List<String> consoleLines = <String>[];
    final void Function(String?, {int? wrapWidth}) originalDebugPrint =
        debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        consoleLines.add(message);
      }
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
    try {
      await action();
    } finally {
      debugPrint = originalDebugPrint;
    }
    return consoleLines;
  }

  /// 断言结构化控制台日志不包含表单原文与原始字段名，只保留安全摘要字段。
  void expectNoRawFormFieldsInConsole(
    String consoleText, {
    required List<String> rawValues,
  }) {
    expect(consoleText, isNot(contains('"title":')));
    expect(consoleText, isNot(contains('"countryOrCity":')));
    expect(consoleText, isNot(contains('"description":')));
    for (final String rawValue in rawValues.where(
      (String item) => item.trim().isNotEmpty,
    )) {
      expect(consoleText, isNot(contains(rawValue)));
    }
  }

  /// 使用页面点击作用域模拟真实发布入口，确保控制器日志能继承页面链路字段。
  Future<void> runPublishAction({
    required ProviderContainer container,
    required String traceId,
    required PostJobFormDraft draft,
    int? editingJobId,
  }) {
    return ActionLog.run<Future<void>>(
      event: 'POST_JOB_SUBMIT_TAP',
      message: '用户点击发布岗位',
      traceId: traceId,
      fields: const <String, Object?>{
        'route': '/jobs/post',
        'module': 'jobs',
        'feature': 'post_job',
        'action': 'POST_JOB_SUBMIT_TAP',
      },
      action: () {
        return AppLogScope.run<Future<void>>(
          traceId: traceId,
          fields: const <String, Object?>{
            'route': '/jobs/post',
            'module': 'jobs',
            'feature': 'post_job',
            'action': 'POST_JOB_SUBMIT_TAP',
          },
          action: () {
            return container
                .read(postJobControllerProvider.notifier)
                .publish(draft, editingJobId: editingJobId);
          },
        );
      },
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_post_job_logging_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory!.path;
          }
          return tempDirectory!.path;
        });
    await AppLogger.instance.init();
    await waitForLogFlush();
  });

  tearDownAll(() async {
    await waitForLogFlush();
    try {
      await AppLogger.instance.dispose();
    } on StateError {
      // `testWidgets` 结束时偶发仍有日志写队列附着，忽略清理期异常即可。
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    final Directory? currentTempDirectory = tempDirectory;
    if (currentTempDirectory != null && await currentTempDirectory.exists()) {
      try {
        await currentTempDirectory.delete(recursive: true);
      } on FileSystemException {
        // 临时目录删除失败不影响断言结果，交给系统在进程退出后回收。
      }
    }
  });

  testWidgets('PostJobPage 挂载时会各输出一次页面进入与首帧日志', (
    WidgetTester tester,
  ) async {
    final List<String> consoleLines = await captureConsoleLogs(() async {
      await pumpPostJobPage(
        tester,
        args: PostJobPageArgs.edit(
          jobId: 99,
          prefetchedRequirementTags: const <TagItemVO>[],
          prefetchedJobDetail: _fakeJobDetail(jobId: 99),
        ),
      );
      await tester.runAsync(waitForLogFlush);
    });

    final String consoleText = consoleLines.join('\n');
    final String pageEnterBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_PAGE_ENTER',
    );
    final String firstFrameBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_FIRST_FRAME',
    );

    expect(
      RegExp(r'"event": "POST_JOB_PAGE_ENTER"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_FIRST_FRAME"').allMatches(consoleText),
      hasLength(1),
    );
    expect(pageEnterBlock, contains('"route": "${RoutePaths.postJob}"'));
    expect(pageEnterBlock, contains('"mode": "edit"'));
    expect(pageEnterBlock, contains('"isEdit": "true"'));
    expect(pageEnterBlock, contains('"editingJobId": "99"'));
    expect(firstFrameBlock, contains('"route": "${RoutePaths.postJob}"'));
    expect(firstFrameBlock, contains('"mode": "edit"'));
    expect(firstFrameBlock, contains('"isEdit": "true"'));
    expect(firstFrameBlock, contains('"editingJobId": "99"'));
  });

  test('publish 会复用点击与请求开始日志的同一条链路字段', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        jobServiceProvider.overrideWithValue(_FakeJobService.success()),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<PostJobState> stateSubscription = container.listen(
      postJobControllerProvider,
      (PostJobState? previous, PostJobState next) {},
      fireImmediately: true,
    );
    addTearDown(stateSubscription.close);
    const String traceId = 'post-job-success-trace';
    final List<String> consoleLines = await captureConsoleLogs(() async {
      await runPublishAction(
        container: container,
        traceId: traceId,
        draft: const PostJobFormDraft(
          title: '焊工',
          countryOrCity: '德国',
          headcount: '5',
          minSalary: '1000',
          maxSalary: '2000',
          description: '测试描述',
        ),
      );
      await waitForLogFlush();
    });
    final String consoleText = consoleLines.join('\n');
    final String validateStartBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_VALIDATE_START',
    );
    final String requestStartBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_SUBMIT_REQUEST_START',
    );

    expect(
      RegExp(r'"event": "POST_JOB_SUBMIT_TAP"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_VALIDATE_START"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_SUBMIT_REQUEST_START"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      consoleText.indexOf('"event": "POST_JOB_SUBMIT_TAP"'),
      lessThan(consoleText.indexOf('"event": "POST_JOB_SUBMIT_REQUEST_START"')),
    );
    expect(requestStartBlock, contains('"traceId": "$traceId"'));
    expect(requestStartBlock, contains('"route": "/jobs/post"'));
    expect(requestStartBlock, contains('"module": "jobs"'));
    expect(requestStartBlock, contains('"feature": "post_job"'));
    expect(requestStartBlock, contains('"action": "POST_JOB_SUBMIT_TAP"'));
    expect(requestStartBlock, isNot(contains('"editingJobId"')));
    expectSafeDraftSummary(
      <String, Object?>{
        'titleFilled': RegExp(r'"titleFilled": "true"')
                .firstMatch(validateStartBlock)
                ?.group(0)
                ?.split(': ')
                .last
                .replaceAll('"', '') ??
            '',
        'locationFilled': RegExp(r'"locationFilled": "true"')
                .firstMatch(validateStartBlock)
                ?.group(0)
                ?.split(': ')
                .last
                .replaceAll('"', '') ??
            '',
        'headcountFilled': RegExp(r'"headcountFilled": "true"')
                .firstMatch(validateStartBlock)
                ?.group(0)
                ?.split(': ')
                .last
                .replaceAll('"', '') ??
            '',
        'salaryRangeFilled': RegExp(r'"salaryRangeFilled": "true"')
                .firstMatch(validateStartBlock)
                ?.group(0)
                ?.split(': ')
                .last
                .replaceAll('"', '') ??
            '',
        'descriptionLength': RegExp(r'"descriptionLength": "(\d+)"')
                .firstMatch(validateStartBlock)
                ?.group(1) ??
            '',
      },
      titleFilled: true,
      locationFilled: true,
      headcountFilled: true,
      salaryRangeFilled: true,
      descriptionLength: 4,
    );
    expectNoRawFormFieldsInConsole(
      consoleText,
      rawValues: const <String>['焊工', '德国', '测试描述'],
    );
    expect(stateSubscription.read().publishSuccessId, 1);
  });

  test('publish 校验失败时会输出失败日志且不会进入请求阶段', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        jobServiceProvider.overrideWithValue(_FakeJobService.success()),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<PostJobState> stateSubscription = container.listen(
      postJobControllerProvider,
      (PostJobState? previous, PostJobState next) {},
      fireImmediately: true,
    );
    addTearDown(stateSubscription.close);
    const String traceId = 'post-job-validate-fail-trace';
    final List<String> consoleLines = await captureConsoleLogs(() async {
      await runPublishAction(
        container: container,
        traceId: traceId,
        draft: const PostJobFormDraft(
          title: '',
          countryOrCity: '德国',
          headcount: '5',
          minSalary: '1000',
          maxSalary: '2000',
          description: '测试描述',
        ),
      );
      await waitForLogFlush();
    });
    final String consoleText = consoleLines.join('\n');
    final String validateStartBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_VALIDATE_START',
    );
    final String validateFailBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_VALIDATE_FAIL',
    );

    expect(
      RegExp(r'"event": "POST_JOB_SUBMIT_TAP"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_VALIDATE_START"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_VALIDATE_FAIL"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      consoleText.contains('"event": "POST_JOB_SUBMIT_REQUEST_START"'),
      isFalse,
    );
    expect(validateFailBlock, contains('"reason": "title_required"'));
    expectSafeDraftSummary(
      <String, Object?>{
        'titleFilled': 'false',
        'locationFilled': 'true',
        'headcountFilled': 'true',
        'salaryRangeFilled': 'true',
        'descriptionLength': RegExp(r'"descriptionLength": "(\d+)"')
                .firstMatch(validateStartBlock)
                ?.group(1) ??
            '',
      },
      titleFilled: false,
      locationFilled: true,
      headcountFilled: true,
      salaryRangeFilled: true,
      descriptionLength: 4,
    );
    expectNoRawFormFieldsInConsole(
      consoleText,
      rawValues: const <String>['德国', '测试描述'],
    );
    expect(stateSubscription.read().feedbackIsError, isTrue);
  });

  test('publish 请求失败时会输出开始和失败日志并重置发布状态', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        jobServiceProvider.overrideWithValue(_FakeJobService.failure()),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<PostJobState> stateSubscription = container.listen(
      postJobControllerProvider,
      (PostJobState? previous, PostJobState next) {},
      fireImmediately: true,
    );
    addTearDown(stateSubscription.close);
    const String traceId = 'post-job-request-fail-trace';
    final List<String> consoleLines = await captureConsoleLogs(() async {
      await runPublishAction(
        container: container,
        traceId: traceId,
        draft: const PostJobFormDraft(
          title: '电工',
          countryOrCity: '德国',
          headcount: '3',
          minSalary: '1200',
          maxSalary: '2400',
          description: '测试描述',
        ),
        editingJobId: 99,
      );
      await waitForLogFlush();
    });
    final String consoleText = consoleLines.join('\n');
    final String validateStartBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_VALIDATE_START',
    );
    final String requestFailBlock = readConsoleEventBlock(
      consoleLines,
      'POST_JOB_SUBMIT_REQUEST_FAIL',
    );

    expect(
      RegExp(r'"event": "POST_JOB_SUBMIT_REQUEST_START"').allMatches(consoleText),
      hasLength(1),
    );
    expect(
      RegExp(r'"event": "POST_JOB_SUBMIT_REQUEST_FAIL"').allMatches(consoleText),
      hasLength(1),
    );
    expect(requestFailBlock, contains('"traceId": "$traceId"'));
    expect(requestFailBlock, contains('"editingJobId": "99"'));
    expect(requestFailBlock, contains('"mode": "edit"'));
    expectSafeDraftSummary(
      <String, Object?>{
        'titleFilled': 'true',
        'locationFilled': 'true',
        'headcountFilled': 'true',
        'salaryRangeFilled': 'true',
        'descriptionLength': RegExp(r'"descriptionLength": "(\d+)"')
                .firstMatch(validateStartBlock)
                ?.group(1) ??
            '',
      },
      titleFilled: true,
      locationFilled: true,
      headcountFilled: true,
      salaryRangeFilled: true,
      descriptionLength: 4,
    );
    expectNoRawFormFieldsInConsole(
      consoleText,
      rawValues: const <String>['电工', '德国', '测试描述'],
    );
    expect(stateSubscription.read().isPublishing, isFalse);
    expect(stateSubscription.read().feedbackIsError, isTrue);
  });
}

/// 提供可控的岗位服务替身，避免测试依赖真实网络请求。
class _FakeJobService extends JobService {
  _FakeJobService._({required this.shouldFail})
    : super(apiClient: ApiClient(Dio()));

  final bool shouldFail;

  /// 构造一个稳定成功的岗位服务替身。
  factory _FakeJobService.success() {
    return _FakeJobService._(shouldFail: false);
  }

  /// 构造一个固定抛错的岗位服务替身，用于验证失败日志链路。
  factory _FakeJobService.failure() {
    return _FakeJobService._(shouldFail: true);
  }

  @override
  /// 按测试场景决定是否抛错，模拟新增岗位请求的成功与失败。
  Future<Map<String, dynamic>> createJob({required CreateJobBO request}) async {
    if (shouldFail) {
      throw StateError('create job failed for test');
    }
    return <String, dynamic>{'jobId': 101};
  }

  @override
  /// 按测试场景决定是否抛错，模拟编辑岗位请求的成功与失败。
  Future<void> updateJob({
    required int jobId,
    required CreateJobBO request,
  }) async {
    if (shouldFail) {
      throw StateError('update job failed for test');
    }
  }
}

/// 构造最小可用的岗位详情假数据，避免页面级测试依赖真实接口。
JobDetailVO _fakeJobDetail({required int jobId}) {
  return JobDetailVO(
    jobId: jobId,
    title: '测试岗位',
    salaryMin: 1000,
    salaryMax: 2000,
    salaryCurrency: 'EUR',
    salaryPeriod: 'month',
    country: 'DE',
    city: 'Berlin',
    address: '德国 Berlin',
    latitude: 0,
    longitude: 0,
    headcount: 3,
    employmentType: 'full_time',
    tags: const <TagVO>[],
    hasVisaSupport: false,
    isUrgent: false,
    responsibilities: const <String>[],
    requirements: const <String>[],
    benefits: const <String>[],
    description: '页面级测试详情',
    status: 'active',
    employer: const EmployerInfoVO(
      employerId: 1,
      name: 'BlueHub',
      industry: 'tech',
      size: 'small',
      logoUrl: '',
    ),
    viewCount: 0,
    applyCount: 0,
    isCollected: false,
    publishedAt: '2026-07-05T00:00:00Z',
  );
}
