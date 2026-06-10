import 'dart:async';
import '../../../shared/widgets/app_toast.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/localization/app_locales.dart';
import '../data/ai_models.dart';
import '../../jobs/data/job_models.dart';
import '../../jobs/presentation/job_detail_page.dart';
import '../application/ai_assistant/ai_assistant_controller.dart';
import '../application/ai_assistant/ai_assistant_state.dart';
import 'widgets/ai_assistant_page_view.dart';
import 'widgets/ai_session_history_sheet.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key, this.sessionId});

  final int? sessionId;

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputFocusNode.addListener(_handleInputFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(aiAssistantControllerProvider.notifier)
            .bootstrap(sessionId: widget.sessionId),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocusNode.removeListener(_handleInputFocusChanged);
    _controller.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      final bool keyboardOpened = keyboardInset > _lastKeyboardInset;
      _lastKeyboardInset = keyboardInset;
      if (keyboardOpened) {
        _scheduleScrollToBottom(animated: false, settle: true);
      }
    });
  }

  void _handleInputFocusChanged() {
    if (_inputFocusNode.hasFocus) {
      _scheduleScrollToBottom(animated: false, settle: true);
    }
  }

  Future<void> _handleSend(AiAssistantController controller) async {
    final String text = _controller.text.trim();
    if (text.isEmpty || ref.read(aiAssistantControllerProvider).isSending) {
      return;
    }
    _controller.clear();
    await controller.sendText(text, language: _resolveLanguage());
  }

  void _handleToggleComposerMode(
    AiAssistantController controller,
    AiAssistantState state,
  ) {
    if (state.isSending || state.isVoiceListening) {
      return;
    }
    final bool willEnterVoice = !state.isVoiceMode;
    controller.toggleComposerMode();
    if (willEnterVoice) {
      _inputFocusNode.unfocus();
    }
  }

  String _resolveLanguage() {
    final String code = context.locale.languageCode.trim().toLowerCase();
    return code == 'en' ? 'en' : 'zh';
  }

  void _openRecommendedJobDetail(JobListVO job) {
    if (job.jobId <= 0) {
      return;
    }
    context.push(
      RoutePaths.jobDetail,
      extra: JobDetailPageArgs(jobId: job.jobId),
    );
  }

  Future<void> _openSessionHistory() async {
    final AiAssistantController controller = ref.read(
      aiAssistantControllerProvider.notifier,
    );
    final int? currentSessionId = ref
        .read(aiAssistantControllerProvider)
        .currentSessionId;
    await showAiSessionHistorySheet(
      context,
      currentSessionId: currentSessionId,
      onSessionSelected: (AiSessionVO session) async {
        await controller.loadSessionHistory(session.sessionId);
      },
      onCurrentSessionDeleted: controller.resetToDefaultConversation,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    AppToast.show(message);
  }

  void _scheduleScrollToBottom({bool animated = true, bool settle = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: animated);
      if (!settle) {
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) {
          return;
        }
        _scrollToBottom(animated: animated);
      });
    });
  }

  void _scrollToBottom({required bool animated}) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    final double target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiAssistantState>(aiAssistantControllerProvider, (
      AiAssistantState? previous,
      AiAssistantState next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showMessage(next.feedbackMessage!, isError: next.feedbackIsError);
        ref.read(aiAssistantControllerProvider.notifier).clearFeedback();
      }
      if (previous?.messageVersion != next.messageVersion) {
        _scheduleScrollToBottom(animated: false, settle: true);
      }
    });

    final AiAssistantState state = ref.watch(aiAssistantControllerProvider);
    final AiAssistantController controller = ref.read(
      aiAssistantControllerProvider.notifier,
    );

    return AiAssistantPageView(
      state: state,
      controller: _controller,
      focusNode: _inputFocusNode,
      scrollController: _scrollController,
      onOpenHistory: _openSessionHistory,
      onToggleComposerMode: () => _handleToggleComposerMode(controller, state),
      onSend: () => _handleSend(controller),
      onVoiceRecordStart: () =>
          controller.startVoiceInput(isChineseLocale: context.isChineseLocale),
      onVoiceRecordEnd: () =>
          controller.finishVoiceInput(language: _resolveLanguage()),
      onVoiceRecordMoveUpdate: controller.updateVoiceDrag,
      onApplyJob: controller.applyRecommendedJob,
      onOpenJobDetail: _openRecommendedJobDetail,
    );
  }
}
