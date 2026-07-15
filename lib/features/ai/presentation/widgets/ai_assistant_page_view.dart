import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/models/app_currency.dart';
import '../../../../shared/ui/app_colors.dart';
import '../../../../shared/ui/app_spacing.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../../shared/widgets/tag_chip.dart';
import '../../../jobs/data/job_models.dart';
import '../../application/ai_assistant/ai_assistant_state.dart';

import 'package:europepass/shared/ui/test_style.dart';

class AiAssistantPageView extends StatelessWidget {
  const AiAssistantPageView({
    super.key,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.isVoiceInputEnabled,
    required this.onOpenHistory,
    required this.onToggleComposerMode,
    required this.onSend,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordEnd,
    required this.onVoiceRecordMoveUpdate,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  static const String _voiceAsset = 'assets/images/chat_page_voice.svg';
  static const String _keyboardAsset = 'assets/images/chat_page_keyboard.svg';
  static const String _sendAsset = 'assets/images/icon_send.svg';
  static const Color _titleColor = Color(0xFF171A1D);
  static const Color _subtleTextColor = Color(0xFF8C8C8C);

  final AiAssistantState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool isVoiceInputEnabled;
  final VoidCallback onOpenHistory;
  final VoidCallback onToggleComposerMode;
  final Future<void> Function() onSend;
  final Future<void> Function() onVoiceRecordStart;
  final Future<void> Function() onVoiceRecordEnd;
  final void Function(LongPressMoveUpdateDetails details)
  onVoiceRecordMoveUpdate;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: TapBlankToDismissKeyboard(
        child: JobSeekerPageBackground(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: Column(
            children: <Widget>[
              _Header(onOpenHistory: onOpenHistory),
              Expanded(
                child: _ChatMessageList(
                  scrollController: scrollController,
                  messages: state.messages,
                  isHistoryLoading: state.isHistoryLoading,
                  isSending: state.isSending,
                  applyingJobIds: state.applyingJobIds,
                  appliedJobIds: state.appliedJobIds,
                  onApplyJob: onApplyJob,
                  onOpenJobDetail: onOpenJobDetail,
                ),
              ),
              _Composer(
                controller: controller,
                focusNode: focusNode,
                isSending: state.isSending,
                isVoiceInputEnabled: isVoiceInputEnabled,
                isVoiceMode: state.isVoiceMode,
                voiceInputState: state.voiceInputState,
                voiceSeconds: state.voiceSeconds,
                onVoiceTap: onToggleComposerMode,
                onVoiceRecordStart: onVoiceRecordStart,
                onVoiceRecordEnd: onVoiceRecordEnd,
                onVoiceRecordMoveUpdate: onVoiceRecordMoveUpdate,
                onSend: () {
                  onSend();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        // height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: 10,
        ),
        color: Colors.transparent,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'AI.AI助手'.tr(),
                style: TestStyle.pingFangMedium(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenHistory,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'AI.历史记录'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.scrollController,
    required this.messages,
    required this.isHistoryLoading,
    required this.isSending,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  final ScrollController scrollController;
  final List<AiAssistantMessageVM> messages;
  final bool isHistoryLoading;
  final bool isSending;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  static const Duration _timeDividerThreshold = Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    final bool showLoading = isHistoryLoading && messages.isEmpty;
    return ListView.separated(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        16,
      ),
      itemCount: showLoading ? 1 : messages.length,
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemBuilder: (BuildContext context, int index) {
        if (showLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final AiAssistantMessageVM message = messages[index];
        final Widget messageWidget = _ChatMessageItem(
          key: ValueKey<String>(
            'chat-message-$index-'
            '${message.role.name}-'
            '${message.text.hashCode}-'
            '${message.embeddedJobs.map((JobListVO job) => job.jobId).join('_')}-'
            '${message.isEmbeddedJobLoading}',
          ),
          message: message,
          isSending: isSending,
          applyingJobIds: applyingJobIds,
          appliedJobIds: appliedJobIds,
          onApplyJob: onApplyJob,
          onOpenJobDetail: onOpenJobDetail,
        );
        final bool shouldShowTimeDivider = _shouldShowAiTimeDivider(
          messages: messages,
          index: index,
          threshold: _timeDividerThreshold,
        );
        if (!shouldShowTimeDivider) {
          return messageWidget;
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AiChatTimeDivider(label: _formatAiChatDateTime(message.sentAt)),
            const SizedBox(height: 12),
            messageWidget,
          ],
        );
      },
    );
  }
}

class _AiChatTimeDivider extends StatelessWidget {
  const _AiChatTimeDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TestStyle.regular(
            fontSize: 11,
            color: const Color(0xFF8C8C8C),
          ).copyWith(height: 14 / 11),
        ),
      ),
    );
  }
}

class _ChatMessageItem extends StatelessWidget {
  const _ChatMessageItem({
    super.key,
    required this.message,
    required this.isSending,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  final AiAssistantMessageVM message;
  final bool isSending;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  @override
  Widget build(BuildContext context) {
    if (message.role == AiAssistantChatRole.assistant) {
      return _AssistantMessageItem(
        message: message,
        isSending: isSending,
        applyingJobIds: applyingJobIds,
        appliedJobIds: appliedJobIds,
        onApplyJob: onApplyJob,
        onOpenJobDetail: onOpenJobDetail,
      );
    }
    return _UserMessageItem(message: message);
  }
}

String _formatAiChatDateTime(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) {
    final RegExpMatch? match = RegExp(
      r'(?:(\d{2,4})[-/])?(\d{2})[-/](\d{2})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(raw.trim());
    if (match == null) {
      return raw;
    }
    final String month = match.group(2) ?? '';
    final String day = match.group(3) ?? '';
    final String hour = match.group(4) ?? '00';
    final String minute = match.group(5) ?? '00';
    final String second = match.group(6) ?? '00';
    final bool hasTime = match.group(4) != null && match.group(5) != null;
    if (!hasTime) {
      return '$month-$day 00:00:00';
    }
    return '$month-$day $hour:$minute:$second';
  }
  final Duration difference = DateTime.now().difference(parsed);
  final String time =
      '${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}:${_twoDigits(parsed.second)}';
  if (!difference.isNegative && difference < const Duration(hours: 24)) {
    return time;
  }
  return '${_twoDigits(parsed.month)}-${_twoDigits(parsed.day)} $time';
}

bool _shouldShowAiTimeDivider({
  required List<AiAssistantMessageVM> messages,
  required int index,
  required Duration threshold,
}) {
  if (index <= 0) {
    return false;
  }
  final String currentRaw = messages[index].sentAt.trim();
  final String previousRaw = messages[index - 1].sentAt.trim();
  if (currentRaw.isEmpty || previousRaw.isEmpty) {
    return false;
  }
  final DateTime? currentTime = DateTime.tryParse(currentRaw);
  final DateTime? previousTime = DateTime.tryParse(previousRaw);
  if (currentTime == null || previousTime == null) {
    return false;
  }
  return currentTime.difference(previousTime) > threshold;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _AssistantMessageItem extends StatelessWidget {
  const _AssistantMessageItem({
    required this.message,
    required this.isSending,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  final AiAssistantMessageVM message;
  final bool isSending;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  @override
  Widget build(BuildContext context) {
    final List<JobListVO> embeddedJobs = message.embeddedJobs;
    final bool showPendingPlaceholder =
        isSending && message.text.trim().isEmpty;
    const double bubbleStartInset = 0;
    const double bubbleTopInset = 38;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: bubbleStartInset,
              top: bubbleTopInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showPendingPlaceholder)
                  const _AssistantPendingIndicator()
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.text,
                        style: TestStyle.regular(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                if (message.footer != null &&
                    message.footer!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      message.footer!,
                      style: TestStyle.semibold(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (message.isEmbeddedJobLoading) ...<Widget>[
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ],
                if (embeddedJobs.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(embeddedJobs.length, (int index) {
                    final JobListVO job = embeddedJobs[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == embeddedJobs.length - 1 ? 0 : 10,
                      ),
                      child: _EmbeddedJobCard(
                        job: job,
                        isApplying: applyingJobIds.contains(job.jobId),
                        isApplied: appliedJobIds.contains(job.jobId),
                        onApply: () => onApplyJob(job),
                        onTap: () => onOpenJobDetail(job),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/images/icon_ai_bot.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantPendingIndicator extends StatefulWidget {
  const _AssistantPendingIndicator();

  @override
  State<_AssistantPendingIndicator> createState() =>
      _AssistantPendingIndicatorState();
}

class _AssistantPendingIndicatorState
    extends State<_AssistantPendingIndicator> {
  static const List<List<double>> _frames = <List<double>>[
    <double>[0.4, 0.7, 1],
    <double>[1, 0.4, 0.7],
    <double>[0.7, 1, 0.4],
  ];
  static const Duration _frameDuration = Duration(milliseconds: 360);
  static const Color _dotColor = Color(0xFF096DD9);

  Timer? _timer;
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<double> opacities = _frames[_frameIndex];
    return Container(
      width: 60,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(opacities.length, (int index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == opacities.length - 1 ? 0 : 7,
            ),
            child: AnimatedOpacity(
              opacity: opacities[index],
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: _dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _UserMessageItem extends StatelessWidget {
  const _UserMessageItem({required this.message});

  final AiAssistantMessageVM message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TestStyle.regular(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedJobCard extends StatelessWidget {
  const _EmbeddedJobCard({
    required this.job,
    required this.isApplying,
    required this.isApplied,
    required this.onApply,
    required this.onTap,
  });

  final JobListVO job;
  final bool isApplying;
  final bool isApplied;
  final Future<void> Function() onApply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String urgentLabel = '招聘卡片.急招'.tr();
    final String visaSupportLabel = '招聘卡片.提供签证'.tr();
    final List<String> tagLabels = job.tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != urgentLabel),
      if (job.hasVisaSupport && !tagLabels.contains(visaSupportLabel))
        visaSupportLabel,
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[if (job.isUrgent) urgentLabel];
    final List<String> locationParts = <String>[
      job.country.trim(),
      job.city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    job.title,
                    style: TestStyle.numberBold(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  job.formatAiSalary(),
                  style: TestStyle.numberBold(
                    fontSize: 16,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: requirementTags
                  .map((String label) => TagChip(label: label))
                  .toList(growable: false),
            ),
            if (highlightTags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: highlightTags
                    .map(
                      (String label) => TagChip(
                        label: label,
                        backgroundColor: AppColors.chipBackground,
                        textColor: AppColors.danger,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Icon(Icons.apartment, size: 18, color: AppColors.brand),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.employer.name,
                    style: TestStyle.numberBold(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    onPressed: job.jobId <= 0 || isApplying || isApplied
                        ? null
                        : () {
                            onApply();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      disabledBackgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isApplied
                          ? '招聘.已投递'.tr()
                          : (isApplying ? '招聘.投递中'.tr() : '招聘卡片.一键投递'.tr()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.place,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  locationParts.join('·'),
                  style: TestStyle.semibold(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on JobListVO {
  String formatAiSalary() {
    return AppCurrency.formatRange(
      min: salaryMin,
      max: salaryMax,
      rawCurrency: salaryCurrency,
      period: salaryPeriod,
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isVoiceInputEnabled,
    required this.isVoiceMode,
    required this.voiceInputState,
    required this.voiceSeconds,
    required this.onVoiceTap,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordEnd,
    required this.onVoiceRecordMoveUpdate,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isVoiceInputEnabled;
  final bool isVoiceMode;
  final AiAssistantVoiceInputState voiceInputState;
  final int voiceSeconds;
  final VoidCallback onVoiceTap;
  final Future<void> Function() onVoiceRecordStart;
  final Future<void> Function() onVoiceRecordEnd;
  final void Function(LongPressMoveUpdateDetails details)
  onVoiceRecordMoveUpdate;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bool effectiveIsVoiceMode = isVoiceInputEnabled && isVoiceMode;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (isVoiceInputEnabled) ...<Widget>[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: InkWell(
                      key: const ValueKey<String>('ai_assistant_voice_toggle'),
                      onTap: isSending ? null : onVoiceTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: SvgPicture.asset(
                          effectiveIsVoiceMode
                              ? AiAssistantPageView._keyboardAsset
                              : AiAssistantPageView._voiceAsset,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: effectiveIsVoiceMode
                      ? _VoiceRecordButton(
                          key: const ValueKey<String>(
                            'ai_assistant_voice_record_button',
                          ),
                          isSending: isSending,
                          voiceInputState: voiceInputState,
                          voiceSeconds: voiceSeconds,
                          onRecordStart: onVoiceRecordStart,
                          onRecordEnd: onVoiceRecordEnd,
                          onRecordMoveUpdate: onVoiceRecordMoveUpdate,
                        )
                      : TextField(
                          key: const ValueKey<String>(
                            'ai_assistant_text_input',
                          ),
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 4,
                          enabled: !isSending,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          onSubmitted: (_) => onSend(),
                          decoration:
                              const InputDecoration(
                                isCollapsed: true,
                                hintText: null,
                                border: InputBorder.none,
                              ).copyWith(
                                hintText: '消息.发消息'.tr(),
                                hintStyle: TestStyle.pingFangRegular(
                                  fontSize: 15,
                                  color: AiAssistantPageView._subtleTextColor,
                                ),
                              ),
                          style: TestStyle.regular(
                            fontSize: 15,
                            color: AiAssistantPageView._titleColor,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                if (!effectiveIsVoiceMode)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder:
                        (
                          BuildContext context,
                          TextEditingValue value,
                          Widget? child,
                        ) {
                          final bool hasText = value.text.trim().isNotEmpty;
                          if (!hasText) {
                            return const SizedBox(width: 24, height: 24);
                          }
                          return InkWell(
                            onTap: isSending ? null : onSend,
                            borderRadius: BorderRadius.circular(12),
                            child: Opacity(
                              opacity: isSending ? 0.45 : 1,
                              child: SvgPicture.asset(
                                AiAssistantPageView._sendAsset,
                                width: 32,
                                height: 32,
                              ),
                            ),
                          );
                        },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceRecordButton extends StatelessWidget {
  const _VoiceRecordButton({
    super.key,
    required this.isSending,
    required this.voiceInputState,
    required this.voiceSeconds,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onRecordMoveUpdate,
  });

  final bool isSending;
  final AiAssistantVoiceInputState voiceInputState;
  final int voiceSeconds;
  final Future<void> Function() onRecordStart;
  final Future<void> Function() onRecordEnd;
  final void Function(LongPressMoveUpdateDetails details) onRecordMoveUpdate;

  @override
  Widget build(BuildContext context) {
    final bool isCancel = voiceInputState == AiAssistantVoiceInputState.cancel;
    final bool isListening =
        voiceInputState == AiAssistantVoiceInputState.listening;
    final Color backgroundColor = isCancel
        ? const Color(0xFFFFEAEA)
        : isListening
        ? const Color(0xFFE5E7EB)
        : Colors.white;
    final Color foregroundColor = isCancel
        ? const Color(0xFFD9363E)
        : isListening
        ? AiAssistantPageView._titleColor
        : AiAssistantPageView._subtleTextColor;
    final String label = isCancel
        ? '消息.松开取消'.tr()
        : isListening
        ? '${'消息.松开发送'.tr()} ${_formatDuration(voiceSeconds)}'
        : '消息.按住说话'.tr();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: isSending ? null : (_) => onRecordStart(),
      onLongPressEnd: isSending ? null : (_) => onRecordEnd(),
      onLongPressMoveUpdate: isSending ? null : onRecordMoveUpdate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TestStyle.medium(fontSize: 15, color: foregroundColor),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int safeSeconds = seconds < 0 ? 0 : seconds;
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }
}
