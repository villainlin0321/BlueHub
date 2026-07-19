import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/logging/app_log_event.dart';
import '../../../../shared/logging/app_log_facade.dart';
import '../../../../shared/logging/app_logger.dart';
import '../../../../shared/network/api_decoders.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/network/services/message_service.dart';
import '../../../../shared/network/sse_models.dart';
import '../../../auth/application/auth_session_provider.dart';
import '../../../messages/data/message_models.dart';
import '../../../messages/data/message_providers.dart';
import 'message_session_state.dart';

final messageSessionControllerProvider =
    NotifierProvider<MessageSessionController, MessageSessionState>(
      MessageSessionController.new,
    );

class MessageSessionController extends Notifier<MessageSessionState> {
  static const int _pageSize = 50;
  static const int _notificationPageSize = 50;
  static int _activeChatConversationId = 0;

  static void setActiveChatConversationId(int conversationId) {
    _activeChatConversationId = conversationId > 0 ? conversationId : 0;
  }

  StreamSubscription<SseEvent>? _sseSubscription;
  StreamSubscription<SseEvent>? _notificationSseSubscription;
  Future<void>? _refreshConversationsFuture;
  bool _isDisposed = false;
  late final MessageService _messageService;
  int _currentUserId = 0;

  @override
  MessageSessionState build() {
    _isDisposed = false;
    _messageService = ref.read(messageServiceProvider);
    _syncCurrentUserId();
    ref.onDispose(() async {
      _isDisposed = true;
      await _disposeSession(closeRemote: false);
    });
    return const MessageSessionState();
  }

  Future<void> startSession() async {
    if (state.hasStarted) {
      return;
    }
    _syncCurrentUserId();
    final int previousCount = state.conversations.length;
    _updateState(
      (MessageSessionState current) => current.copyWith(
        conversations: const <ConversationVO>[],
        notifications: const <NotificationVO>[],
        hasStarted: true,
        isInitializing: true,
        isNotificationsInitializing: true,
        loadErrorMessage: null,
        notificationLoadErrorMessage: null,
      ),
    );
    _logSessionStart(previousCount: previousCount);
    _subscribeConversationSse();
    _subscribeNotificationSse();
    await Future.wait<void>(<Future<void>>[
      refreshConversations(),
      refreshNotifications(),
    ]);
    if (state.loadErrorMessage == null &&
        state.notificationLoadErrorMessage == null) {
      _logSessionSuccess(latestCount: state.conversations.length);
      return;
    }
    _logSessionFail(
      previousCount: previousCount,
      reason: _resolveSessionStartFailureReason(),
    );
  }

  Future<void> stopSession({bool clearState = false}) async {
    await _disposeSession(closeRemote: true);
    if (clearState) {
      _updateState((_) => const MessageSessionState());
      return;
    }
    _updateState(
      (MessageSessionState current) => current.copyWith(
        hasStarted: false,
        isInitializing: false,
        isNotificationsInitializing: false,
        latestEvent: null,
        latestNotificationEvent: null,
      ),
    );
  }

