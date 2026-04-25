import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';

/// 我的页（按 Figma 截图还原，菜单点击暂用提示占位）。
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '我的',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ProfileCard(
              name: '程先生',
              phone: '132****3456',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _MenuCard(
              items: const <_MenuItem>[
                _MenuItem(icon: Icons.description_outlined, label: '简历管理'),
                _MenuItem(icon: Icons.local_shipping_outlined, label: '订单进度'),
                _MenuItem(icon: Icons.bookmark_border, label: '我的收藏'),
                _MenuItem(icon: Icons.support_agent_outlined, label: '客服中心'),
              ],
              onItemTap: (label) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label（占位）')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.onTap,
  });

  final String name;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.chipBackground,
                child: Icon(Icons.person, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '已实名',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const <Widget>[
              _StatItem(value: '3', label: '我的订单'),
              _StatItem(value: '85%', label: '我的简历'),
              _StatItem(value: '3', label: '我的应聘'),
              _StatItem(value: '24', label: '我的收藏'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.items,
    required this.onItemTap,
  });

  final List<_MenuItem> items;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: items.map((it) {
          final idx = items.indexOf(it);
          return InkWell(
            onTap: () => onItemTap(it.label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: idx == 0
                    ? null
                    : const Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(it.icon, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

