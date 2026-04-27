import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import 'service_detail_merchant_tab.dart';
import 'service_detail_package_tab.dart';
import 'service_detail_review_tab.dart';

class ServiceDetailPage extends StatefulWidget {
  const ServiceDetailPage({super.key});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  static const _expandedAppBarHeight = 292.0;
  static const _heroAsset = 'assets/images/service_detail_top_background.png';
  static const _backAsset = 'assets/images/service_detail_back.svg';
  static const _favoriteAsset = 'assets/images/service_detail_favorite.svg';
  static const _shareAsset = 'assets/images/service_detail_share.svg';
  static const _verifiedBadgeAsset =
      'assets/images/service_detail_verified_badge.png';
  static const _consultIconAsset =
      'assets/images/service_detail_consult_icon.svg';

  static const _packages = <ServicePackageData>[
    ServicePackageData(
      title: '基础套餐',
      price: '¥15,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['审核材料', '表格填写'],
    ),
    ServicePackageData(
      title: '标准套餐',
      price: '¥25,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['翻译服务', '面签辅导', '面签陪同'],
    ),
    ServicePackageData(
      title: '尊享套餐',
      price: '¥36,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['拒签退款', '加急处理'],
    ),
  ];

  static const _materials = <ServiceMaterialData>[
    ServiceMaterialData(
      title: '护照原件及复印件',
      subtitle: '有效期需超过预计逗留期至少3个月一行展示',
      status: '必填',
      required: true,
    ),
    ServiceMaterialData(
      title: '厨师资格证公证件',
      subtitle: '需经过双认证，带德文翻译',
      status: '必填',
      required: true,
    ),
    ServiceMaterialData(
      title: '德语语言证明 (A2)',
      subtitle: '如果有可加速获签',
      status: '选填',
      required: false,
    ),
  ];

  int _selectedPackageIndex = 0;
  bool _isFavorited = false;
  bool _showCollapsedTitle = false;

  @override
  Widget build(BuildContext context) {
    final collapseThreshold =
        _expandedAppBarHeight -
        (kToolbarHeight + MediaQuery.paddingOf(context).top) -
        12;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _BottomActionBar(
          consultIconAsset: _consultIconAsset,
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) {
              return false;
            }
            final shouldShowTitle =
                notification.metrics.pixels >= collapseThreshold;
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF262626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final topPadding = MediaQuery.paddingOf(context).top;
                      final collapsed = _isCollapsed(
                        constraints.biggest.height,
                        topPadding,
                      );
                      final progress = _collapseProgress(
                        constraints.biggest.height,
                        topPadding,
                      );

                      return _SliverHeroAppBar(
                        assetPath: _heroAsset,
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
                    package: _packages[_selectedPackageIndex],
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
                  packages: _packages,
                  selectedPackageIndex: _selectedPackageIndex,
                  onPackageSelected: (index) {
                    setState(() => _selectedPackageIndex = index);
                  },
                  materials: _materials,
                ),
                const ServiceDetailReviewTab(),
                const ServiceDetailMerchantTab(
                  verifiedBadgeAsset: _verifiedBadgeAsset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isCollapsed(double currentHeight, double topPadding) {
    final minExtent = kToolbarHeight + topPadding;
    return currentHeight <= minExtent + 12;
  }

  double _collapseProgress(double currentHeight, double topPadding) {
    final minExtent = kToolbarHeight + topPadding;
    final delta = (_expandedAppBarHeight - minExtent).clamp(1, double.infinity);
    return ((_expandedAppBarHeight - currentHeight) / delta).clamp(0.0, 1.0);
  }
}

class _SliverHeroAppBar extends StatelessWidget {
  const _SliverHeroAppBar({
    required this.assetPath,
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

  final String assetPath;
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
    final iconColor = Color.lerp(
      Colors.white,
      const Color(0xFF262626),
      progress,
    )!;
    final buttonBackground = Color.lerp(
      Colors.black.withValues(alpha: 0.28),
      AppColors.surface.withValues(alpha: 0.92),
      progress,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(assetPath, fit: BoxFit.cover),
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.package,
    required this.verifiedBadgeAsset,
  });

  final ServicePackageData package;
  final String verifiedBadgeAsset;

  @override
  Widget build(BuildContext context) {
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
                  '德国厨师专属工作签证',
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
                      text: package.price,
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
              Image.asset(
                verifiedBadgeAsset,
                width: 55.67,
                height: 16,
                fit: BoxFit.contain,
              ),
              const _SummaryTag(label: '德国'),
              const _SummaryTag(label: '工作签'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及。',
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
    final controller = DefaultTabController.of(context);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 0),
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
            count: '234',
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
    this.count,
    this.selectedWeight = FontWeight.w500,
    this.horizontalPadding = EdgeInsets.zero,
  });

  final String label;
  final String? count;
  final FontWeight selectedWeight;
  final EdgeInsets horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final tabIndex = <String>['套餐', '评价', '商家'].indexOf(label);
        final selected = controller.index == tabIndex;
        final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF262626),
          fontSize: 16,
          height: 1.2,
          fontWeight: selected ? selectedWeight : FontWeight.w400,
        );

        return Tab(
          height: 48,
          child: Padding(
            padding: horizontalPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: labelStyle),
                if (count != null) ...<Widget>[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      count!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF8C8C8C),
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final size = configuration.size;
    if (size == null) {
      return;
    }
    final paint = borderSide.toPaint();
    final y = offset.dy + size.height - borderSide.width - bottomOffset;
    final x = offset.dx + (size.width - width) / 2;
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
  const _BottomActionBar({required this.consultIconAsset});

  final String consultIconAsset;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
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
            return _PackageBottomActionBar(consultIconAsset: consultIconAsset);
        }
      },
    );
  }
}

class _PackageBottomActionBar extends StatelessWidget {
  const _PackageBottomActionBar({required this.consultIconAsset});

  final String consultIconAsset;

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
                onPressed: () {},
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
    final secondaryStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFF171A1D),
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 22 / 16,
    );
    final primaryStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
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
