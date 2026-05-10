import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../visa/data/provider_models.dart'
    hide MaterialVO, TierVO, VisaPackageVO;
import '../../visa/data/provider_providers.dart';
import '../../visa/data/visa_package_models.dart';
import '../../visa/data/visa_package_providers.dart';
import 'service_detail_bottom_sheets.dart';
import 'service_detail_merchant_tab.dart';
import 'service_detail_package_tab.dart';
import 'service_detail_review_tab.dart';

class ServiceDetailPageArgs {
  const ServiceDetailPageArgs({required this.packageId, this.providerId});

  final int packageId;
  final int? providerId;
}

/// 签证服务详情页：根据套餐和服务商参数加载真实详情数据。
class ServiceDetailPage extends ConsumerStatefulWidget {
  const ServiceDetailPage({super.key, this.args});

  final ServiceDetailPageArgs? args;

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  static const double _expandedAppBarHeight = 292;
  static const String _heroAsset =
      'assets/images/service_detail_top_background.png';
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _favoriteAsset =
      'assets/images/service_detail_favorite.svg';
  static const String _shareAsset = 'assets/images/service_detail_share.svg';
  static const String _verifiedBadgeAsset =
      'assets/images/service_detail_verified_badge.png';
  static const String _consultIconAsset =
      'assets/images/service_detail_consult_icon.svg';

  int _selectedPackageIndex = 0;
  bool _isFavorited = false;
  bool _showCollapsedTitle = false;

