import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/visa_service_card.dart';
import '../../../me/data/collection_providers.dart';
import '../../../service_detail/presentation/service_detail_page.dart';
import '../../data/provider_models.dart';
import '../../data/provider_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 求职者签证页。
class JobSeekerVisaPage extends ConsumerStatefulWidget {
  const JobSeekerVisaPage({super.key});

  @override
  ConsumerState<JobSeekerVisaPage> createState() => _JobSeekerVisaPageState();
}

class _JobSeekerVisaPageState extends ConsumerState<JobSeekerVisaPage> {
  int _selectedTabIndex = 0;

  VisaProviderListQuery get _query => VisaProviderListQuery(
    page: 1,
    pageSize: 50,
    tab: _resolveTabQuery(_selectedTabIndex),
  );

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<PageResult<VisaProviderListVO>> providersAsync = ref.watch(
      visaProviderListProvider(_query),
    );
    final AsyncValue<Set<int>> collectedVisaPackageIdsAsync = ref.watch(
      collectedVisaPackageIdsProvider,
    );

    return JobSeekerPageBackground(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _VisaHeroSection(
            selectedIndex: _selectedTabIndex,
            onTabTap: (int index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _VisaProviderListSection(
                  providersAsync: providersAsync,
                  collectedVisaPackageIdsAsync: collectedVisaPackageIdsAsync,
                  onRetry: () {
                    ref.invalidate(visaProviderListProvider(_query));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 将当前签证标签映射为后端列表接口的 tab 参数。
  String? _resolveTabQuery(int index) {
    return switch (index) {
      1 => 'de',
      2 => 'fr',
      3 => 'it',
      4 => 'uk',
      _ => 'recommended',
    };
  }
}

class _VisaProviderListSection extends StatelessWidget {
  const _VisaProviderListSection({
    required this.providersAsync,
    required this.collectedVisaPackageIdsAsync,
    required this.onRetry,
  });

  final AsyncValue<PageResult<VisaProviderListVO>> providersAsync;
  final AsyncValue<Set<int>> collectedVisaPackageIdsAsync;
  final VoidCallback onRetry;

  /// 根据接口状态切换签证列表区块的加载、错误、空态和正常列表。
  @override
  Widget build(BuildContext context) {
    return providersAsync.when(
      data: (PageResult<VisaProviderListVO> pageResult) {
        if (pageResult.list.isEmpty) {
          return _VisaProviderEmptyState();
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pageResult.list.length,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final VisaProviderListVO item = pageResult.list[index];
            final bool isCollected = _resolveCollectedState(item);
            return VisaServiceCard(
              data: item.toVisaServiceCardData(),
              onTap: () => context.push(
                RoutePaths.serviceDetail,
                extra: ServiceDetailPageArgs(
                  packageId: item.latestPackage.packageId,
                  providerId: item.providerId,
                  initialIsCollected: isCollected,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) {
        return _VisaProviderErrorState(
          message: _resolveVisaProviderErrorMessage(error),
          onRetry: onRetry,
        );
      },
    );
  }

  /// 解析签证卡片当前收藏态，优先使用真实收藏列表结果。
  bool _resolveCollectedState(VisaProviderListVO item) {
    final Set<int>? collectedIds = collectedVisaPackageIdsAsync.asData?.value;
    if (collectedIds == null) {
      return false;
    }
    return collectedIds.contains(item.latestPackage.packageId);
  }
}

class _VisaProviderEmptyState extends StatelessWidget {
  const _VisaProviderEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: AppEmptyState(
          message: '签证页.暂无签证服务'.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}

class _VisaProviderErrorState extends StatelessWidget {
  const _VisaProviderErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.pingFangRegular(
                fontSize: 14,
                color: Color(0xFF8C8C8C),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

/// 提取签证服务商列表的错误文案。
String _resolveVisaProviderErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return '签证页.签证服务加载失败'.tr();
}

extension on VisaProviderListVO {
  /// 将服务商列表项映射为签证卡片展示数据。
  VisaServiceCardData toVisaServiceCardData() {
    return VisaServiceCardData(
      title: name.trim().isEmpty ? '签证页.签证服务商'.tr() : name,
      avatarUrl: logoUrl.trim().isEmpty ? null : logoUrl.trim(),
      rating: rating.toStringAsFixed(1),
      cases: caseCount > 0
          ? '签证页.服务案例数'.tr(
              namedArgs: <String, String>{'count': caseCount.toString()},
            )
          : '签证页.暂无服务案例'.tr(),
      tags: tags.isEmpty ? <String>['首页.签证服务'.tr()] : tags,
      description: brief.trim().isEmpty ? '签证页.暂无服务商简介'.tr() : brief.trim(),
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: latestPackage.name.trim().isEmpty
              ? '签证页.推荐套餐'.tr()
              : latestPackage.name,
          currency: latestPackage.currency,
          price: _formatVisaListPrice(latestPackage.priceFrom),
        ),
      ],
      verified: isVerified,
    );
  }
}

/// 格式化签证列表卡片价格数值，货币符号由卡片组件统一渲染。
String _formatVisaListPrice(double price) {
  return price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(1);
}

class _VisaHeroSection extends StatelessWidget {
  const _VisaHeroSection({required this.selectedIndex, required this.onTabTap});

  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10, left: 20),
            child: Text(
              '签证页.服务商与签证套餐'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ),
          // const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const _VisaSearchBar(),
          ),
          const SizedBox(height: 14),
          _VisaTabRow(selectedIndex: selectedIndex, onTap: onTabTap),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _VisaSearchBar extends StatelessWidget {
  const _VisaSearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.visaProviderSearch),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/mon8on2b-h3091wk.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '首页.搜索签证服务欧洲岗位'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TestStyle.pingFangRegular(
                    fontSize: 14,
                    color: Color(0xFFBFBFBF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisaTabRow extends StatelessWidget {
  const _VisaTabRow({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  List<String> get _tabs => <String>[
    tr('签证页.推荐套餐'),
    tr('签证页.德国签证'),
    tr('签证页.法国签证'),
    tr('签证页.意大利签证'),
    tr('签证页.英国推荐'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 39),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7AAAF4)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _tabs[index],
                style: TestStyle.medium(
                  fontSize: 12,
                  color: selected
                      ? const Color(0xFF096DD9)
                      : const Color(0xFF171A1D),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
