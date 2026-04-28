import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/job_position_card.dart';

/// 招聘列表页（按 Figma 截图还原，列表数据先静态占位）。
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: <Widget>[
            Text(
              '欧洲招聘',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const AppSearchBar(hintText: '搜索签证服务/欧洲岗位'),
            const SizedBox(height: 12),
            const _FilterRow(),
            const SizedBox(height: 12),
            _JobCard(
              data: const JobPositionCardData(
                title: '中餐厨师 (包食宿)',
                salary: '€2,500~3,500',
                requirementTags: <String>['3-5年经验', '厨师证高级', '提供签证'],
                highlightTags: <String>['急招', '包吃住'],
                company: '柏林老四川餐厅',
                location: '德国·柏林',
                showApplyButton: true,
              ),
              onApply: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('一键投递（占位）')));
              },
              onTap: () => context.push(RoutePaths.jobDetail),
            ),
            const SizedBox(height: 12),
            _JobCard(
              data: const JobPositionCardData(
                title: '建筑工(包食宿)',
                salary: '€2,200~2,800',
                requirementTags: <String>['3-5年经验', '不限学历', '包食宿'],
                highlightTags: <String>['年假回国机票'],
                company: '柏林老四川餐厅',
                location: '德国·柏林',
                showApplyButton: true,
              ),
              onApply: () {},
            ),
            const SizedBox(height: 12),
            _JobCard(
              data: const JobPositionCardData(
                title: '中餐帮厨',
                salary: '€1,500~2,000',
                requirementTags: <String>['3-5年经验', '厨师证', '提供签证'],
                highlightTags: <String>['双休'],
                company: '柏林老四川餐厅',
                location: '德国·柏林',
                showApplyButton: true,
              ),
              onApply: () {},
            ),
            const SizedBox(height: 12),
            _JobCard(
              data: const JobPositionCardData(
                title: '养老院护理员',
                salary: '€2,000~2,500',
                requirementTags: <String>['3-5年经验', '营养健康证', '提供签证'],
                highlightTags: <String>['长白班'],
                company: '柏林老四川餐厅',
                location: '德国·柏林',
                showApplyButton: true,
              ),
              onApply: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _FilterChip(label: '全部国家', onTap: () {}),
        const SizedBox(width: 10),
        _FilterChip(label: '全部分类', onTap: () {}),
        const SizedBox(width: 10),
        _FilterChip(label: '薪资要求', onTap: () {}, highlighted: true),
        const Spacer(),
        _FilterChip(label: '筛选', onTap: () {}, icon: Icons.tune),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? AppColors.brand : AppColors.divider;
    final textColor = highlighted ? AppColors.brand : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icon == null) ...<Widget>[
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, size: 18, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.data, required this.onApply, this.onTap});

  final JobPositionCardData data;
  final VoidCallback onApply;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return JobPositionCard(data: data, onApply: onApply, onTap: onTap);
  }
}