  @override
  Widget build(BuildContext context) {
    final ServiceDetailPageArgs? args = widget.args;
    if (args == null) {
      return const _ServiceDetailMessagePage(message: '缺少套餐参数，暂时无法打开详情页');
    }

    final AsyncValue<VisaPackageVO> packageAsync = ref.watch(
      visaPackageDetailProvider(args.packageId),
    );
    final AsyncValue<VisaProviderDetailVO>? providerDetailAsync =
        args.providerId == null
        ? null
        : ref.watch(visaProviderDetailProvider(args.providerId!));
    final AsyncValue<ReviewVO>? reviewAsync = args.providerId == null
        ? null
        : ref.watch(visaProviderReviewsProvider(args.providerId!));

    return packageAsync.when(
      loading: () => const _ServiceDetailLoadingPage(),
      error: (Object error, StackTrace stackTrace) {
        return _ServiceDetailMessagePage(
          message: _resolveErrorMessage(error, fallback: '套餐详情加载失败，请稍后重试'),
        );
      },
      data: (VisaPackageVO package) {
        final List<ServicePackageData> servicePackages = package
            .toServicePackages();
        final List<ServiceMaterialData> serviceMaterials = package
            .toServiceMaterials();
        final int selectedPackageIndex = _resolveSelectedPackageIndex(
          servicePackages.length,
        );
        final ServicePackageData? selectedPackage = servicePackages.isEmpty
            ? null
            : servicePackages[selectedPackageIndex];
        final ProviderVO? provider =
            providerDetailAsync?.asData?.value.provider;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: _BottomActionBar(
              consultIconAsset: _consultIconAsset,
              onApplyTap: () => _showApplyBottomSheet(
                serviceTitle: package.name,
                package: selectedPackage,
              ),
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification.depth != 0) {
                  return false;
                }
                final bool shouldShowTitle =
                    notification.metrics.pixels >=
                    _collapseThreshold(context: context);
                if (shouldShowTitle != _showCollapsedTitle) {
                  setState(() => _showCollapsedTitle = shouldShowTitle);
                }
                return false;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      pinned: true,
                      stretch: true,
                      expandedHeight: _expandedAppBarHeight,
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      titleSpacing: 70,
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _showCollapsedTitle ? 1 : 0,
                        child: Text(
                          '服务详情',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF262626),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final double topPadding = MediaQuery.paddingOf(
                            context,
                          ).top;
                          final bool collapsed = _isCollapsed(
                            constraints.biggest.height,
                            topPadding,
                          );
                          final double progress = _collapseProgress(
                            constraints.biggest.height,
                            topPadding,
                          );

                          return _SliverHeroAppBar(
                            imageUrl: package.coverImages.isEmpty
                                ? ''
                                : package.coverImages.first,
                            backAsset: _backAsset,
                            favoriteAsset: _favoriteAsset,
                            shareAsset: _shareAsset,
                            collapsed: collapsed,
                            progress: progress,
                            isFavorited: _isFavorited,
                            onBackTap: () {
                              if (Navigator.of(context).canPop()) {
                                context.pop();
                              }
                            },
                            onFavoriteTap: () {
                              setState(() => _isFavorited = !_isFavorited);
                            },
                            onShareTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('分享功能开发中')),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SummaryPanel(
                        serviceTitle: package.name,
                        selectedPackage: selectedPackage,
                        packageDetail: package,
                        provider: provider,
                        verifiedBadgeAsset: _verifiedBadgeAsset,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: const _PinnedTopTabBarDelegate(
                        child: _ServiceDetailTabBar(),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: <Widget>[
                    ServiceDetailPackageTab(
                      packages: servicePackages,
                      selectedPackageIndex: selectedPackageIndex,
                      onPackageSelected: (int index) {
                        setState(() => _selectedPackageIndex = index);
                      },
                      materials: serviceMaterials,
                    ),
                    ServiceDetailReviewTab(
                      review: reviewAsync?.asData?.value,
                      isLoading: reviewAsync?.isLoading ?? false,
                      errorMessage: args.providerId == null
                          ? '暂无评价数据'
                          : _resolveAsyncErrorMessage(
                              reviewAsync,
                              fallback: '评价加载失败，请稍后重试',
                            ),
                    ),
                    ServiceDetailMerchantTab(
                      verifiedBadgeAsset: _verifiedBadgeAsset,
                      provider: provider,
                      isLoading: providerDetailAsync?.isLoading ?? false,
                      errorMessage: args.providerId == null
                          ? '暂无商家信息'
                          : _resolveAsyncErrorMessage(
                              providerDetailAsync,
                              fallback: '商家信息加载失败，请稍后重试',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 计算头图折叠阈值，统一控制标题显隐。
  double _collapseThreshold({required BuildContext context}) {
    return _expandedAppBarHeight -
        (kToolbarHeight + MediaQuery.paddingOf(context).top) -
        12;
  }

  /// 解析当前有效的档位索引，避免空数组或索引越界。
  int _resolveSelectedPackageIndex(int packageCount) {
    if (packageCount <= 0) {
      return 0;
    }
    if (_selectedPackageIndex < 0) {
      return 0;
    }
    if (_selectedPackageIndex >= packageCount) {
      return packageCount - 1;
    }
    return _selectedPackageIndex;
  }

  /// 判断头图是否已经进入折叠态。
  bool _isCollapsed(double currentHeight, double topPadding) {
    final double minExtent = kToolbarHeight + topPadding;
    return currentHeight <= minExtent + 12;
  }

  /// 计算头图从展开到折叠的过渡进度。
  double _collapseProgress(double currentHeight, double topPadding) {
    final double minExtent = kToolbarHeight + topPadding;
    final double delta = (_expandedAppBarHeight - minExtent).clamp(
      1,
      double.infinity,
    );
    return ((_expandedAppBarHeight - currentHeight) / delta).clamp(0.0, 1.0);
  }

  /// 打开申请弹窗，若没有可选档位则提示用户。
  void _showApplyBottomSheet({
    required String serviceTitle,
    required ServicePackageData? package,
  }) {
    if (package == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前套餐暂无可申请档位')));
      return;
    }
    ServiceDetailApplyBottomSheet.show(
      context: context,
      serviceTitle: serviceTitle,
      package: package,
    );
  }
}

class _ServiceDetailLoadingPage extends StatelessWidget {
  const _ServiceDetailLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ServiceDetailMessagePage extends StatelessWidget {
  const _ServiceDetailMessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('服务详情'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8C8C8C)),
          ),
        ),
      ),
    );
  }
}

class _SliverHeroAppBar extends StatelessWidget {
  const _SliverHeroAppBar({
    required this.imageUrl,
    required this.backAsset,
    required this.favoriteAsset,
    required this.shareAsset,
    required this.collapsed,
    required this.progress,
    required this.isFavorited,
    required this.onBackTap,
    required this.onFavoriteTap,
    required this.onShareTap,
  });

  final String imageUrl;
  final String backAsset;
  final String favoriteAsset;
  final String shareAsset;
  final bool collapsed;
  final double progress;
  final bool isFavorited;
  final VoidCallback onBackTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Color.lerp(
      Colors.white,
      const Color(0xFF262626),
      progress,
    )!;
    final Color buttonBackground = Color.lerp(
      Colors.black.withValues(alpha: 0.28),
      AppColors.surface.withValues(alpha: 0.92),
      progress,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _HeroBackground(imageUrl: imageUrl),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            height: 18,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.18 * (1 - progress)),
                Colors.black.withValues(alpha: 0.06 * (1 - progress)),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: progress),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TopCircleAction(
                    assetPath: backAsset,
                    fallback: Icons.arrow_back_ios_new_rounded,
                    color: iconColor,
                    backgroundColor: buttonBackground,
                    onTap: onBackTap,
                  ),
                  const Spacer(),
                  _TopCircleAction(
                    assetPath: favoriteAsset,
                    fallback: isFavorited
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: isFavorited && collapsed
                        ? AppColors.warning
                        : isFavorited
                        ? const Color(0xFFFFD166)
                        : iconColor,
                    backgroundColor: buttonBackground,
                    onTap: onFavoriteTap,
                  ),
                  const SizedBox(width: 12),
                  _TopCircleAction(
                    assetPath: shareAsset,
                    fallback: Icons.share_outlined,
                    color: iconColor,
                    backgroundColor: buttonBackground,
                    onTap: onShareTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Image.asset(_ServiceDetailPageState._heroAsset, fit: BoxFit.cover);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          _ServiceDetailPageState._heroAsset,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.serviceTitle,
    required this.selectedPackage,
    required this.packageDetail,
    required this.provider,
    required this.verifiedBadgeAsset,
  });

  final String serviceTitle;
  final ServicePackageData? selectedPackage;
  final VisaPackageVO packageDetail;
  final ProviderVO? provider;
  final String verifiedBadgeAsset;

  @override
  Widget build(BuildContext context) {
    final String summaryDescription = provider?.brief.trim().isNotEmpty == true
        ? provider!.brief
        : '预计办理 ${packageDetail.estimatedDays > 0 ? packageDetail.estimatedDays : '--'} 天';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  serviceTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text:
                          selectedPackage?.price ??
                          _formatPrice(0, packageDetail.currency),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFFFE5815),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    TextSpan(
                      text: '起',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (provider?.isVerified == true)
                Image.asset(
                  verifiedBadgeAsset,
                  width: 55.67,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              _SummaryTag(
                label: _formatCountryLabel(packageDetail.targetCountry),
              ),
              _SummaryTag(label: _formatVisaTypeLabel(packageDetail.visaType)),
              if (packageDetail.estimatedDays > 0)
                _SummaryTag(label: '${packageDetail.estimatedDays}天办结'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF595959),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailTabBar extends StatelessWidget {
  const _ServiceDetailTabBar();

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor: Colors.transparent,
        indicator: const _FixedWidthUnderlineIndicator(
          width: 20,
          bottomOffset: 2,
          borderSide: BorderSide(color: Color(0xFF096DD9), width: 2),
        ),
        tabs: const <Widget>[
          _ServiceDetailTab(
            label: '套餐',
            selectedWeight: FontWeight.w500,
            horizontalPadding: EdgeInsets.only(left: 16, right: 16),
          ),
          _ServiceDetailTab(
            label: '评价',
            horizontalPadding: EdgeInsets.only(left: 16, right: 16),
          ),
          _ServiceDetailTab(label: '商家'),
        ],
      ),
    );
  }
}

class _ServiceDetailTab extends StatelessWidget {
  const _ServiceDetailTab({
    required this.label,
    this.selectedWeight = FontWeight.w500,
    this.horizontalPadding = EdgeInsets.zero,
  });

