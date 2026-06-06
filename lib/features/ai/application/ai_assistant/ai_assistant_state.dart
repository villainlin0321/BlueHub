import '../../../jobs/data/job_models.dart';

const Object _aiAssistantStateSentinel = Object();
const Object _aiAssistantStateIntSetSentinel = Object();
const Object _aiAssistantMessageSentinel = Object();

enum AiAssistantChatRole { assistant, user }

enum AiAssistantComposerMode { text, voice }

enum AiAssistantVoiceInputState { idle, listening, cancel }

class AiAssistantMessageVM {
  const AiAssistantMessageVM({
    required this.role,
    required this.text,
    required this.footer,
    this.embeddedJob,
    this.isEmbeddedJobLoading = false,
  });

  final AiAssistantChatRole role;
  final String text;
  final String? footer;
  final JobListVO? embeddedJob;
  final bool isEmbeddedJobLoading;

  AiAssistantMessageVM copyWith({
    AiAssistantChatRole? role,
    String? text,
    Object? footer = _aiAssistantMessageSentinel,
    Object? embeddedJob = _aiAssistantMessageSentinel,
    bool? isEmbeddedJobLoading,
  }) {
    return AiAssistantMessageVM(
      role: role ?? this.role,
      text: text ?? this.text,
      footer: identical(footer, _aiAssistantMessageSentinel)
          ? this.footer
          : footer as String?,
      embeddedJob: identical(embeddedJob, _aiAssistantMessageSentinel)
          ? this.embeddedJob
          : embeddedJob as JobListVO?,
      isEmbeddedJobLoading:
          isEmbeddedJobLoading ?? this.isEmbeddedJobLoading,
    );
  }
}

class AiAssistantState {
  const AiAssistantState({
    this.messages = const <AiAssistantMessageVM>[],
    this.currentSessionId,
    this.isHistoryLoading = false,
    this.isSending = false,
    this.composerMode = AiAssistantComposerMode.text,
    this.voiceInputState = AiAssistantVoiceInputState.idle,
    this.voiceSeconds = 0,
    this.recognizedText = '',
    this.applyingJobIds = const <int>{},
    this.appliedJobIds = const <int>{},
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackId = 0,
    this.messageVersion = 0,
  });

  final List<AiAssistantMessageVM> messages;
  final int? currentSessionId;
  final bool isHistoryLoading;
  final bool isSending;
  final AiAssistantComposerMode composerMode;
  final AiAssistantVoiceInputState voiceInputState;
  final int voiceSeconds;
  final String recognizedText;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackId;
  final int messageVersion;

  bool get isVoiceMode => composerMode == AiAssistantComposerMode.voice;
  bool get isVoiceListening =>
      voiceInputState == AiAssistantVoiceInputState.listening;
  bool get isVoiceCancel =>
      voiceInputState == AiAssistantVoiceInputState.cancel;

  AiAssistantState copyWith({
    List<AiAssistantMessageVM>? messages,
    Object? currentSessionId = _aiAssistantStateSentinel,
    bool? isHistoryLoading,
    bool? isSending,
    AiAssistantComposerMode? composerMode,
    AiAssistantVoiceInputState? voiceInputState,
    int? voiceSeconds,
    String? recognizedText,
    Object? applyingJobIds = _aiAssistantStateIntSetSentinel,
    Object? appliedJobIds = _aiAssistantStateIntSetSentinel,
    Object? feedbackMessage = _aiAssistantStateSentinel,
    bool? feedbackIsError,
    int? feedbackId,
    int? messageVersion,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      currentSessionId: identical(currentSessionId, _aiAssistantStateSentinel)
          ? this.currentSessionId
          : currentSessionId as int?,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      isSending: isSending ?? this.isSending,
      composerMode: composerMode ?? this.composerMode,
      voiceInputState: voiceInputState ?? this.voiceInputState,
      voiceSeconds: voiceSeconds ?? this.voiceSeconds,
      recognizedText: recognizedText ?? this.recognizedText,
      applyingJobIds: identical(
            applyingJobIds,
            _aiAssistantStateIntSetSentinel,
          )
          ? this.applyingJobIds
          : applyingJobIds as Set<int>,
      appliedJobIds: identical(appliedJobIds, _aiAssistantStateIntSetSentinel)
          ? this.appliedJobIds
          : appliedJobIds as Set<int>,
      feedbackMessage: identical(feedbackMessage, _aiAssistantStateSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackId: feedbackId ?? this.feedbackId,
      messageVersion: messageVersion ?? this.messageVersion,
    );
  }
}
