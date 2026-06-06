import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../shared/network/api_decoders.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/sse_models.dart';
import '../../../jobs/data/application_models.dart';
import '../../../jobs/data/application_providers.dart';
import '../../../jobs/data/job_models.dart';
import '../../../jobs/data/job_providers.dart';
import '../../data/ai_models.dart';
import '../../data/ai_providers.dart';
import 'ai_assistant_state.dart';

final aiAssistantControllerProvider =
    NotifierProvider.autoDispose<AiAssistantController, AiAssistantState>(
      AiAssistantController.new,
    );

class AiAssistantController extends Notifier<AiAssistantState> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  Timer? _voiceTimer;
  bool _isDisposed = false;
  bool _hasBootstrapped = false;
  final Map<int, JobListVO?> _pendingEmbeddedJobs = <int, JobListVO?>{};

  @override
  AiAssistantState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _voiceTimer?.cancel();
      unawaited(_speechToText.cancel());
    });
    return const AiAssistantState();
  }

  Future<void> bootstrap({required int? sessionId}) async {
    if (_hasBootstrapped) {
      return;
    }
    _hasBootstrapped = true;
    if (_hasValidSessionId(sessionId)) {
      await loadSessionHistory(sessionId!);
      return;
    }
    _showDefaultConversation();
    await _loadRecommendedJob();
  }

  Future<void> loadSessionHistory(int sessionId) async {
    _updateState((AiAssistantState current) {
      return current.copyWith(isHistoryLoading: true);
    });

    try {
      final List<AiMessageVO> history = await ref
          .read(aiServiceProvider)
          .getChatHistory(sessionId: sessionId);
      history.sort(
        (AiMessageVO left, AiMessageVO right) =>
            left.aiMsgId.compareTo(right.aiMsgId),
      );
      if (_isDisposed) {
        return;
      }
      _updateState((AiAssistantState current) {
        return current.copyWith(
          currentSessionId: sessionId,
          isHistoryLoading: false,
          messages: history.map(_mapHistoryMessage).toList(growable: false),
          messageVersion: current.messageVersion + 1,
        );
      });
    } catch (_) {
      _updateState((AiAssistantState current) {
        return current.copyWith(isHistoryLoading: false);
      });
    }
  }

  Future<void> resetToDefaultConversation() async {
    _showDefaultConversation();
    await _loadRecommendedJob();
  }

  Future<void> sendText(String rawText, {required String language}) async {
    final String text = rawText.trim();
    if (text.isEmpty || state.isSending) {
      return;
    }

    final List<AiAssistantMessageVM> nextMessages =
        List<AiAssistantMessageVM>.from(state.messages)
          ..add(
            const AiAssistantMessageVM(
              role: AiAssistantChatRole.user,
              text: '',
              footer: null,
            ).copyWith(text: text),
          )
          ..add(
            const AiAssistantMessageVM(
              role: AiAssistantChatRole.assistant,
              text: '',
              footer: '',
            ),
          );
    final int assistantIndex = nextMessages.length - 1;
    _pendingEmbeddedJobs.remove(assistantIndex);

    _updateState((AiAssistantState current) {
      return current.copyWith(
        messages: nextMessages,
        isSending: true,
        feedbackMessage: null,
        feedbackIsError: false,
        messageVersion: current.messageVersion + 1,
      );
    });

    try {
      await for (final SseEvent event
          in ref.read(aiServiceProvider).chat(
                request: AiChatBO(
                  sessionId: state.currentSessionId,
                  message: text,
                  contextType: 'job_match',
                  language: language,
                ),
              )) {
        if (_isDisposed) {
          return;
        }
        _handleChatEvent(event, assistantIndex: assistantIndex);
      }
    } catch (error) {
      _emitFeedback(error.toString(), isError: true);
      _removeEmptyAssistantMessage(assistantIndex);
    } finally {
      _updateState((AiAssistantState current) {
        return current.copyWith(isSending: false);
      });
    }
  }

  void toggleComposerMode() {
    if (state.isSending || state.isVoiceListening) {
      return;
    }
    _updateState((AiAssistantState current) {
      final AiAssistantComposerMode nextMode = current.isVoiceMode
          ? AiAssistantComposerMode.text
          : AiAssistantComposerMode.voice;
      return current.copyWith(
        composerMode: nextMode,
        voiceInputState: AiAssistantVoiceInputState.idle,
        voiceSeconds: 0,
        recognizedText: '',
      );
    });
  }

  Future<void> startVoiceInput({required bool isChineseLocale}) async {
    if (state.isSending || state.isVoiceListening) {
      return;
    }

    final bool initialized = await _speechToText.initialize(
      onStatus: (_) {},
      onError: (error) {
        if (_isDisposed) {
          return;
        }
        if (state.voiceInputState == AiAssistantVoiceInputState.idle) {
          return;
        }
        _resetVoiceInputState();
        _emitFeedback(error.errorMsg, isError: true);
      },
    );
    if (_isDisposed) {
      return;
    }
    if (!initialized) {
      _emitFeedback('语音识别不可用，请检查麦克风和语音识别权限', isError: true);
      return;
    }

    final String? speechLocaleId = await _resolveSpeechLocaleId(
      isChineseLocale: isChineseLocale,
    );
    if (_isDisposed) {
      return;
    }

    _voiceTimer?.cancel();
    _updateState((AiAssistantState current) {
      return current.copyWith(
        voiceInputState: AiAssistantVoiceInputState.listening,
        voiceSeconds: 0,
        recognizedText: '',
      );
    });
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_isDisposed || state.voiceInputState != AiAssistantVoiceInputState.listening) {
        timer.cancel();
        return;
      }
      _updateState((AiAssistantState current) {
        return current.copyWith(voiceSeconds: current.voiceSeconds + 1);
      });
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (_isDisposed) {
            return;
          }
          _updateState((AiAssistantState current) {
            return current.copyWith(
              recognizedText: result.recognizedWords.trim(),
            );
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          localeId: speechLocaleId,
        ),
      );
    } catch (error) {
      _resetVoiceInputState();
      _emitFeedback(error.toString(), isError: true);
    }
  }

  void updateVoiceDrag(LongPressMoveUpdateDetails details) {
    if (state.voiceInputState == AiAssistantVoiceInputState.idle) {
      return;
    }
    final AiAssistantVoiceInputState nextState = details.localPosition.dy < -50
        ? AiAssistantVoiceInputState.cancel
        : AiAssistantVoiceInputState.listening;
    if (nextState == state.voiceInputState) {
      return;
    }
    _updateState((AiAssistantState current) {
      return current.copyWith(voiceInputState: nextState);
    });
  }

  Future<void> finishVoiceInput({required String language}) async {
    if (state.voiceInputState == AiAssistantVoiceInputState.idle) {
      return;
    }

    final bool shouldCancel =
        state.voiceInputState == AiAssistantVoiceInputState.cancel;
    try {
      await _speechToText.stop();
    } catch (_) {
      // ignore stop errors when the recognizer already stopped itself
    }

    final String recognizedText = state.recognizedText.trim();
    _resetVoiceInputState();

    if (shouldCancel) {
      return;
    }
    if (recognizedText.isEmpty) {
      _emitFeedback('未识别到语音内容', isError: true);
      return;
    }
    await sendText(recognizedText, language: language);
  }

  Future<void> applyRecommendedJob(JobListVO job) async {
    if (job.jobId <= 0 ||
        state.applyingJobIds.contains(job.jobId) ||
        state.appliedJobIds.contains(job.jobId)) {
      return;
    }

    _updateState((AiAssistantState current) {
      final Set<int> nextApplying = <int>{...current.applyingJobIds, job.jobId};
      return current.copyWith(applyingJobIds: nextApplying);
    });

    try {
      await ref
          .read(applicationServiceProvider)
          .apply(request: CreateApplicationBO(jobId: job.jobId));
      _updateState((AiAssistantState current) {
        final Set<int> nextApplying = <int>{...current.applyingJobIds}
          ..remove(job.jobId);
        final Set<int> nextApplied = <int>{...current.appliedJobIds, job.jobId};
        return current.copyWith(
          applyingJobIds: nextApplying,
          appliedJobIds: nextApplied,
          feedbackMessage: '招聘.投递成功'.tr(),
          feedbackIsError: false,
          feedbackId: current.feedbackId + 1,
        );
      });
    } catch (error) {
      _updateState((AiAssistantState current) {
        final Set<int> nextApplying = <int>{...current.applyingJobIds}
          ..remove(job.jobId);
        return current.copyWith(
          applyingJobIds: nextApplying,
          feedbackMessage: _resolveJobApplyErrorMessage(error),
          feedbackIsError: true,
          feedbackId: current.feedbackId + 1,
        );
      });
    }
  }

  void clearFeedback() {
    _updateState((AiAssistantState current) {
      return current.copyWith(feedbackMessage: null, feedbackIsError: false);
    });
  }

  bool _hasValidSessionId(int? sessionId) {
    return sessionId != null && sessionId > 0;
  }

  void _showDefaultConversation() {
    _updateState((AiAssistantState current) {
      return current.copyWith(
        currentSessionId: null,
        isHistoryLoading: false,
        messages: _buildDefaultMessages(),
        messageVersion: current.messageVersion + 1,
      );
    });
  }

  List<AiAssistantMessageVM> _buildDefaultMessages() {
    return <AiAssistantMessageVM>[
      AiAssistantMessageVM(
        role: AiAssistantChatRole.assistant,
        text: 'AI.欢迎语'.tr(),
        footer: null,
      ),
      AiAssistantMessageVM(
        role: AiAssistantChatRole.user,
        text: 'AI.用户示例提问'.tr(),
        footer: null,
      ),
      AiAssistantMessageVM(
        role: AiAssistantChatRole.assistant,
        text: 'AI.匹配追问'.tr(),
        footer: 'AI.由西格玛AI提供'.tr(),
      ),
      AiAssistantMessageVM(
        role: AiAssistantChatRole.assistant,
        text: 'AI.推荐岗位提示'.tr(),
        footer: 'AI.由西格玛AI提供'.tr(),
        isEmbeddedJobLoading: true,
      ),
    ];
  }

  AiAssistantMessageVM _mapHistoryMessage(AiMessageVO message) {
    final AiAssistantChatRole role = _parseChatRole(message.role);
    final bool isAssistant = role == AiAssistantChatRole.assistant;
    return AiAssistantMessageVM(
      role: role,
      text: message.content.trim(),
      footer: isAssistant ? 'AI.由西格玛AI提供'.tr() : null,
      embeddedJob: isAssistant ? _parseEmbeddedJobFromCards(message.cards) : null,
    );
  }

  AiAssistantChatRole _parseChatRole(String role) {
    final String normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'assistant' ||
        normalizedRole == 'ai' ||
        normalizedRole == 'bot') {
      return AiAssistantChatRole.assistant;
    }
    return AiAssistantChatRole.user;
  }

  Future<void> _loadRecommendedJob() async {
    try {
      final response = await ref.read(jobServiceProvider).listJobs(
            page: 1,
            pageSize: 1,
          );
      if (_isDisposed) {
        return;
      }
      _updateDemoRecommendationMessage(
        response.list.isEmpty ? null : response.list.first,
      );
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      _updateDemoRecommendationMessage(null);
    }
  }

  void _updateDemoRecommendationMessage(JobListVO? job) {
    final int messageIndex = state.messages.indexWhere(
      (AiAssistantMessageVM message) => message.isEmbeddedJobLoading,
    );
    if (messageIndex < 0) {
      return;
    }

    final List<AiAssistantMessageVM> nextMessages =
        List<AiAssistantMessageVM>.from(state.messages);
    nextMessages[messageIndex] = nextMessages[messageIndex].copyWith(
      embeddedJob: job,
      isEmbeddedJobLoading: false,
    );
    _updateState((AiAssistantState current) {
      return current.copyWith(
        messages: nextMessages,
        messageVersion: current.messageVersion + 1,
      );
    });
  }

  JobListVO? _parseEmbeddedJobFromCards(List<AiCardEvent> cards) {
    for (final AiCardEvent card in cards) {
      if (card.type.trim().toLowerCase() != 'jobs') {
        continue;
      }
      for (final JsonMap item in card.items) {
        try {
          return JobListVO.fromJson(_normalizeJobJson(item));
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  Map<String, Object?> _normalizeJobJson(Map<String, Object?> json) {
    return <String, Object?>{
      'jobId': json['jobId'] ?? json['job_id'] ?? 0,
      'title': json['title'] ?? json['job_title'] ?? '',
      'salaryMin': json['salaryMin'] ?? json['salary_min'] ?? 0,
      'salaryMax': json['salaryMax'] ?? json['salary_max'] ?? 0,
      'salaryCurrency': json['salaryCurrency'] ?? json['salary_currency'] ?? '',
      'salaryPeriod': json['salaryPeriod'] ?? json['salary_period'] ?? '',
      'country': json['country'] ?? '',
      'city': json['city'] ?? '',
      'tags': json['tags'] ?? const <Object?>[],
      'hasVisaSupport':
          json['hasVisaSupport'] ?? json['has_visa_support'] ?? false,
      'employer': _normalizeEmployerJson(asJsonMap(json['employer'])),
      'isUrgent': json['isUrgent'] ?? json['is_urgent'] ?? false,
      'isCollected': json['isCollected'] ?? json['is_collected'] ?? false,
      'publishedAt': json['publishedAt'] ?? json['published_at'] ?? '',
    };
  }

  Map<String, Object?> _normalizeEmployerJson(Map<String, Object?>? json) {
    final Map<String, Object?> employerJson = json ?? <String, Object?>{};
    return <String, Object?>{
      'employerId':
          employerJson['employerId'] ?? employerJson['employer_id'] ?? 0,
      'name': employerJson['name'] ?? '',
      'logoUrl': employerJson['logoUrl'] ?? employerJson['logo_url'] ?? '',
    };
  }

  void _handleChatEvent(SseEvent event, {required int assistantIndex}) {
    final String eventName = (event.event ?? '').trim().toLowerCase();
    final JsonMap payload = _decodeEventPayload(event.data);
    switch (eventName) {
      case 'ready':
        final int sessionId = readInt(payload, 'sessionId');
        if (sessionId > 0) {
          _updateState((AiAssistantState current) {
            return current.copyWith(currentSessionId: sessionId);
          });
        }
        break;
      case 'cards':
        final AiCardEvent card = AiCardEvent.fromJson(payload);
        if (!_isValidAssistantIndex(assistantIndex)) {
          break;
        }
        _pendingEmbeddedJobs[assistantIndex] = _parseEmbeddedJobFromCards(
          <AiCardEvent>[card],
        );
        break;
      case 'delta':
        final String content = readString(payload, 'content');
        if (content.isEmpty || !_isValidAssistantIndex(assistantIndex)) {
          break;
        }
        final List<AiAssistantMessageVM> nextMessages =
            List<AiAssistantMessageVM>.from(state.messages);
        nextMessages[assistantIndex] = nextMessages[assistantIndex].copyWith(
          text: '${nextMessages[assistantIndex].text}$content',
        );
        _updateState((AiAssistantState current) {
          return current.copyWith(
            messages: nextMessages,
            messageVersion: current.messageVersion + 1,
          );
        });
        break;
      case 'error':
        _pendingEmbeddedJobs.remove(assistantIndex);
        _emitFeedback(
          readString(payload, 'msg', fallback: event.data),
          isError: true,
        );
        _removeEmptyAssistantMessage(assistantIndex);
        break;
      case 'done':
        if (!_isValidAssistantIndex(assistantIndex)) {
          break;
        }
        final JobListVO? pendingEmbeddedJob = _pendingEmbeddedJobs.remove(
          assistantIndex,
        );
        final List<AiAssistantMessageVM> nextMessages =
            List<AiAssistantMessageVM>.from(state.messages);
        nextMessages[assistantIndex] = nextMessages[assistantIndex].copyWith(
          embeddedJob: pendingEmbeddedJob,
          isEmbeddedJobLoading: false,
        );
        _updateState((AiAssistantState current) {
          return current.copyWith(
            messages: nextMessages,
            messageVersion: current.messageVersion + 1,
          );
        });
        break;
      default:
        return;
    }
  }

  bool _isValidAssistantIndex(int index) {
    return index >= 0 && index < state.messages.length;
  }

  JsonMap _decodeEventPayload(String raw) {
    final String normalized = raw.trim();
    if (normalized.isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      return asJsonMap(jsonDecode(normalized));
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  void _removeEmptyAssistantMessage(int assistantIndex) {
    if (!_isValidAssistantIndex(assistantIndex)) {
      _pendingEmbeddedJobs.remove(assistantIndex);
      return;
    }
    final AiAssistantMessageVM message = state.messages[assistantIndex];
    if (message.role != AiAssistantChatRole.assistant ||
        message.text.trim().isNotEmpty) {
      return;
    }
    final List<AiAssistantMessageVM> nextMessages =
        List<AiAssistantMessageVM>.from(state.messages)..removeAt(assistantIndex);
    _pendingEmbeddedJobs.remove(assistantIndex);
    _updateState((AiAssistantState current) {
      return current.copyWith(
        messages: nextMessages,
        messageVersion: current.messageVersion + 1,
      );
    });
  }

  Future<String?> _resolveSpeechLocaleId({
    required bool isChineseLocale,
  }) async {
    final List<String> preferredLocaleIds = isChineseLocale
        ? <String>['zh_CN', 'cmn_Hans_CN', 'zh-Hans-CN', 'zh-CN', 'zh']
        : <String>['en_US', 'en-US', 'en_GB', 'en-GB', 'en'];
    final List<stt.LocaleName> availableLocales = await _speechToText.locales();
    if (availableLocales.isEmpty) {
      return isChineseLocale ? 'zh_CN' : 'en_US';
    }

    for (final String preferredLocaleId in preferredLocaleIds) {
      final String? exactLocaleId = _findSpeechLocaleId(
        availableLocales,
        preferredLocaleId,
      );
      if (exactLocaleId != null) {
        return exactLocaleId;
      }
    }

    final String languageCode = isChineseLocale ? 'zh' : 'en';
    for (final stt.LocaleName locale in availableLocales) {
      if (_extractLanguageCode(locale.localeId) == languageCode) {
        return locale.localeId;
      }
    }

    return availableLocales.first.localeId;
  }

  String? _findSpeechLocaleId(
    List<stt.LocaleName> availableLocales,
    String targetLocaleId,
  ) {
    final String normalizedTarget = _normalizeLocaleId(targetLocaleId);
    for (final stt.LocaleName locale in availableLocales) {
      if (_normalizeLocaleId(locale.localeId) == normalizedTarget) {
        return locale.localeId;
      }
    }
    return null;
  }

  String _normalizeLocaleId(String localeId) {
    return localeId.trim().replaceAll('-', '_').toLowerCase();
  }

  String _extractLanguageCode(String localeId) {
    final String normalized = _normalizeLocaleId(localeId);
    final List<String> segments = normalized.split('_');
    return segments.isEmpty ? normalized : segments.first;
  }

  void _resetVoiceInputState() {
    _voiceTimer?.cancel();
    _updateState((AiAssistantState current) {
      return current.copyWith(
        voiceInputState: AiAssistantVoiceInputState.idle,
        voiceSeconds: 0,
        recognizedText: '',
      );
    });
  }

  String _resolveJobApplyErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '招聘.投递失败'.tr();
  }

  void _emitFeedback(String message, {required bool isError}) {
    _updateState((AiAssistantState current) {
      return current.copyWith(
        feedbackMessage: message,
        feedbackIsError: isError,
        feedbackId: current.feedbackId + 1,
      );
    });
  }

  void _updateState(
    AiAssistantState Function(AiAssistantState current) transform,
  ) {
    if (_isDisposed) {
      return;
    }
    state = transform(state);
  }
}