  final String label;
  final FontWeight selectedWeight;
  final EdgeInsets horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final int tabIndex = <String>['套餐', '评价', '商家'].indexOf(label);
        final bool selected = controller.index == tabIndex;
        final TextStyle? labelStyle = Theme.of(context).textTheme.titleMedium
            ?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              height: 1.2,
              fontWeight: selected ? selectedWeight : FontWeight.w400,
            );

        return Tab(
          height: 48,
          child: Padding(
            padding: horizontalPadding,
            child: Text(label, style: labelStyle),
          ),
        );
      },
    );
  }
}

class _FixedWidthUnderlineIndicator extends Decoration {
  const _FixedWidthUnderlineIndicator({
    required this.width,
    this.bottomOffset = 0,
    required this.borderSide,
  });

  final double width;
  final double bottomOffset;
  final BorderSide borderSide;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthUnderlinePainter(
      width: width,
      bottomOffset: bottomOffset,
      borderSide: borderSide,
    );
  }
}

class _FixedWidthUnderlinePainter extends BoxPainter {
  const _FixedWidthUnderlinePainter({
    required this.width,
    required this.bottomOffset,
    required this.borderSide,
  });

  final double width;
  final double bottomOffset;
  final BorderSide borderSide;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null) {
      return;
    }
    final Paint paint = borderSide.toPaint();
    final double y = offset.dy + size.height - borderSide.width - bottomOffset;
    final double x = offset.dx + (size.width - width) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, borderSide.width),
        const Radius.circular(2),
      ),
      paint,
    );
  }
}

