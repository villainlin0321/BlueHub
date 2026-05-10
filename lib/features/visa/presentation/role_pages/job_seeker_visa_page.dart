import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/visa_service_card.dart';
import '../../../me/data/collection_models.dart' show CollectionBO;
import '../../../me/data/collection_providers.dart';
import '../../../service_detail/presentation/service_detail_page.dart';
import '../../data/provider_models.dart';
import '../../data/provider_providers.dart';

/// 求职者签证页。
class JobSeekerVisaPage extends ConsumerStatefulWidget {
  const JobSeekerVisaPage({super.key});

  @override
  ConsumerState<JobSeekerVisaPage> createState() => _JobSeekerVisaPageState();
}

class _JobSeekerVisaPageState extends ConsumerState<JobSeekerVisaPage> {
  int _selectedTabIndex = 0;
  final Set<int> _collectingPackageIds = <int>{};
  final Map<int, bool> _collectedOverrides = <int, bool>{};

  static const List<String> _tabs = <String>['推荐套餐', '德国签证', '法国签证', '意大利签证'];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<PageResult<VisaProviderListVO>> providersAsync = ref.watch(
      visaProviderListProvider(_resolveTabQuery(_selectedTabIndex)),
    );
    final AsyncValue<Set<int>> collectedVisaPackageIdsAsync = ref.watch(
      collectedVisaPackageIdsProvider,
    );

    return JobSeekerPageBackground(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding + 20),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _VisaProviderListSection(
                providersAsync: providersAsync,
                collectedVisaPackageIdsAsync: collectedVisaPackageIdsAsync,
                collectingPackageIds: _collectingPackageIds,
                onRetry: () {
                  ref.invalidate(
                    visaProviderListProvider(
                      _resolveTabQuery(_selectedTabIndex),
                    ),
                  );
                },
                onToggleCollection: _handleToggleCollection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 将当前签证标签映射为后端列表接口的 tab 参数。
  String? _resolveTabQuery(int index) {
    return switch (index) {
      1 => 'de',
      2 => 'fr',
      3 => 'it',
      _ => 'recommended',
    };
  }

  /// 切换签证列表卡片的收藏状态，并同步刷新详情页与收藏页。
  Future<void> _handleToggleCollection(VisaProviderListVO item) async {
    final int packageId = item.latestPackage.packageId;
    if (packageId <= 0 || _collectingPackageIds.contains(packageId)) {
      return;
    }

    final Set<int>? collectedIds = ref
        .read(collectedVisaPackageIdsProvider)
        .asData
        ?.value;
    final bool isCollected =
        _collectedOverrides[packageId] ??
        collectedIds?.contains(packageId) ??
        false;

    setState(() {
      _collectingPackageIds.add(packageId);
    });

    try {
      final service = ref.read(collectionServiceProvider);
      final request = CollectionBO(
        targetType: 'visa_package',
        targetId: packageId,
      );
      if (isCollected) {
        await service.removeCollection(request: request);
      } else {
        await service.addCollection(request: request);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _collectingPackageIds.remove(packageId);
        _collectedOverrides[packageId] = !isCollected;
      });
      ref.read(collectionRefreshTickProvider.notifier).bump();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(isCollected ? '已取消收藏' : '收藏成功')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _collectingPackageIds.remove(packageId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resolveVisaCollectionErrorMessage(error))),
      );
    }
  }
}

class _VisaProviderListSection extends StatelessWidget {
  const _VisaProviderListSection({
    required this.providersAsync,
    required this.collectedVisaPackageIdsAsync,
    required this.collectingPackageIds,
    required this.onRetry,
    required this.onToggleCollection,
  });

  final AsyncValue<PageResult<VisaProviderListVO>> providersAsync;
  final AsyncValue<Set<int>> collectedVisaPackageIdsAsync;
  final Set<int> collectingPackageIds;
  final VoidCallback onRetry;
  final Future<void> Function(VisaProviderListVO item) onToggleCollection;

  /// 根据接口状态切换签证列表区块的加载、错误、空态和正常列表。
  @override
  Widget build(BuildContext context) {
    return providersAsync.when(
      data: (PageResult<VisaProviderListVO> pageResult) {
        if (pageResult.list.isEmpty) {
          return const _VisaProviderEmptyState();
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pageResult.list.length,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final VisaProviderListVO item = pageResult.list[index];
            return VisaServiceCard(
              data: item.toVisaServiceCardData(
                isCollected: _resolveCollectedState(item),
              ),
              onTap: () => context.push(
                RoutePaths.serviceDetail,
                extra: ServiceDetailPageArgs(
                  packageId: item.latestPackage.packageId,
                  providerId: item.providerId,
                  initialIsCollected: _resolveCollectedState(item),
                ),
              ),
              onFavoriteTap: () {
                onToggleCollection(item);
              },
              isCollecting: collectingPackageIds.contains(
                item.latestPackage.packageId,
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          '暂无签证服务',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
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
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
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
  return '签证服务加载失败，请稍后重试';
}

/// 提取签证列表收藏操作的错误文案。
String _resolveVisaCollectionErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return '收藏操作失败，请稍后重试';
}

extension on VisaProviderListVO {
  /// 将服务商列表项映射为签证卡片展示数据。
  VisaServiceCardData toVisaServiceCardData({required bool isCollected}) {
    return VisaServiceCardData(
      title: name.trim().isEmpty ? '签证服务商' : name,
      avatarUrl: logoUrl.trim().isEmpty ? null : logoUrl.trim(),
      rating: rating.toStringAsFixed(1),
      cases: caseCount > 0 ? '服务案例$caseCount' : '暂无服务案例',
      tags: tags.isEmpty ? <String>['签证服务'] : tags,
      description: brief.trim().isEmpty ? '暂无服务商简介' : brief.trim(),
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: latestPackage.name.trim().isEmpty
              ? '推荐套餐'
              : latestPackage.name,
          price: _formatVisaListPrice(latestPackage.priceFrom),
        ),
      ],
      verified: isVerified,
      isCollected: isCollected,
    );
  }
}

/// 格式化签证列表卡片价格，列表接口默认按人民币返回展示。
String _formatVisaListPrice(double price) {
  final String value = price % 1 == 0
      ? price.toInt().toString()
      : price.toStringAsFixed(1);
  return '¥$value';
}

class _VisaHeroSection extends StatelessWidget {
  const _VisaHeroSection({required this.selectedIndex, required this.onTabTap});

  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: topPadding + 13, bottom: 10, left: 20),
          child: Text(
            '服务商与签证套餐',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _VisaSearchBar(),
        ),
        const SizedBox(height: 14),
        _VisaTabRow(selectedIndex: selectedIndex, onTap: onTabTap),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _VisaSearchBar extends StatelessWidget {
  const _VisaSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            '搜索签证服务/欧洲岗位',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFBFBFBF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisaTabRow extends StatelessWidget {
  const _VisaTabRow({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 39),
        itemCount: _JobSeekerVisaPageState._tabs.length,
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
                _JobSeekerVisaPageState._tabs[index],
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF096DD9)
                      : const Color(0xFF171A1D),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  height: 18 / 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
