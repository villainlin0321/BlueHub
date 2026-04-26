import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/app_svg_icon.dart';

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

  static const _topTabs = <String>['套餐', '评价 234', '商家'];

  static const _packages = <_PackageData>[
    _PackageData(
      title: '基础套餐',
      price: '¥15,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['审核材料', '表格填写'],
    ),
    _PackageData(
      title: '标准套餐',
      price: '¥25,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['翻译服务', '面签辅导', '面签陪同'],
    ),
    _PackageData(
      title: '尊享套餐',
      price: '¥36,000',
      description:
          '套餐描述文字内容，套餐描述文字内容套餐描述文字内容套餐描述文字内容套，餐描述文字内容餐描述文字内容餐描述文字内容餐描述文字内容',
      tags: <String>['拒签退款', '加急处理'],
    ),
  ];

  static const _materials = <_MaterialData>[
    _MaterialData(
      title: '护照原件及复印件',
      subtitle: '有效期需超过预计逗留期至少3个月一行展示',
      status: '必填',
      required: true,
    ),
    _MaterialData(
      title: '厨师资格证公证件',
      subtitle: '需经过双认证，带德文翻译',
      status: '必填',
      required: true,
    ),
    _MaterialData(
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

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const _BottomActionBar(
        consultIconAsset: _consultIconAsset,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final shouldShowTitle =
              notification.metrics.pixels >= collapseThreshold;
          if (shouldShowTitle != _showCollapsedTitle) {
            setState(() => _showCollapsedTitle = shouldShowTitle);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: _expandedAppBarHeight,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 70,
              // centerTitle: false,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showCollapsedTitle ? 1 : 0,
                child: SizedBox(
                  height: 46,
                  // alignment: Alignment.topLeft,
                  child: Text(
                    '服务详情',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF262626),
                      fontWeight: FontWeight.w700,
                    ),
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
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('分享功能开发中')));
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
              delegate: _PinnedTopTabBarDelegate(
                child: _TopTabBar(tabs: _topTabs),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: List<Widget>.generate(_packages.length, (index) {
                    final data = _packages[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _packages.length - 1 ? 0 : 12,
                      ),
                      child: _PackageOptionCard(
                        data: data,
                        selected: index == _selectedPackageIndex,
                        onTap: () =>
                            setState(() => _selectedPackageIndex = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _MaterialsSection(materials: _materials),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
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
    final progress = ((_expandedAppBarHeight - currentHeight) / delta).clamp(
      0.0,
      1.0,
    );
    return progress;
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
            decoration: BoxDecoration(
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

  final _PackageData package;
  final String verifiedBadgeAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: BoxDecoration(color: AppColors.surface),
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

class _TopTabBar extends StatelessWidget {
  const _TopTabBar({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 16,
              top: 12,
              child: Text(
                tabs[0],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 40,
              child: Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF096DD9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: 84,
              top: 12,
              child: Text(
                '评价',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            Positioned(
              left: 118,
              top: 15,
              child: Text(
                '234',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8C8C8C),
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ),
            Positioned(
              left: 152,
              top: 12,
              child: Text(
                tabs[2],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
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

class _PackageOptionCard extends StatelessWidget {
  const _PackageOptionCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _PackageData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F8FF) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF096DD9)
                  : const Color(0xFFD9D9D9),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? const Color(0xFF096DD9)
                        : const Color(0xFFB8C2D8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF262626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    data.price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFE5815),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.tags
                    .map((tag) => _PackageTag(label: tag))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF595959),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8C8C8C),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialsSection extends StatelessWidget {
  const _MaterialsSection({required this.materials});

  final List<_MaterialData> materials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  '所需材料',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF096DD9),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('查看样例'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(materials.length, (index) {
            final material = materials[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == materials.length - 1 ? 0 : 12,
              ),
              child: _MaterialCard(material: material),
            );
          }),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});

  final _MaterialData material;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF8FA0C9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  material.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  material.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8C8C8C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _MaterialStatusTag(
                label: material.status,
                required: material.required,
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8C8C8C),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.consultIconAsset});

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

class _PackageTag extends StatelessWidget {
  const _PackageTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF546D96),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MaterialStatusTag extends StatelessWidget {
  const _MaterialStatusTag({required this.label, required this.required});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final color = required ? const Color(0xFFFF0B03) : const Color(0xFF546D96);
    final borderColor = required
        ? const Color(0xFFFF6661)
        : const Color(0xFFA3AFD4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackageData {
  const _PackageData({
    required this.title,
    required this.price,
    required this.description,
    required this.tags,
  });

  final String title;
  final String price;
  final String description;
  final List<String> tags;
}

class _MaterialData {
  const _MaterialData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.required,
  });

  final String title;
  final String subtitle;
  final String status;
  final bool required;
}