class _PinnedTopTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTopTabBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: overlapsContent
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTopTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.consultIconAsset,
    required this.onApplyTap,
  });

  final String consultIconAsset;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        switch (controller.index) {
          case 1:
            return const SizedBox.shrink();
          case 2:
            return const _MerchantBottomActionBar();
          case 0:
          default:
            return _PackageBottomActionBar(
              consultIconAsset: consultIconAsset,
              onApplyTap: onApplyTap,
            );
        }
      },
    );
  }
}

class _PackageBottomActionBar extends StatelessWidget {
  const _PackageBottomActionBar({
    required this.consultIconAsset,
    required this.onApplyTap,
  });

  final String consultIconAsset;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 48,
              height: 44,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {},
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 1,
                      left: 12,
                      width: 24,
                      height: 24,
                      child: AppSvgIcon(
                        assetPath: consultIconAsset,
                        fallback: Icons.headset_mic_outlined,
                        size: 24,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    Positioned(
                      top: 27,
                      left: 3,
                      right: 3,
                      child: Text(
                        '咨询',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8C8C8C),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: onApplyTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '立即申请',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantBottomActionBar extends StatelessWidget {
  const _MerchantBottomActionBar();

  @override
  Widget build(BuildContext context) {
    final TextStyle? secondaryStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(
          color: const Color(0xFF171A1D),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
        );
    final TextStyle? primaryStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
        );

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 169,
              child: OutlinedButton(
                onPressed: () => context.push(RoutePaths.serviceDetailReport),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFD9D9D9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text('举报商家', style: secondaryStyle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 170,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('联系商家', style: primaryStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleAction extends StatelessWidget {
  const _TopCircleAction({
    required this.assetPath,
    required this.fallback,
    required this.onTap,
    this.color = Colors.white,
    this.backgroundColor = const Color(0x47000000),
  });

  final String assetPath;
  final IconData fallback;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AppSvgIcon(
                  assetPath: assetPath,
                  fallback: fallback,
                  size: 18,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF386EF8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 提取异步 Provider 的错误文案，优先透传后端提示。
String? _resolveAsyncErrorMessage<T>(
  AsyncValue<T>? asyncValue, {
  required String fallback,
}) {
  final Object? error = asyncValue?.asError?.error;
  if (error == null) {
    return null;
  }
  return _resolveErrorMessage(error, fallback: fallback);
}

/// 统一处理接口异常文案。
String _resolveErrorMessage(Object error, {required String fallback}) {
  if (error is ApiException) {
    return error.message;
  }
  return fallback;
}

/// 将签证套餐详情映射为详情页的档位和材料展示模型。
extension on VisaPackageVO {
  List<ServicePackageData> toServicePackages() {
    return tiers
        .map(
          (TierVO tier) => ServicePackageData(
            title: tier.name.trim().isEmpty ? '套餐档位' : tier.name,
            price: _formatPrice(tier.price, currency),
            description: tier.description.trim().isEmpty
                ? '暂无套餐说明'
                : tier.description,
            tags: tier.services.isEmpty ? <String>['暂无服务标签'] : tier.services,
          ),
        )
        .toList(growable: false);
  }

  List<ServiceMaterialData> toServiceMaterials() {
    return requiredMaterials
        .map(
          (MaterialVO material) => ServiceMaterialData(
            title: material.materialName.trim().isEmpty
                ? '所需材料'
                : material.materialName,
            subtitle: _buildMaterialSubtitle(material),
            status: _buildMaterialStatus(material),
            required: true,
          ),
        )
        .toList(growable: false);
  }
}

/// 组装材料副标题，尽量从文件元信息拼出可读文案。
String _buildMaterialSubtitle(MaterialVO material) {
  final List<String> parts = <String>[
    if (material.fileType.trim().isNotEmpty)
      material.fileType.trim().toUpperCase(),
    if (material.fileSize > 0) _formatFileSize(material.fileSize),
    if (material.uploadedAt.trim().isNotEmpty)
      _formatMaterialDate(material.uploadedAt),
  ];
  if (parts.isEmpty) {
    return '请按服务要求准备相关材料';
  }
  return parts.join(' · ');
}

/// 组装材料状态文案，优先展示文件类型。
String _buildMaterialStatus(MaterialVO material) {
  final String fileType = material.fileType.trim();
  return fileType.isEmpty ? '材料' : fileType.toUpperCase();
}

/// 格式化详情页价格，统一复用币种前缀转换规则。
String _formatPrice(double amount, String currency) {
  final String prefix = _resolveCurrencyPrefix(currency);
  final String value = amount % 1 == 0
      ? amount.toInt().toString()
      : amount.toStringAsFixed(1);
  return '$prefix$value';
}

/// 统一处理常见币种前缀，缺省回退为人民币。
String _resolveCurrencyPrefix(String rawCurrency) {
  return switch (rawCurrency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'EUR' => '€',
    'USD' => '\$',
    _ => rawCurrency.trim().isEmpty ? '¥' : '${rawCurrency.trim()} ',
  };
}

/// 将国家代码转为详情页展示文案。
String _formatCountryLabel(String country) {
  return switch (country.trim().toUpperCase()) {
    'DE' => '德国',
    'FR' => '法国',
    'IT' => '意大利',
    'ES' => '西班牙',
    'NL' => '荷兰',
    'BE' => '比利时',
    _ => country.trim().isEmpty ? '签证' : country.trim().toUpperCase(),
  };
}

/// 将签证类型代码转为详情页展示文案。
String _formatVisaTypeLabel(String visaType) {
  return switch (visaType.trim().toLowerCase()) {
    'work' => '工作签',
    'travel' => '旅游签',
    'tech' => '技术签',
    'nursing' => '护理签',
    'study' => '留学签',
    _ => visaType.trim().isEmpty ? '签证服务' : visaType.trim(),
  };
}

/// 格式化文件大小，优先展示为 KB/MB。
String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '未知大小';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  }
  return '${bytes}B';
}

/// 格式化材料时间，解析失败时回退原始值。
String _formatMaterialDate(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  final String month = parsed.month.toString().padLeft(2, '0');
  final String day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}.$month.$day';
}