  Future<void> refreshConversations() {
    if (!state.hasStarted) {
      return Future<void>.value();
    }
    final Future<void>? currentRefresh = _refreshConversationsFuture;
    if (currentRefresh != null) {
      return currentRefresh;
    }

    final Future<void> refreshFuture = _performRefreshConversations();
    _refreshConversationsFuture = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_refreshConversationsFuture, refreshFuture)) {
        _refreshConversationsFuture = null;
      }
    });
  }

  Future<void> _performRefreshConversations() async {
    final int previousCount = state.conversations.length;
    _syncCurrentUserId();
    _updateState(
      (MessageSessionState current) =>
          current.copyWith(isInitializing: true, loadErrorMessage: null),
    );
    _logRefreshStart(previousCount: previousCount);

    try {
      final PageResult<ConversationVO> response = await _messageService
          .listConversations(page: 1, pageSize: _pageSize);
      _logRefreshSuccess(
        previousCount: previousCount,
        latestCount: response.list.length,
      );
      _updateState(
        (MessageSessionState current) => current.copyWith(
          conversations: response.list,
          isInitializing: false,
          loadErrorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      _logRefreshFail(
        previousCount: previousCount,
        error: error,
        stackTrace: stackTrace,
      );
      AppLogger.instance.error(
        'MESSAGE_SESSION',
        '刷新会话列表失败',
        error: error,
        stackTrace: stackTrace,
      );
      _updateState(
        (MessageSessionState current) => current.copyWith(
          isInitializing: false,
          loadErrorMessage: _resolveErrorMessage(error),
        ),
      );
    }
  }

  Future<void> refreshNotifications() async {
    if (!state.hasStarted) {
      return;
    }
    final int previousCount = state.notifications.length;
    _updateState(
      (MessageSessionState current) => current.copyWith(
        isNotificationsInitializing: true,
        notificationLoadErrorMessage: null,
      ),
    );

    try {
      final PageResult<NotificationVO> response = await _messageService
          .listNotifications(page: 1, pageSize: _notificationPageSize);
      _updateState(
        (MessageSessionState current) => current.copyWith(
          notifications: response.list,
          isNotificationsInitializing: false,
          notificationLoadErrorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      _logNotificationRefreshFail(
        previousCount: previousCount,
        error: error,
        stackTrace: stackTrace,
      );
      AppLogger.instance.error(
        'MESSAGE_SESSION',
        '刷新系统通知列表失败',
        error: error,
        stackTrace: stackTrace,
      );
      _updateState(
        (MessageSessionState current) => current.copyWith(
          isNotificationsInitializing: false,
          notificationLoadErrorMessage: _resolveErrorMessage(error),
        ),
      );
    }
  }

  Future<void> markConversationRead(int conversationId) async {
    if (conversationId <= 0) {
      return;
    }
    final int index = state.conversations.indexWhere(
      (ConversationVO item) => item.conversationId == conversationId,
    );
    if (index == -1) {
      return;
    }
    final ConversationVO previous = state.conversations[index];
    if (previous.unreadCount <= 0) {
      return;
    }

    _replaceConversation(previous.copyWith(unreadCount: 0));
    try {
      await _messageService.markRead(conversationId: conversationId);
    } catch (error, stackTrace) {
      _logReadSyncFail(
        conversationId: conversationId,
        unreadCountBefore: previous.unreadCount,
        mode: 'single',
        error: error,
        stackTrace: stackTrace,
      );
      _replaceConversation(previous, moveToFront: false);
    }
  }

  Future<void> markAllConversationsRead(List<int> conversationIds) async {
    if (conversationIds.isEmpty) {
      return;
    }
    final Map<int, ConversationVO> previousById = <int, ConversationVO>{
      for (final ConversationVO item in state.conversations)
        if (conversationIds.contains(item.conversationId))
          item.conversationId: item,
    };
    if (previousById.isEmpty) {
      return;
    }

    final Set<int> targetIds = conversationIds.toSet();
    _updateState((MessageSessionState current) {
      final List<ConversationVO> updated = current.conversations
          .map(
            (ConversationVO item) => targetIds.contains(item.conversationId)
                ? item.copyWith(unreadCount: 0)
                : item,
          )
          .toList(growable: false);
      return current.copyWith(conversations: updated);
    });

    for (final int conversationId in conversationIds) {
      try {
        await _messageService.markRead(conversationId: conversationId);
      } catch (error, stackTrace) {
        _logReadSyncFail(
          conversationId: conversationId,
          unreadCountBefore: previousById[conversationId]?.unreadCount ?? 0,
          mode: 'batch',
          error: error,
          stackTrace: stackTrace,
        );
        final ConversationVO? previous = previousById[conversationId];
        if (previous != null) {
          _replaceConversation(previous, moveToFront: false);
        }
      }
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    if (notificationId <= 0) {
      return;
    }
    final int index = state.notifications.indexWhere(
      (NotificationVO item) => item.notificationId == notificationId,
    );
    if (index == -1) {
      return;
    }
    final NotificationVO previous = state.notifications[index];
    if (previous.isRead) {
      return;
    }
    _replaceNotification(previous.copyWith(isRead: true), moveToFront: false);
    try {
      await _messageService.markNotificationRead(
        notificationId: notificationId,
      );
    } catch (error, stackTrace) {
      _logNotificationReadSyncFail(
        notificationId: notificationId,
        mode: 'single',
        error: error,
        stackTrace: stackTrace,
      );
      _replaceNotification(previous, moveToFront: false);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final List<NotificationVO> unreadItems = state.notifications
        .where((NotificationVO item) => !item.isRead)
        .toList(growable: false);
    if (unreadItems.isEmpty) {
      return;
    }
    _updateState((MessageSessionState current) {
      final List<NotificationVO> updated = current.notifications
          .map((NotificationVO item) => item.copyWith(isRead: true))
          .toList(growable: false);
      return current.copyWith(notifications: updated);
    });
    try {
      await _messageService.markAllNotificationsRead();
    } catch (error, stackTrace) {
      _logNotificationReadSyncFail(
        notificationId: 0,
        mode: 'batch',
        error: error,
        stackTrace: stackTrace,
      );
      await refreshNotifications();
    }
  }

  void _subscribeConversationSse() {
    _sseSubscription?.cancel();
    _sseSubscription = _messageService.connectConversationStream().listen(
      _handleConversationEvent,
      onError: (Object error, StackTrace stackTrace) {
        _logSseStreamFail(
          error: error,
          stackTrace: stackTrace,
          phase: 'stream',
        );
      },
    );
  }

  void _subscribeNotificationSse() {
    _notificationSseSubscription?.cancel();
    _notificationSseSubscription = _messageService
        .connectNotificationStream()
        .listen(
          _handleNotificationEvent,
          onError: (Object error, StackTrace stackTrace) {
            _logNotificationSseStreamFail(
              error: error,
              stackTrace: stackTrace,
              phase: 'stream',
            );
          },
        );
  }

  void _handleConversationEvent(SseEvent event) {
    if (_isDisposed || !state.hasStarted) {
      return;
    }
    _updateState(
      (MessageSessionState current) => current.copyWith(
        latestEventToken: current.latestEventToken + 1,
        latestEvent: event,
      ),
    );
    if (!event.hasData) {
      return;
    }

    try {
      final JsonMap payload = _extractPayload(event);
      if (payload.isEmpty) {
        return;
      }
      final JsonMap messageJson = _extractMessageJson(payload);
      final int conversationId = _extractConversationId(
        payload,
        messageJson: messageJson,
      );
      if (conversationId <= 0) {
        return;
      }
      final int index = state.conversations.indexWhere(
        (ConversationVO item) => item.conversationId == conversationId,
      );
      if (index == -1) {
        unawaited(refreshConversations());
        return;
      }

      final ConversationVO current = state.conversations[index];
      final MessageVO? message = _parseMessage(
        messageJson,
        conversationId: conversationId,
      );
      final bool isActiveChatConversation = _isActiveChatConversation(
        conversationId,
      );
      final ConversationVO updated = current.copyWith(
        lastMessage: message == null
            ? current.lastMessage
            : current.lastMessage.copyWith(
                content: message.content,
                type: message.type,
                sentAt: message.sentAt,
                isRead: message.isRead,
              ),
        unreadCount: isActiveChatConversation
            ? 0
            : _resolveUnreadCount(current, message, payload),
        relatedOrder: _extractRelatedOrder(payload) ?? current.relatedOrder,
      );
      _replaceConversation(updated);
    } catch (error, stackTrace) {
      _logSseParseFail(event: event, error: error, stackTrace: stackTrace);
    }
  }

  void _handleNotificationEvent(SseEvent event) {
    if (_isDisposed || !state.hasStarted) {
      return;
    }
    _updateState(
      (MessageSessionState current) => current.copyWith(
        notificationLatestEventToken: current.notificationLatestEventToken + 1,
        latestNotificationEvent: event,
      ),
    );
    if (!event.hasData) {
      return;
    }

    try {
      final JsonMap payload = _extractPayload(event);
      if (payload.isEmpty) {
        return;
      }
      final NotificationVO? notification = _parseNotification(payload);
      if (notification == null) {
        unawaited(refreshNotifications());
        return;
      }
      _replaceNotification(notification);
    } catch (error, stackTrace) {
      _logNotificationSseParseFail(
        event: event,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _disposeSession({required bool closeRemote}) async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    await _notificationSseSubscription?.cancel();
    _notificationSseSubscription = null;
    if (!closeRemote) {
      return;
    }
    try {
      await Future.wait<void>(<Future<void>>[
        _messageService.closeConversationStream(),
        _messageService.closeNotificationStream(),
      ]);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'MESSAGE_SESSION',
        '关闭会话 SSE 失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _replaceConversation(
    ConversationVO conversation, {
    bool moveToFront = true,
  }) {
    _updateState((MessageSessionState current) {
      final List<ConversationVO> items = List<ConversationVO>.from(
        current.conversations,
      );
      final int index = items.indexWhere(
        (ConversationVO item) =>
            item.conversationId == conversation.conversationId,
      );
      if (index == -1) {
        return current;
      }
      items.removeAt(index);
      if (moveToFront) {
        items.insert(0, conversation);
      } else {
        items.insert(index, conversation);
      }
      return current.copyWith(conversations: items);
    });
  }

  void _replaceNotification(
    NotificationVO notification, {
    bool moveToFront = true,
  }) {
    _updateState((MessageSessionState current) {
      final List<NotificationVO> items = List<NotificationVO>.from(
        current.notifications,
      );
      final int index = items.indexWhere(
        (NotificationVO item) =>
            item.notificationId == notification.notificationId,
      );
      if (index != -1) {
        items.removeAt(index);
      }
      if (moveToFront || index == -1) {
        items.insert(0, notification);
      } else {
        items.insert(index, notification);
      }
      return current.copyWith(notifications: items);
    });
  }

  JsonMap _extractPayload(SseEvent event) {
    final dynamic decoded = jsonDecode(event.data);
    final JsonMap root = asJsonMap(decoded);
    final JsonMap payload = asJsonMap(root['data']);
    if (payload.isNotEmpty) {
      return payload;
    }
    return root;
  }

  JsonMap _extractMessageJson(JsonMap payload) {
    if (payload['messageId'] != null) {
      return payload;
    }
    final JsonMap message = asJsonMap(payload['message']);
    if (message.isNotEmpty) {
      return message;
    }
    return asJsonMap(payload['data']);
  }

  int _extractConversationId(JsonMap payload, {JsonMap? messageJson}) {
    final int directConversationId = readInt(payload, 'conversationId');
    if (directConversationId > 0) {
      return directConversationId;
    }

    final int snakeConversationId = readInt(payload, 'conversation_id');
    if (snakeConversationId > 0) {
      return snakeConversationId;
    }

    final JsonMap conversation = asJsonMap(payload['conversation']);
    final int nestedConversationId = readInt(conversation, 'conversationId');
    if (nestedConversationId > 0) {
      return nestedConversationId;
    }

    final int nestedSnakeConversationId = readInt(
      conversation,
      'conversation_id',
    );
    if (nestedSnakeConversationId > 0) {
      return nestedSnakeConversationId;
    }

    final JsonMap payloadData = asJsonMap(payload['data']);
    final int dataConversationId = readInt(payloadData, 'conversationId');
    if (dataConversationId > 0) {
      return dataConversationId;
    }

    final int dataSnakeConversationId = readInt(payloadData, 'conversation_id');
    if (dataSnakeConversationId > 0) {
      return dataSnakeConversationId;
    }

    final JsonMap message = messageJson ?? const <String, dynamic>{};
    final int messageConversationId = readInt(message, 'conversationId');
    if (messageConversationId > 0) {
      return messageConversationId;
    }

    final int messageSnakeConversationId = readInt(message, 'conversation_id');
    if (messageSnakeConversationId > 0) {
      return messageSnakeConversationId;
    }

    final JsonMap messageConversation = asJsonMap(message['conversation']);
    final int nestedMessageConversationId = readInt(
      messageConversation,
      'conversationId',
    );
    if (nestedMessageConversationId > 0) {
      return nestedMessageConversationId;
    }

    return readInt(messageConversation, 'conversation_id');
  }

  MessageVO? _parseMessage(JsonMap messageJson, {required int conversationId}) {
    if (messageJson.isEmpty || messageJson['messageId'] == null) {
      return null;
    }

    final JsonMap normalizedMessage = <String, dynamic>{
      ...messageJson,
      if (readInt(messageJson, 'conversationId') <= 0 &&
          readInt(messageJson, 'conversation_id') <= 0)
        'conversationId': conversationId,
    };
    return MessageVO.fromJson(normalizedMessage);
  }

  NotificationVO? _parseNotification(JsonMap payload) {
    final JsonMap notificationJson = _extractNotificationJson(payload);
    if (notificationJson.isEmpty) {
      return null;
    }
    final int notificationId = readInt(notificationJson, 'notificationId');
    if (notificationId <= 0) {
      return null;
    }
    return NotificationVO.fromJson(notificationJson);
  }

  JsonMap _extractNotificationJson(JsonMap payload) {
    if (payload['notificationId'] != null) {
      return payload;
    }
    final JsonMap notification = asJsonMap(payload['notification']);
    if (notification.isNotEmpty) {
      return notification;
    }
    final JsonMap payloadData = asJsonMap(payload['data']);
    if (payloadData['notificationId'] != null) {
      return payloadData;
    }
    final JsonMap nestedNotification = asJsonMap(payloadData['notification']);
    if (nestedNotification.isNotEmpty) {
      return nestedNotification;
    }
    return const <String, dynamic>{};
  }

  bool _isActiveChatConversation(int conversationId) {
    return conversationId > 0 && conversationId == _activeChatConversationId;
  }

  RelatedOrderVO? _extractRelatedOrder(JsonMap payload) {
    final JsonMap direct = asJsonMap(payload['relatedOrder']);
    if (direct.isNotEmpty) {
      return RelatedOrderVO.fromJson(direct);
    }
    final JsonMap conversation = asJsonMap(payload['conversation']);
    final JsonMap nested = asJsonMap(conversation['relatedOrder']);
    if (nested.isNotEmpty) {
      return RelatedOrderVO.fromJson(nested);
    }
    return null;
  }

  int _resolveUnreadCount(
    ConversationVO current,
    MessageVO? message,
    JsonMap payload,
  ) {
    final int directUnreadCount = _readUnreadCount(payload);
    if (directUnreadCount >= 0) {
      return directUnreadCount;
    }
    if (message == null) {
      return current.unreadCount;
    }
    if (message.senderId == _currentUserId) {
      return current.unreadCount;
    }
    return current.unreadCount + 1;
  }

  int _readUnreadCount(JsonMap payload) {
    if (payload.containsKey('unreadCount')) {
      return readInt(payload, 'unreadCount', fallback: 0);
    }
    if (payload.containsKey('unread_count')) {
      return readInt(payload, 'unread_count', fallback: 0);
    }
    final JsonMap conversation = asJsonMap(payload['conversation']);
    if (conversation.containsKey('unreadCount')) {
      return readInt(conversation, 'unreadCount', fallback: 0);
    }
    if (conversation.containsKey('unread_count')) {
      return readInt(conversation, 'unread_count', fallback: 0);
    }
    return -1;
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return tr('消息.消息加载失败');
  }

  String _resolveSessionStartFailureReason() {
    final List<String> reasons = <String>[
      if (state.loadErrorMessage != null && state.loadErrorMessage!.isNotEmpty)
        state.loadErrorMessage!,
      if (state.notificationLoadErrorMessage != null &&
          state.notificationLoadErrorMessage!.isNotEmpty)
        state.notificationLoadErrorMessage!,
    ];
    if (reasons.isEmpty) {
      return tr('消息.消息加载失败');
    }
    return reasons.join(' | ');
  }

  void _syncCurrentUserId() {
    _currentUserId = ref.read(authSessionProvider).user?.userId ?? 0;
  }

  void _updateState(
    MessageSessionState Function(MessageSessionState current) updater,
  ) {
    if (_isDisposed) {
      return;
    }
    state = updater(state);
  }

  /// 记录会话刷新开始事件，补齐当前分页和现有会话数量上下文。
  void _logRefreshStart({required int previousCount}) {
    StateLog.transition(
      event: 'MESSAGE_REFRESH_START',
      message: '开始刷新会话列表',
      result: AppLogResult.pending,
      context: _buildRefreshLogContext(previousCount: previousCount),
    );
  }

  /// 记录会话刷新成功事件，便于回放本次刷新拉回了多少条会话。
  void _logRefreshSuccess({
    required int previousCount,
    required int latestCount,
  }) {
    StateLog.transition(
      event: 'MESSAGE_REFRESH_SUCCESS',
      message: '会话列表刷新成功',
      result: AppLogResult.success,
      context: _buildRefreshLogContext(
        previousCount: previousCount,
        latestCount: latestCount,
      ),
    );
  }

  /// 记录会话刷新失败事件，并保留错误对象与分页上下文用于排障。
  void _logRefreshFail({
    required int previousCount,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'MESSAGE_REFRESH_FAIL',
      message: '会话列表刷新失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: _buildRefreshLogContext(previousCount: previousCount),
    );
  }

  /// 构建会话刷新日志上下文，统一补齐分页和数量摘要字段。
  Map<String, Object?> _buildRefreshLogContext({
    required int previousCount,
    int? latestCount,
  }) {
    return <String, Object?>{
      'page': 1,
      'pageSize': _pageSize,
      'conversationCountBefore': previousCount,
      if (latestCount != null) 'conversationCountAfter': latestCount,
      if (_currentUserId > 0) 'currentUserId': _currentUserId,
    };
  }

  /// 记录系统通知刷新失败事件，并保留当前通知数量上下文。
  void _logNotificationRefreshFail({
    required int previousCount,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'NOTIFICATION_REFRESH_FAIL',
      message: '系统通知列表刷新失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'page': 1,
        'pageSize': _notificationPageSize,
        'notificationCountBefore': previousCount,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录消息会话启动开始事件，便于把订阅启动和刷新列表串成同一段会话链路。
  void _logSessionStart({required int previousCount}) {
    StateLog.transition(
      event: 'MESSAGE_SESSION_START',
      message: '开始启动消息会话',
      result: AppLogResult.pending,
      context: <String, Object?>{
        'conversationCountBefore': previousCount,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录消息会话启动成功事件，明确当前会话订阅已经可用。
  void _logSessionSuccess({required int latestCount}) {
    StateLog.transition(
      event: 'MESSAGE_SESSION_SUCCESS',
      message: '消息会话启动成功',
      result: AppLogResult.success,
      context: <String, Object?>{
        'conversationCountAfter': latestCount,
        'notificationCountAfter': state.notifications.length,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录消息会话启动失败事件，保留失败原因帮助区分是订阅失败还是列表刷新失败。
  void _logSessionFail({required int previousCount, required String reason}) {
    StateLog.transition(
      event: 'MESSAGE_SESSION_FAIL',
      message: '消息会话启动失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      context: <String, Object?>{
        'conversationCountBefore': previousCount,
        'notificationCountBefore': state.notifications.length,
        'reason': reason,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录已读同步失败事件，统一沉淀单条和批量同步的失败上下文。
  void _logReadSyncFail({
    required int conversationId,
    required int unreadCountBefore,
    required String mode,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'MESSAGE_READ_SYNC_FAIL',
      message: mode == 'batch' ? '批量同步会话已读失败' : '同步单个会话已读失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'conversationId': conversationId,
        'mode': mode,
        'unreadCountBefore': unreadCountBefore,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录 SSE 收包阶段异常，帮助区分流断开、网络错误和业务解析失败。
  void _logSseStreamFail({
    required Object error,
    required StackTrace stackTrace,
    required String phase,
  }) {
    StateLog.transition(
      event: 'MESSAGE_SSE_STREAM_FAIL',
      message: '会话 SSE 收包异常',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'phase': phase,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录 SSE 解析失败事件，保留事件类型和数据摘要便于快速回放异常包。
  void _logSseParseFail({
    required SseEvent event,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'MESSAGE_SSE_PARSE_FAIL',
      message: '解析会话 SSE 事件失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        if ((event.id ?? '').trim().isNotEmpty) 'sseId': event.id,
        if ((event.event ?? '').trim().isNotEmpty) 'sseEvent': event.event,
        if (event.data.trim().isNotEmpty) 'sseDataLength': event.data.length,
      },
    );
  }

  /// 记录系统通知已读同步失败事件。
  void _logNotificationReadSyncFail({
    required int notificationId,
    required String mode,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'NOTIFICATION_READ_SYNC_FAIL',
      message: mode == 'batch' ? '批量同步系统通知已读失败' : '同步单条系统通知已读失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        if (notificationId > 0) 'notificationId': notificationId,
        'mode': mode,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录系统通知 SSE 收包阶段异常。
  void _logNotificationSseStreamFail({
    required Object error,
    required StackTrace stackTrace,
    required String phase,
  }) {
    StateLog.transition(
      event: 'NOTIFICATION_SSE_STREAM_FAIL',
      message: '系统通知 SSE 收包异常',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'phase': phase,
        if (_currentUserId > 0) 'currentUserId': _currentUserId,
      },
    );
  }

  /// 记录系统通知 SSE 解析失败事件。
  void _logNotificationSseParseFail({
    required SseEvent event,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'NOTIFICATION_SSE_PARSE_FAIL',
      message: '解析系统通知 SSE 事件失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        if ((event.id ?? '').trim().isNotEmpty) 'sseId': event.id,
        if ((event.event ?? '').trim().isNotEmpty) 'sseEvent': event.event,
        if (event.data.trim().isNotEmpty) 'sseDataLength': event.data.length,
      },
    );
  }
}
