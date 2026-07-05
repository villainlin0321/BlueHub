import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:europepass/features/message/application/message_session/message_session_controller.dart';
import 'package:europepass/features/message/application/message_session/message_session_state.dart';
import 'package:europepass/features/messages/data/message_models.dart';
import 'package:europepass/features/messages/data/message_providers.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/services/message_service.dart';
import 'package:europepass/shared/network/sse_client.dart';
import 'package:europepass/shared/network/sse_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证消息会话链路会补齐启动、SSE 异常和已读同步失败的结构化事件。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;

  /// 读取当前日志文件中的结构化日志，便于断言事件名和上下文字段。
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

  /// 从结构化日志中安全读取上下文字段。
  Map<String, Object?> readContext(Map<String, Object?> entry) {
    return Map<String, Object?>.from(entry['context']! as Map);
  }

  /// 等待日志刷盘和异步状态更新，避免断言读到中间态。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_message_session_logging_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory.path;
          }
          return tempDirectory.path;
        });
    await AppLogger.instance.init();
    await waitForLogFlush();
  });

  tearDownAll(() async {
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('startSession 会输出启动成功与刷新成功事件', () async {
    final _FakeMessageService messageService = _FakeMessageService();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        messageServiceProvider.overrideWithValue(messageService),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<MessageSessionState> subscription = container
        .listen(
          messageSessionControllerProvider,
          (MessageSessionState? previous, MessageSessionState next) {},
          fireImmediately: true,
        );
    addTearDown(subscription.close);

    await AppLogScope.run<Future<void>>(
      traceId: 'test-message-session-start',
      fields: const <String, Object?>{'testCase': 'message_session_start'},
      action: () {
        return container.read(messageSessionControllerProvider.notifier)
            .startSession();
      },
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries.where((
      Map<String, Object?> item,
    ) {
      final Map<String, Object?>? context =
          item['context'] == null ? null : readContext(item);
      return context?['traceId'] == 'test-message-session-start' &&
          (item['event'] == 'MESSAGE_SESSION_START' ||
              item['event'] == 'MESSAGE_SESSION_SUCCESS' ||
              item['event'] == 'MESSAGE_REFRESH_SUCCESS');
    }).toList();

    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'MESSAGE_SESSION_START';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'MESSAGE_SESSION_SUCCESS';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'MESSAGE_REFRESH_SUCCESS';
      }),
      isTrue,
    );
  });

  test('markConversationRead 失败时会输出已读同步失败事件', () async {
    final _FakeMessageService messageService = _FakeMessageService(
      failMarkReadConversationIds: const <int>{1001},
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        messageServiceProvider.overrideWithValue(messageService),
      ],
    );
    addTearDown(container.dispose);

    await AppLogScope.run<Future<void>>(
      traceId: 'test-message-read-sync-fail',
      fields: const <String, Object?>{'testCase': 'mark_read_fail'},
      action: () async {
        final MessageSessionController controller =
            container.read(messageSessionControllerProvider.notifier);
        await controller.startSession();
        await controller.markConversationRead(1001);
      },
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final Map<String, Object?> failEntry = entries.firstWhere(
      (Map<String, Object?> item) {
        final Map<String, Object?>? context =
            item['context'] == null ? null : readContext(item);
        return context?['traceId'] == 'test-message-read-sync-fail' &&
            item['event'] == 'MESSAGE_READ_SYNC_FAIL';
      },
    );
    final Map<String, Object?> failContext = readContext(failEntry);
    expect(failContext['conversationId'], '1001');
    expect(failContext['mode'], 'single');
  });

  test('SSE 收包和解析异常都会输出结构化失败事件', () async {
    final _FakeMessageService messageService = _FakeMessageService();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        messageServiceProvider.overrideWithValue(messageService),
      ],
    );
    addTearDown(container.dispose);

    await AppLogScope.run<Future<void>>(
      traceId: 'test-message-sse-fail',
      fields: const <String, Object?>{'testCase': 'message_sse_fail'},
      action: () async {
        final MessageSessionController controller =
            container.read(messageSessionControllerProvider.notifier);
        await controller.startSession();
        messageService.emitSseEvent(
          const SseEvent(
            id: 'evt-parse-fail',
            event: 'conversation.message',
            data: 'not-json',
          ),
        );
        messageService.emitSseError(
          StateError('stream-failed'),
          StackTrace.current,
        );
      },
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final Map<String, Object?> parseFailEntry = entries.firstWhere(
      (Map<String, Object?> item) {
        final Map<String, Object?>? context =
            item['context'] == null ? null : readContext(item);
        return context?['traceId'] == 'test-message-sse-fail' &&
            item['event'] == 'MESSAGE_SSE_PARSE_FAIL';
      },
    );
    final Map<String, Object?> streamFailEntry = entries.firstWhere(
      (Map<String, Object?> item) {
        final Map<String, Object?>? context =
            item['context'] == null ? null : readContext(item);
        return context?['traceId'] == 'test-message-sse-fail' &&
            item['event'] == 'MESSAGE_SSE_STREAM_FAIL';
      },
    );

    expect(readContext(parseFailEntry)['sseEvent'], 'conversation.message');
    expect(readContext(parseFailEntry)['sseId'], 'evt-parse-fail');
    expect(readContext(streamFailEntry)['phase'], 'stream');
  });
}

