import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_decoders.dart';
import '../../../shared/network/sse_models.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/job_seeker_page_background.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../data/ai_models.dart';
import '../data/ai_providers.dart';
import 'widgets/ai_session_history_sheet.dart';
import '../../jobs/data/job_models.dart';
import '../../jobs/data/job_providers.dart';
import '../../jobs/presentation/job_apply_helper.dart';
import '../../jobs/presentation/job_detail_page.dart';

/// AI 助手页（按 Figma 截图还原：对话流 + 推荐问题 + 输入框）。
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key, this.sessionId});

  final int? sessionId;

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final Set<int> _applyingJobIds = <int>{};
  final Set<int> _appliedJobIds = <int>{};
  int? _currentSessionId;
  bool _isHistoryLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMessages();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 初始化页面消息源：有有效会话时拉取历史，否则展示默认示例消息。
  Future<void> _initializeMessages() async {
    _currentSessionId = widget.sessionId;
    if (_hasValidSessionId(_currentSessionId)) {
      await _loadHistoryMessages(_currentSessionId!);
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..addAll(_buildDefaultMessages());
    });
    await _loadRecommendedJob();
  }

  /// 判断会话 ID 是否可用于拉取历史记录。
  bool _hasValidSessionId(int? sessionId) {
    return sessionId != null && sessionId > 0;
  }

  /// 构建无会话场景下的默认示例消息。
  List<_ChatMessage> _buildDefaultMessages() {
    return <_ChatMessage>[
      _ChatMessage(
        role: _ChatRole.assistant,
        text: 'AI.欢迎语'.tr(),
        footer: null,
      ),
      _ChatMessage(role: _ChatRole.user, text: 'AI.用户示例提问'.tr(), footer: null),
      _ChatMessage(
        role: _ChatRole.assistant,
        text: 'AI.匹配追问'.tr(),
        footer: 'AI.由西格玛AI提供'.tr(),
      ),
      _ChatMessage(
        role: _ChatRole.assistant,
        text: 'AI.推荐岗位提示'.tr(),
        footer: 'AI.由西格玛AI提供'.tr(),
        isEmbeddedJobLoading: true,
      ),
    ];
  }

  /// 发送用户消息并建立 AI SSE 对话流。
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    final String language = _resolveLanguage();
    setState(() {
      _messages.add(
        _ChatMessage(role: _ChatRole.user, text: text, footer: null),
      );
      _messages.add(
        _ChatMessage(
          role: _ChatRole.assistant,
          text: '',
          footer: 'AI.由西格玛AI提供'.tr(),
        ),
      );
      _controller.clear();
      _isSending = true;
    });
    final int assistantIndex = _messages.length - 1;
    try {
      await for (final SseEvent event in ref.read(aiServiceProvider).chat(
        request: AiChatBO(
          sessionId: _currentSessionId,
          message: text,
          contextType: 'general',
          language: language,
        ),
      )) {
        if (!mounted) {
          return;
        }
        _handleChatEvent(event, assistantIndex: assistantIndex);
      }
    } catch (error) {
      _showMessage(error.toString(), isError: true);
      if (mounted) {
        _removeEmptyAssistantMessage(assistantIndex);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// 拉取会话历史，并将服务端消息映射为页面内部消息模型。
  Future<void> _loadHistoryMessages(int sessionId) async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final List<AiMessageVO> history = await ref
          .read(aiServiceProvider)
          .getChatHistory(sessionId: sessionId);
      history.sort(
        (AiMessageVO left, AiMessageVO right) =>
            left.aiMsgId.compareTo(right.aiMsgId),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentSessionId = sessionId;
        _isHistoryLoading = false;
        _messages
          ..clear()
          ..addAll(history.map(_mapHistoryMessage));
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  /// 将接口消息统一转换为页面渲染模型，便于兼容 footer 与嵌入卡片。
  _ChatMessage _mapHistoryMessage(AiMessageVO message) {
    final _ChatRole role = _parseChatRole(message.role);
    final bool isAssistant = role == _ChatRole.assistant;
    return _ChatMessage(
      role: role,
      text: message.content.trim(),
      footer: isAssistant ? 'AI.由西格玛AI提供'.tr() : null,
      embeddedJob: isAssistant ? _parseEmbeddedJobFromCards(message.cards) : null,
    );
  }

  /// 解析历史消息角色，兼容后端可能返回的多个助理角色值。
  _ChatRole _parseChatRole(String role) {
    final String normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'assistant' ||
        normalizedRole == 'ai' ||
        normalizedRole == 'bot') {
      return _ChatRole.assistant;
    }
    return _ChatRole.user;
  }

  /// 加载一个真实岗位作为默认推荐卡片的数据来源，确保跳详情时有真实 `jobId`。
  Future<void> _loadRecommendedJob() async {
    try {
      final response = await ref
          .read(jobServiceProvider)
          .listJobs(page: 1, pageSize: 1);
      if (!mounted) {
        return;
      }
      _updateDemoRecommendationMessage(
        response.list.isEmpty ? null : response.list.first,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _updateDemoRecommendationMessage(null);
    }
  }

  /// 将默认示例中的推荐消息补齐为真实岗位卡片。
  void _updateDemoRecommendationMessage(JobListVO? job) {
    final int messageIndex = _messages.indexWhere(
      (_ChatMessage message) => message.isEmbeddedJobLoading,
    );
    if (messageIndex < 0) {
      return;
    }

    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        isEmbeddedJobLoading: false,
        embeddedJob: job,
      );
    });
  }

  /// 处理岗位投递操作，支持历史记录与默认推荐卡片共用一套交互。
  Future<void> _handleApplyRecommendedJob(JobListVO job) async {
    if (job.jobId <= 0 ||
        _applyingJobIds.contains(job.jobId) ||
        _appliedJobIds.contains(job.jobId)) {
      return;
    }

    setState(() {
      _applyingJobIds.add(job.jobId);
    });

    final String? errorMessage = await submitJobApplication(
      context,
      jobId: job.jobId,
    );
    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      setState(() {
        _applyingJobIds.remove(job.jobId);
        _appliedJobIds.add(job.jobId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('招聘.投递成功'.tr())));
      return;
    }

    setState(() {
      _applyingJobIds.remove(job.jobId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  /// 跳转到真实职位详情页。
  void _openRecommendedJobDetail(JobListVO job) {
    if (job.jobId <= 0) {
      return;
    }
    context.push(
      RoutePaths.jobDetail,
      extra: JobDetailPageArgs(jobId: job.jobId),
    );
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

  /// 标准化雇主对象，兼容后端可能返回的蛇形字段。
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
          setState(() {
            _currentSessionId = sessionId;
          });
        }
      case 'cards':
        final AiCardEvent card = AiCardEvent.fromJson(payload);
        if (_isValidAssistantIndex(assistantIndex)) {
          setState(() {
            final JobListVO? embeddedJob = _parseEmbeddedJobFromCards(
              <AiCardEvent>[card],
            );
            _messages[assistantIndex] = _messages[assistantIndex].copyWith(
              embeddedJob: embeddedJob,
              isEmbeddedJobLoading: false,
            );
          });
        }
      case 'delta':
        final String content = readString(payload, 'content');
        if (content.isEmpty || !_isValidAssistantIndex(assistantIndex)) {
          return;
        }
        setState(() {
          _messages[assistantIndex] = _messages[assistantIndex].copyWith(
            text: '${_messages[assistantIndex].text}$content',
          );
        });
      case 'error':
        final String message = readString(payload, 'msg', fallback: event.data);
        _showMessage(message, isError: true);
        _removeEmptyAssistantMessage(assistantIndex);
      case 'done':
        if (_isValidAssistantIndex(assistantIndex)) {
          setState(() {
            _messages[assistantIndex] = _messages[assistantIndex].copyWith(
              isEmbeddedJobLoading: false,
            );
          });
        }
      default:
        return;
    }
  }

  bool _isValidAssistantIndex(int index) {
    return index >= 0 && index < _messages.length;
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
      return;
    }
    final _ChatMessage message = _messages[assistantIndex];
    if (message.role != _ChatRole.assistant || message.text.trim().isNotEmpty) {
      return;
    }
    setState(() {
      _messages.removeAt(assistantIndex);
    });
  }

  String _resolveLanguage() {
    final String code = context.locale.languageCode.trim().toLowerCase();
    return code == 'en' ? 'en' : 'zh';
  }

  Future<void> _openSessionHistory() async {
    await showAiSessionHistorySheet(
      context,
      currentSessionId: _currentSessionId,
      onSessionSelected: (AiSessionVO session) async {
        await _loadHistoryMessages(session.sessionId);
      },
      onCurrentSessionDeleted: () async {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentSessionId = null;
          _messages
            ..clear()
            ..addAll(_buildDefaultMessages());
        });
        await _loadRecommendedJob();
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? const Color(0xFFD9363E) : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JobSeekerPageBackground(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  10,
                  AppSpacing.pagePadding,
                  10,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      'AI.AI助手'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _openSessionHistory,
                      child: Text('AI.历史记录'.tr()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  children: <Widget>[
                    if (_isHistoryLoading && _messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ..._messages.map(
                        (_ChatMessage message) => _ChatMessageItem(
                          message: message,
                          applyingJobIds: _applyingJobIds,
                          appliedJobIds: _appliedJobIds,
                          onApplyJob: _handleApplyRecommendedJob,
                          onOpenJobDetail: _openRecommendedJobDetail,
                        ),
                      ),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: 'AI.推荐适合我的欧洲签证服务商'.tr(),
                      onTap: () => _controller.text = 'AI.推荐适合我的欧洲签证服务商'.tr(),
                    ),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: 'AI.推荐匹配我的欧洲岗位'.tr(),
                      onTap: () => _controller.text = 'AI.推荐匹配我的欧洲岗位'.tr(),
                    ),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: 'AI.签证办理流程是什么'.tr(),
                      onTap: () => _controller.text = 'AI.签证办理流程是什么'.tr(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _Composer(controller: _controller, onSend: () => unawaited(_send())),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChatRole { assistant, user }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    required this.footer,
    this.extraData,
    this.embeddedJob,
    this.isEmbeddedJobLoading = false,
  });

  final _ChatRole role;
  final String text;
  final String? footer;
  final String? extraData;
  final JobListVO? embeddedJob;
  final bool isEmbeddedJobLoading;

  /// 创建消息副本，便于异步补齐推荐岗位卡片。
  _ChatMessage copyWith({
    _ChatRole? role,
    String? text,
    String? footer,
    String? extraData,
    JobListVO? embeddedJob,
    bool? isEmbeddedJobLoading,
  }) {
    return _ChatMessage(
      role: role ?? this.role,
      text: text ?? this.text,
      footer: footer ?? this.footer,
      extraData: extraData ?? this.extraData,
      embeddedJob: embeddedJob ?? this.embeddedJob,
      isEmbeddedJobLoading: isEmbeddedJobLoading ?? this.isEmbeddedJobLoading,
    );
  }
}

class _ChatMessageItem extends StatelessWidget {
  const _ChatMessageItem({
    required this.message,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  final _ChatMessage message;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  @override
  Widget build(BuildContext context) {
    if (message.role == _ChatRole.assistant) {
      return _AssistantMessageItem(
        message: message,
        applyingJobIds: applyingJobIds,
        appliedJobIds: appliedJobIds,
        onApplyJob: onApplyJob,
        onOpenJobDetail: onOpenJobDetail,
      );
    }
    return _UserMessageItem(message: message);
  }
}

class _AssistantMessageItem extends StatelessWidget {
  const _AssistantMessageItem({
    required this.message,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyJob,
    required this.onOpenJobDetail,
  });

  final _ChatMessage message;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApplyJob;
  final void Function(JobListVO job) onOpenJobDetail;

  @override
  Widget build(BuildContext context) {
    final JobListVO? embeddedJob = message.embeddedJob;
    final double bubbleStartInset = 18;
    final double bubbleTopInset = 20;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: bubbleStartInset,
              top: bubbleTopInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.7,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
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
                if (embeddedJob != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _EmbeddedJobCard(
                    job: embeddedJob,
                    isApplying: applyingJobIds.contains(embeddedJob.jobId),
                    isApplied: appliedJobIds.contains(embeddedJob.jobId),
                    onApply: () => onApplyJob(embeddedJob),
                    onTap: () => onOpenJobDetail(embeddedJob),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/images/icon_ai_bot.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMessageItem extends StatelessWidget {
  const _UserMessageItem({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickQuestion extends StatelessWidget {
  const _QuickQuestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
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

  /// 构建 AI 推荐岗位卡片，支持跳转详情与直接投递。
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  job.formatSalary(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
  /// 组装 AI 推荐岗位展示的薪资文案。
  String formatSalary() {
    final String currency = salaryCurrency.isEmpty ? '¥' : salaryCurrency;
    final String minText = salaryMin % 1 == 0
        ? salaryMin.toInt().toString()
        : salaryMin.toStringAsFixed(1);
    final String maxText = salaryMax % 1 == 0
        ? salaryMax.toInt().toString()
        : salaryMax.toStringAsFixed(1);
    final String rangeText = salaryMax > 0
        ? '$currency$minText~$maxText'
        : '$currency$minText';
    return salaryPeriod.isEmpty ? rangeText : '$rangeText/$salaryPeriod';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '消息.发消息'.tr(),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              height: 44,
              child: FloatingActionButton(
                // 发送按钮不需要 Hero 动画，显式关闭以避免与其他 FAB 冲突。
                heroTag: null,
                onPressed: onSend,
                backgroundColor: AppColors.brand,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
