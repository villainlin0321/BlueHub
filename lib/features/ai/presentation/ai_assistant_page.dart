import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/job_seeker_page_background.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../jobs/data/job_models.dart';
import '../../jobs/data/job_providers.dart';
import '../../jobs/presentation/job_apply_helper.dart';
import '../../jobs/presentation/job_detail_page.dart';

/// AI 助手页（按 Figma 截图还原：对话流 + 推荐问题 + 输入框）。
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _controller = TextEditingController();
  bool _isApplyingRecommendedJob = false;
  bool _isAppliedRecommendedJob = false;
  bool _isRecommendationLoading = true;
  JobListVO? _recommendedJob;

  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: '你好！我是您的专属AI助手。请问有什么我可以帮您的？',
      footer: null,
    ),
    const _ChatMessage(
      role: _ChatRole.user,
      text: '我从事电气技术工作8年，持高级电工证，擅长工业电气系统安装调试、设备维护升级、配电方案优化及安全管理',
      footer: null,
    ),
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: '请稍后，我这边为您匹配一下岗位，请问您有德国语音证书吗？',
      footer: '由西格玛AI提供',
    ),
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: '给您推荐了以下几个厨师岗位，看看合不合适？',
      footer: '由西格玛AI提供',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendedJob();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text, footer: null));
      _controller.clear();
    });
  }

  /// 加载一个真实岗位作为 AI 推荐卡片的数据来源，确保跳详情时有真实 `jobId`。
  Future<void> _loadRecommendedJob() async {
    try {
      final response = await ref.read(jobServiceProvider).listJobs(
        page: 1,
        pageSize: 1,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecommendationLoading = false;
        _recommendedJob = response.list.isEmpty ? null : response.list.first;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecommendationLoading = false;
        _recommendedJob = null;
      });
    }
  }

  /// 处理 AI 推荐卡片的投递操作，使用真实岗位 ID 发起投递。
  Future<void> _handleApplyRecommendedJob() async {
    if (_isApplyingRecommendedJob || _isAppliedRecommendedJob) {
      return;
    }

    setState(() {
      _isApplyingRecommendedJob = true;
    });

    final String? errorMessage = await submitJobApplication(
      context,
      jobId: _recommendedJob?.jobId,
    );
    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      setState(() {
        _isApplyingRecommendedJob = false;
        _isAppliedRecommendedJob = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投递成功')));
      return;
    }

    setState(() {
      _isApplyingRecommendedJob = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  /// 跳转到真实职位详情页。
  void _openRecommendedJobDetail() {
    final JobListVO? job = _recommendedJob;
    if (job == null) {
      return;
    }
    context.push(
      RoutePaths.jobDetail,
      extra: JobDetailPageArgs(jobId: job.jobId),
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
                      'AI助手',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('历史记录'),
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
                    ..._messages.map((m) => _ChatBubble(message: m)),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: '推荐适合我的欧洲签证服务商',
                      onTap: () => _controller.text = '推荐适合我的欧洲签证服务商',
                    ),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: '推荐匹配我的欧洲岗位',
                      onTap: () => _controller.text = '推荐匹配我的欧洲岗位',
                    ),
                    const SizedBox(height: 10),
                    _QuickQuestion(
                      label: '签证办理流程是什么',
                      onTap: () => _controller.text = '签证办理流程是什么',
                    ),
                    const SizedBox(height: 10),
                    if (_isRecommendationLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_recommendedJob != null)
                      _EmbeddedJobCard(
                        job: _recommendedJob!,
                        isApplying: _isApplyingRecommendedJob,
                        isApplied: _isAppliedRecommendedJob,
                        onApply: _handleApplyRecommendedJob,
                        onTap: _openRecommendedJobDetail,
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _Composer(
                controller: _controller,
                onSend: _send,
              ),
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
  });

  final _ChatRole role;
  final String text;
  final String? footer;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    final bg = isUser ? AppColors.brand : AppColors.surface;
    final fg = isUser ? Colors.white : AppColors.textPrimary;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!isUser)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.chipBackground,
                  child: Icon(Icons.smart_toy, size: 16, color: AppColors.brand),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fg,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
              if (isUser)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.chipBackground,
                  child: Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                ),
            ],
          ),
          if (message.footer != null && !isUser) ...<Widget>[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                message.footer!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
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
    final List<String> tagLabels = job.tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != '急招'),
      if (job.hasVisaSupport && !tagLabels.contains('提供签证')) '提供签证',
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[
      if (job.isUrgent) '急招',
    ];
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
                  onPressed: isApplying || isApplied
                      ? null
                      : () {
                          onApply();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(isApplied ? '已投递' : (isApplying ? '投递中...' : '一键投递')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.place, size: 18, color: AppColors.textTertiary),
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
    final String rangeText = salaryMax > 0 ? '$currency$minText~$maxText' : '$currency$minText';
    return salaryPeriod.isEmpty ? rangeText : '$rangeText/$salaryPeriod';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
  });

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
                  decoration: const InputDecoration(
                    hintText: '发消息...',
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
