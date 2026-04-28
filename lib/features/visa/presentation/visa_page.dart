import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/visa_service_card.dart';

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brand.withValues(alpha: 0.10)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? AppColors.brand : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? AppColors.brand
                              : AppColors.textSecondary,
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
            VisaServiceCard(
              data: const VisaServiceCardData(
                title: '德国厨师专属工作签证',
                rating: '4.8',
                cases: '服务案例1.2K',
                tags: <String>['过签率高', '办理快'],
                description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国、意大利',
                packages: <VisaServicePackageData>[
                  VisaServicePackageData(
                    title: '德国厨师专签标准包包包包包包包',
                    price: '¥15,000',
                  ),
                ],
                verified: true,
              ),
              onTap: () => context.push(RoutePaths.serviceDetail),
            ),
            const SizedBox(height: 12),
            VisaServiceCard(
              data: const VisaServiceCardData(
                title: '法签通个人服务',
                rating: '4.8',
                cases: '服务案例1.2K',
                tags: <String>['工作签', '个人旅游'],
                description: '提供法国工作签证、旅游签证办理，一对一指导',
                packages: <VisaServicePackageData>[
                  VisaServicePackageData(title: '法国工作签加急', price: '¥18,000'),
                ],
              ),
              onTap: () => context.push(RoutePaths.serviceDetail),
            ),
            const SizedBox(height: 12),
            VisaServiceCard(
              data: const VisaServiceCardData(
                title: '意游签证中心',
                rating: '4.8',
                cases: '服务案例1.2K',
                tags: <String>['加急办理', '材料辅导'],
                description: '意大利商务签、护理工定制签证服务',
                packages: <VisaServicePackageData>[
                  VisaServicePackageData(title: '意大利劳务签', price: '¥15,000'),
                ],
                verified: true,
              ),
              onTap: () => context.push(RoutePaths.serviceDetail),
            ),
            const SizedBox(height: 12),
            VisaServiceCard(
              data: const VisaServiceCardData(
                title: '中欧出海签证服务',
                rating: '4.8',
                cases: '服务案例1.2K',
                tags: <String>['过签率高', '办理快'],
                description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国...',
                packages: <VisaServicePackageData>[
                  VisaServicePackageData(title: '德国厨师专签标准包', price: '¥12,000'),
                ],
              ),
              onTap: () => context.push(RoutePaths.serviceDetail),
            ),
          ],
        ),
      ),
    );
  }
}
