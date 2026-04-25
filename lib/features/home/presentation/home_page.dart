import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/tag_chip.dart';

/// 首页（按 Figma 截图还原，数据先静态占位）。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                const CircleAvatar(radius: 22, backgroundColor: AppColors.chipBackground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '早上好，程先生',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '德国',
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
            const SizedBox(height: 14),
            const AppSearchBar(hintText: '搜索签证服务/欧洲岗位'),
            const SizedBox(height: 14),
            _ShortcutRow(
              items: const <_ShortcutItem>[
                _ShortcutItem(label: 'AI招聘', icon: Icons.auto_awesome),
                _ShortcutItem(label: '欧洲招聘', icon: Icons.work_outline),
                _ShortcutItem(label: '签证服务', icon: Icons.assignment_outlined),
                _ShortcutItem(label: '我的简历', icon: Icons.badge_outlined),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Image.asset(
                '.figma/image/moe2ehkm-a8dlv0s.png',
                height: 104,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: '热门签证套餐',
              actionLabel: '更多',
              onActionTap: () {},
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return _VisaMiniCard(
                    title: index == 0 ? '厨师专属签证' : '电工专属签证',
                    price: '¥15,000',
                    country: '德国',
                    rating: '4.8',
                    subtitle: '包含材料审核、翻译、面签辅导',
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: 2,
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: '最新欧洲岗位',
              actionLabel: '更多',
              onActionTap: () {},
            ),
            const SizedBox(height: 10),
            _EmptyPlaceholder(
              title: '暂无岗位数据',
              subtitle: '后续对接岗位列表接口后展示',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items});

  final List<_ShortcutItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((it) {
        return Expanded(
          child: Column(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(it.icon, color: AppColors.brand),
              ),
              const SizedBox(height: 8),
              Text(
                it.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _VisaMiniCard extends StatelessWidget {
  const _VisaMiniCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.country,
  });

  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final String country;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242,
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                price,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              TagChip(label: country),
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 16, color: AppColors.warning),
              const SizedBox(width: 2),
              Text(
                rating,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

