import '../../../../shared/network/sse_models.dart';
import '../../../messages/data/message_models.dart';

const Object _messageSessionStateSentinel = Object();

class MessageSessionState {
  const MessageSessionState({
    this.conversations = const <ConversationVO>[],
    this.isInitializing = false,
    this.hasStarted = false,
    this.loadErrorMessage,
    this.latestEventToken = 0,
    this.latestEvent,
  });

  final List<ConversationVO> conversations;
  final bool isInitializing;
  final bool hasStarted;
  final String? loadErrorMessage;
  final int latestEventToken;
  final SseEvent? latestEvent;

  bool get hasUnreadConversations =>
      conversations.any((ConversationVO item) => item.unreadCount > 0);

  bool get hasLoadedOnce => hasStarted && !isInitializing;

  MessageSessionState copyWith({
    List<ConversationVO>? conversations,
    bool? isInitializing,
    bool? hasStarted,
    Object? loadErrorMessage = _messageSessionStateSentinel,
    int? latestEventToken,
    Object? latestEvent = _messageSessionStateSentinel,
  }) {
    return MessageSessionState(
      conversations: conversations ?? this.conversations,
      isInitializing: isInitializing ?? this.isInitializing,
      hasStarted: hasStarted ?? this.hasStarted,
      loadErrorMessage:
          identical(loadErrorMessage, _messageSessionStateSentinel)
          ? this.loadErrorMessage
          : loadErrorMessage as String?,
      latestEventToken: latestEventToken ?? this.latestEventToken,
      latestEvent: identical(latestEvent, _messageSessionStateSentinel)
          ? this.latestEvent
          : latestEvent as SseEvent?,
    );
  }
}
