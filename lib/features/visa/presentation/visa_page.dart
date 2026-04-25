import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/tag_chip.dart';

/// 签证页：服务商与签证套餐列表（按 Figma 截图还原，数据先静态占位）。
class VisaPage extends StatefulWidget {
  const VisaPage({super.key});

  @override
  State<VisaPage> createState() => _VisaPageState();
}

class _VisaPageState extends State<VisaPage> {
  int _tabIndex = 0;

  static const _tabs = <String>['推荐套餐', '德国签证', '法国签证', '意大利签证'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: <Widget>[
            Text(
              '服务商与签证套餐',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            const AppSearchBar(hintText: '搜索签证服务/欧洲岗位'),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final selected = index == _tabIndex;
                  return InkWell(
                    onTap: () => setState(() => _tabIndex = index),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand.withValues(alpha: 0.10) : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: selected ? AppColors.brand : AppColors.divider),
                      ),
                      child: Text(
                        _tabs[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: selected ? AppColors.brand : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: _tabs.length,
              ),
            ),
            const SizedBox(height: 12),
            const _VisaProviderCard(
              title: '德国厨师专属工作签',
              rating: '4.8',
              cases: '服务案例1.2K',
              tags: <String>['过签率高', '办理快'],
              description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国、意大利...',
              packageName: '德国厨师专签标准包包包包包包包',
              price: '¥15,000',
              verified: true,
            ),
            const SizedBox(height: 12),
            const _VisaProviderCard(
              title: '法签通个人服务',
              rating: '4.8',
              cases: '服务案例1.2K',
              tags: <String>['工作签', '个人旅游'],
              description: '提供法国工作签证、旅游签证办理，一对一指导',
              packageName: '法国工作签加急',
              price: '¥18,000',
              verified: false,
            ),
            const SizedBox(height: 12),
            const _VisaProviderCard(
              title: '意游签证中心',
              rating: '4.8',
              cases: '服务案例1.2K',
              tags: <String>['加急办理', '材料辅导'],
              description: '意大利商务签、护理工定制签证服务',
              packageName: '意大利劳务签',
              price: '¥15,000',
              verified: true,
            ),
            const SizedBox(height: 12),
            const _VisaProviderCard(
              title: '中欧出海签证服务',
              rating: '4.8',
              cases: '服务案例1.2K',
              tags: <String>['过签率高', '办理快'],
              description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国...',
              packageName: '德国厨师专签标准包',
              price: '¥12,000',
              verified: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisaProviderCard extends StatelessWidget {
  const _VisaProviderCard({
    required this.title,
    required this.rating,
    required this.cases,
    required this.tags,
    required this.description,
    required this.packageName,
    required this.price,
    required this.verified,
  });

  final String title;
  final String rating;
  final String cases;
  final List<String> tags;
  final String description;
  final String packageName;
  final String price;
  final bool verified;

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
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.chipBackground,
                child: Icon(Icons.person, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (verified) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'V认证',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.star, size: 16, color: AppColors.warning),
              const SizedBox(width: 2),
              Text(
                rating,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 10),
              Text(
                cases,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 10),
              ...tags
                  .take(2)
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TagChip(
                        label: t,
                        backgroundColor: AppColors.brand.withValues(alpha: 0.10),
                        textColor: AppColors.brand,
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
