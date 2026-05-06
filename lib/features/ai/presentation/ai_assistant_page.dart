import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/job_seeker_page_background.dart';
import '../../../shared/widgets/tag_chip.dart';

/// AI 助手页（按 Figma 截图还原：对话流 + 推荐问题 + 输入框）。
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _controller = TextEditingController();

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
                    const _EmbeddedJobCard(),
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
  const _EmbeddedJobCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  '中餐厨师 (包食宿)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '€2,500~3,500',
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
            children: const <Widget>[
              TagChip(label: '3-5年经验'),
              TagChip(label: '厨师证高级'),
              TagChip(label: '提供签证'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              TagChip(label: '急招', backgroundColor: AppColors.chipBackground, textColor: AppColors.danger),
              TagChip(label: '包吃住'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(Icons.apartment, size: 18, color: AppColors.brand),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '柏林老四川餐厅',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('一键投递（占位）')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('一键投递'),
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
                '德国·柏林',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
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
