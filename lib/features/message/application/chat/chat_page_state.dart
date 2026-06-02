import '../../../messages/data/message_models.dart';

const Object _chatPageStateSentinel = Object();
const Object _chatPageStateIntSetSentinel = Object();

enum ChatComposerMode { text, voice }

enum ChatVoiceRecordingState { idle, recording, cancel }

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
    this.composerMode = ChatComposerMode.text,
    this.recordingState = ChatVoiceRecordingState.idle,
    this.recordingSeconds = 0,
    this.playingMessageId,
    this.downloadingAudioMessageIds = const <int>{},
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
  final ChatComposerMode composerMode;
  final ChatVoiceRecordingState recordingState;
  final int recordingSeconds;
  final int? playingMessageId;
  final Set<int> downloadingAudioMessageIds;

  bool get isVoiceMode => composerMode == ChatComposerMode.voice;
  bool get isRecording => recordingState == ChatVoiceRecordingState.recording;
  bool get isRecordingCancel =>
      recordingState == ChatVoiceRecordingState.cancel;

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
    ChatComposerMode? composerMode,
    ChatVoiceRecordingState? recordingState,
    int? recordingSeconds,
    Object? playingMessageId = _chatPageStateSentinel,
    Object? downloadingAudioMessageIds = _chatPageStateIntSetSentinel,
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
      composerMode: composerMode ?? this.composerMode,
      recordingState: recordingState ?? this.recordingState,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      playingMessageId: identical(playingMessageId, _chatPageStateSentinel)
          ? this.playingMessageId
          : playingMessageId as int?,
      downloadingAudioMessageIds: identical(
            downloadingAudioMessageIds,
            _chatPageStateIntSetSentinel,
          )
          ? this.downloadingAudioMessageIds
          : downloadingAudioMessageIds as Set<int>,
    );
  }
}
