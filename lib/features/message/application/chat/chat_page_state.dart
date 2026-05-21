import '../../../messages/data/message_models.dart';

const Object _chatPageStateSentinel = Object();

class ChatPageState {
  const ChatPageState({
    this.conversationId = 0,
    this.messages = const <MessageVO>[],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.hasMore = true,
    this.loadErrorMessage,
    this.feedbackMessage,
    this.feedbackId = 0,
    this.newestMessageToken = 0,
    this.clearComposerToken = 0,
  });

  final int conversationId;
  final List<MessageVO> messages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isSending;
  final bool hasMore;
  final String? loadErrorMessage;
  final String? feedbackMessage;
  final int feedbackId;
  final int newestMessageToken;
  final int clearComposerToken;

  ChatPageState copyWith({
    int? conversationId,
    List<MessageVO>? messages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? hasMore,
    Object? loadErrorMessage = _chatPageStateSentinel,
    Object? feedbackMessage = _chatPageStateSentinel,
    int? feedbackId,
    int? newestMessageToken,
    int? clearComposerToken,
  }) {
    return ChatPageState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      loadErrorMessage: identical(loadErrorMessage, _chatPageStateSentinel)
          ? this.loadErrorMessage
          : loadErrorMessage as String?,
      feedbackMessage: identical(feedbackMessage, _chatPageStateSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackId: feedbackId ?? this.feedbackId,
      newestMessageToken: newestMessageToken ?? this.newestMessageToken,
      clearComposerToken: clearComposerToken ?? this.clearComposerToken,
    );
  }
}