/// 构造消息控制器测试所需的最小消息服务替身，避免依赖真实网络和 SSE。
class _FakeMessageService extends MessageService {
  _FakeMessageService({this.failMarkReadConversationIds = const <int>{}})
    : _sseController = StreamController<SseEvent>.broadcast(),
      super(
        apiClient: ApiClient(Dio()),
        sseClient: SseClient(baseUrl: '', tokenStore: TokenStore.inMemory()),
      );

  final StreamController<SseEvent> _sseController;
  final Set<int> failMarkReadConversationIds;

  /// 向当前 SSE 订阅主动推送一条事件，供测试覆盖解析分支。
  void emitSseEvent(SseEvent event) {
    _sseController.add(event);
  }

  /// 主动推送 SSE 流异常，覆盖 onError 的结构化日志分支。
  void emitSseError(Object error, StackTrace stackTrace) {
    _sseController.addError(error, stackTrace);
  }

  @override
  /// 返回预设的会话列表，保证控制器能进入正常启动态。
  Future<PageResult<ConversationVO>> listConversations({
    int? page,
    int? pageSize,
  }) async {
    return PageResult<ConversationVO>(
      list: const <ConversationVO>[
        ConversationVO(
          conversationId: 1001,
          targetUser: TargetUserVO(
            userId: 2001,
            nickname: '测试用户',
            avatarUrl: '',
            role: 'worker',
            isOnline: true,
          ),
          relatedOrder: null,
          lastMessage: LastMessageVO(
            content: '你好',
            type: 'text',
            sentAt: '2026-07-05T00:00:00Z',
            isRead: false,
          ),
          unreadCount: 2,
        ),
      ],
      pagination: const Pagination(
        page: 1,
        total: 1,
        pageSize: 50,
        totalPages: 1,
        hasNext: false,
      ),
    );
  }

  @override
  /// 返回可控的 SSE 流，供测试模拟收包与流异常。
  Stream<SseEvent> connectConversationStream() {
    return _sseController.stream;
  }

  @override
  /// 按需抛出已读同步异常，覆盖失败日志分支。
  Future<void> markRead({required int conversationId}) async {
    if (failMarkReadConversationIds.contains(conversationId)) {
      throw StateError('mark-read-failed');
    }
  }

  @override
  /// 关闭测试用 SSE 控制器，避免流资源泄漏。
  Future<void> closeConversationStream() async {
    await _sseController.close();
  }
}
