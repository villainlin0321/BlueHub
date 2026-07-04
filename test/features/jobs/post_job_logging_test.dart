import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/jobs/application/post_job/post_job_controller.dart';
import 'package:europepass/features/jobs/application/post_job/post_job_state.dart';
import 'package:europepass/features/jobs/data/job_models.dart';
import 'package:europepass/features/jobs/data/job_providers.dart';
import 'package:europepass/shared/logging/app_log_facade.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/job_service.dart';
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

  /// 读取当前日志文件中的结构化日志，便于断言事件顺序与上下文字段。
  Future<List<Map<String, Object?>>> readJsonLogEntries() async {
    final String? content = await AppLogger.instance.readCurrentLog();
    if (content == null || content.trim().isEmpty) {
      return <Map<String, Object?>>[];
    }

    return content
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .map((String line) {
          final Object? decoded = jsonDecode(line);
          return Map<String, Object?>.from(decoded! as Map<dynamic, dynamic>);
        })
        .toList();
  }

  /// 等待异步日志刷盘，避免测试在日志尚未落盘时提前读取。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 安全读取结构化日志里的上下文对象，避免测试里重复做类型转换。
  Map<String, Object?> readContext(Map<String, Object?> entry) {
    return Map<String, Object?>.from(entry['context']! as Map);
  }

  /// 只保留指定 traceId 下的结构化日志，避免其他测试前置日志干扰断言。
  Future<List<Map<String, Object?>>> readEntriesByTraceId(String traceId) async {
    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    return entries.where((Map<String, Object?> item) {
      final Map<String, Object?>? context =
          item['context'] as Map<String, Object?>?;
      return context?['traceId'] == traceId;
    }).toList(growable: false);
  }

  /// 从事件列表里提取事件名序列，便于断言链路顺序是否正确。
  List<String> readEvents(List<Map<String, Object?>> entries) {
    return entries
        .map((Map<String, Object?> item) => item['event'].toString())
        .toList(growable: false);
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
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    final Directory? currentTempDirectory = tempDirectory;
    if (currentTempDirectory != null && await currentTempDirectory.exists()) {
      await currentTempDirectory.delete(recursive: true);
    }
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

    final List<Map<String, Object?>> entries = await readEntriesByTraceId(
      traceId,
    );
    final List<String> events = readEvents(entries);
    final Map<String, Object?> requestStartContext = readContext(
      entries.lastWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'POST_JOB_SUBMIT_REQUEST_START',
      ),
    );

    expect(events, contains('POST_JOB_SUBMIT_TAP'));
    expect(events, contains('POST_JOB_SUBMIT_REQUEST_START'));
    expect(
      events.indexOf('POST_JOB_SUBMIT_TAP'),
      lessThan(events.indexOf('POST_JOB_SUBMIT_REQUEST_START')),
    );
    expect(requestStartContext['traceId'], traceId);
    expect(requestStartContext['route'], '/jobs/post');
    expect(requestStartContext['module'], 'jobs');
    expect(requestStartContext['feature'], 'post_job');
    expect(requestStartContext['action'], 'POST_JOB_SUBMIT_TAP');
    expect(requestStartContext.containsKey('editingJobId'), isFalse);
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

    final List<Map<String, Object?>> entries = await readEntriesByTraceId(
      traceId,
    );
    final List<String> events = readEvents(entries);
    final Map<String, Object?> validateFailContext = readContext(
      entries.lastWhere(
        (Map<String, Object?> item) => item['event'] == 'POST_JOB_VALIDATE_FAIL',
      ),
    );

    expect(events, contains('POST_JOB_SUBMIT_TAP'));
    expect(events, contains('POST_JOB_VALIDATE_FAIL'));
    expect(events, isNot(contains('POST_JOB_SUBMIT_REQUEST_START')));
    expect(validateFailContext['reason'], 'title_required');
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

    final List<Map<String, Object?>> entries = await readEntriesByTraceId(
      traceId,
    );
    final List<String> events = readEvents(entries);
    final Map<String, Object?> requestFailContext = readContext(
      entries.lastWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'POST_JOB_SUBMIT_REQUEST_FAIL',
      ),
    );

    expect(events, contains('POST_JOB_SUBMIT_REQUEST_START'));
    expect(events, contains('POST_JOB_SUBMIT_REQUEST_FAIL'));
    expect(requestFailContext['traceId'], traceId);
    expect(requestFailContext['editingJobId'], '99');
    expect(requestFailContext['mode'], 'edit');
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
