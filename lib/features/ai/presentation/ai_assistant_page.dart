import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/job_seeker_page_background.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../data/ai_models.dart';
import '../data/ai_providers.dart';
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
  bool _isHistoryLoading = false;

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
    if (_hasValidSessionId(widget.sessionId)) {
      await _loadHistoryMessages(widget.sessionId!);
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

  /// 发送本地输入消息，仅追加用户侧消息气泡。
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(
        _ChatMessage(role: _ChatRole.user, text: text, footer: null),
      );
      _controller.clear();
    });
  }

  /// 拉取会话历史，并将服务端消息映射为页面内部消息模型。
  Future<void> _loadHistoryMessages(int sessionId) async {
    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final List<AiMessage> history = await ref
          .read(aiServiceProvider)
          .getChatHistory(sessionId: sessionId);
      history.sort(
        (AiMessage left, AiMessage right) =>
            left.aiMsgId.compareTo(right.aiMsgId),
      );
      if (!mounted) {
        return;
      }
      setState(() {
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
  _ChatMessage _mapHistoryMessage(AiMessage message) {
    final _ChatRole role = _parseChatRole(message.role);
    final bool isAssistant = role == _ChatRole.assistant;
    return _ChatMessage(
      role: role,
      text: message.content.trim(),
      footer: isAssistant
          ? (_parseFooterFromExtraData(message.extraData) ?? 'AI.由西格玛AI提供'.tr())
          : null,
      extraData: message.extraData,
      embeddedJob: isAssistant
          ? _parseEmbeddedJobFromExtraData(message.extraData)
          : null,
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
        extraData: job == null ? null : jsonEncode(job.toJson()),
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

  /// 解析额外数据中的 footer 文案，兼容多种字段命名。
  String? _parseFooterFromExtraData(String extraData) {
    final Map<String, Object?>? json = _decodeJsonMap(extraData);
    if (json == null) {
      return null;
    }
    for (final String key in <String>[
      'footer',
      'footerText',
      'providerLabel',
      'sourceLabel',
    ]) {
      final String? value = _readStringValue(json[key]);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// 从额外数据中提取岗位卡片，兼容嵌套对象与列表结构。
  JobListVO? _parseEmbeddedJobFromExtraData(String extraData) {
    final Map<String, Object?>? json = _decodeJsonMap(extraData);
    if (json == null) {
      return null;
    }
    final Map<String, Object?>? jobJson = _findEmbeddedJobJson(json);
    if (jobJson == null) {
      return null;
    }
    try {
      return JobListVO.fromJson(_normalizeJobJson(jobJson));
    } catch (_) {
      return null;
    }
  }

  /// 安全解码 JSON Map，避免 extraData 非 JSON 时影响页面渲染。
  Map<String, Object?>? _decodeJsonMap(String value) {
    final String normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(normalizedValue);
      return _asJsonMap(decoded);
    } catch (_) {
      return null;
    }
  }

  /// 递归查找最像岗位结构的对象，优先命中特定业务键名。
  Map<String, Object?>? _findEmbeddedJobJson(Object? value) {
    final Map<String, Object?>? json = _asJsonMap(value);
    if (json != null) {
      if (_looksLikeJobJson(json)) {
        return json;
      }
      for (final String key in <String>[
        'job',
        'jobCard',
        'embeddedJob',
        'payload',
        'data',
      ]) {
        final Map<String, Object?>? nestedJson = _findEmbeddedJobJson(
          json[key],
        );
        if (nestedJson != null) {
          return nestedJson;
        }
      }
      for (final Object? nestedValue in json.values) {
        final Map<String, Object?>? nestedJson = _findEmbeddedJobJson(
          nestedValue,
        );
        if (nestedJson != null) {
          return nestedJson;
        }
      }
    }

    final List<Object?>? items = _asObjectList(value);
    if (items == null) {
      return null;
    }
    for (final Object? item in items) {
      final Map<String, Object?>? nestedJson = _findEmbeddedJobJson(item);
      if (nestedJson != null) {
        return nestedJson;
      }
    }
    return null;
  }

  /// 判断对象是否具备岗位卡片的关键字段。
  bool _looksLikeJobJson(Map<String, Object?> json) {
    return (json.containsKey('jobId') || json.containsKey('job_id')) &&
        (json.containsKey('title') || json.containsKey('job_title')) &&
        json.containsKey('employer');
  }

  /// 将 extraData 中可能出现的蛇形字段映射为页面已使用的岗位模型字段。
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
      'employer': _normalizeEmployerJson(_asJsonMap(json['employer'])),
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

  /// 将运行时对象安全转换为 JSON Map。
  Map<String, Object?>? _asJsonMap(Object? value) {
    if (value is Map<Object?, Object?>) {
      return value.map(
        (Object? key, Object? nestedValue) =>
            MapEntry<String, Object?>(key.toString(), nestedValue),
      );
    }
    return null;
  }

  /// 将运行时对象安全转换为对象列表。
  List<Object?>? _asObjectList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }
    if (value is List<dynamic>) {
      return value.cast<Object?>();
    }
    return null;
  }

  /// 从多态 JSON 值中读取字符串，避免类型漂移导致解析失败。
  String? _readStringValue(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
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
                    TextButton(onPressed: () {}, child: Text('AI.历史记录'.tr())),
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
              _Composer(controller: _controller, onSend: _send),
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
