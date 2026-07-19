import '../../../../shared/network/sse_models.dart';
import '../../../messages/data/message_models.dart';

const Object _messageSessionStateSentinel = Object();

class MessageSessionState {
  const MessageSessionState({
    this.conversations = const <ConversationVO>[],
    this.notifications = const <NotificationVO>[],
    this.isInitializing = false,
    this.isNotificationsInitializing = false,
    this.hasStarted = false,
    this.loadErrorMessage,
    this.notificationLoadErrorMessage,
    this.latestEventToken = 0,
    this.latestEvent,
    this.notificationLatestEventToken = 0,
    this.latestNotificationEvent,
  });

  final List<ConversationVO> conversations;
  final List<NotificationVO> notifications;
  final bool isInitializing;
  final bool isNotificationsInitializing;
  final bool hasStarted;
  final String? loadErrorMessage;
  final String? notificationLoadErrorMessage;
  final int latestEventToken;
  final SseEvent? latestEvent;
  final int notificationLatestEventToken;
  final SseEvent? latestNotificationEvent;

  bool get hasUnreadConversations =>
      conversations.any((ConversationVO item) => item.unreadCount > 0);

  bool get hasUnreadNotifications =>
      notifications.any((NotificationVO item) => !item.isRead);

  bool get hasUnreadMessages =>
      hasUnreadConversations || hasUnreadNotifications;

  bool get hasLoadedOnce => hasStarted && !isInitializing;

  MessageSessionState copyWith({
    List<ConversationVO>? conversations,
    List<NotificationVO>? notifications,
    bool? isInitializing,
    bool? isNotificationsInitializing,
    bool? hasStarted,
    Object? loadErrorMessage = _messageSessionStateSentinel,
    Object? notificationLoadErrorMessage = _messageSessionStateSentinel,
    int? latestEventToken,
    Object? latestEvent = _messageSessionStateSentinel,
    int? notificationLatestEventToken,
    Object? latestNotificationEvent = _messageSessionStateSentinel,
  }) {
    return MessageSessionState(
      conversations: conversations ?? this.conversations,
      notifications: notifications ?? this.notifications,
      isInitializing: isInitializing ?? this.isInitializing,
      isNotificationsInitializing:
          isNotificationsInitializing ?? this.isNotificationsInitializing,
      hasStarted: hasStarted ?? this.hasStarted,
      loadErrorMessage:
          identical(loadErrorMessage, _messageSessionStateSentinel)
          ? this.loadErrorMessage
          : loadErrorMessage as String?,
      notificationLoadErrorMessage:
          identical(notificationLoadErrorMessage, _messageSessionStateSentinel)
          ? this.notificationLoadErrorMessage
          : notificationLoadErrorMessage as String?,
      latestEventToken: latestEventToken ?? this.latestEventToken,
      latestEvent: identical(latestEvent, _messageSessionStateSentinel)
          ? this.latestEvent
          : latestEvent as SseEvent?,
      notificationLatestEventToken:
          notificationLatestEventToken ?? this.notificationLatestEventToken,
      latestNotificationEvent:
          identical(latestNotificationEvent, _messageSessionStateSentinel)
          ? this.latestNotificationEvent
          : latestNotificationEvent as SseEvent?,
    );
  }
}
