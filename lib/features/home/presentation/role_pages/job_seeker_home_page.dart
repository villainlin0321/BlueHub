import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';

/// 求职者首页：独立页面文件，后续该角色的业务逻辑统一放在这里处理。
class JobSeekerHomePage extends ConsumerWidget {
  const JobSeekerHomePage({super.key});

  static const List<_ShortcutItem> _shortcutItems = <_ShortcutItem>[
    _ShortcutItem(
      label: 'AI招聘',
      assetPath: 'assets/images/mon5bjog-oey0vv1.svg',
      colors: <Color>[Color(0xFF52A9FF), Color(0xFF0887FF)],
      fallback: Icons.auto_awesome_rounded,
      destination: _ShortcutDestination.aiAssistant,
    ),
    _ShortcutItem(
      label: '欧洲招聘',
      assetPath: 'assets/images/mon5bjog-wp0nhm8.svg',
      colors: <Color>[Color(0xFFFF943C), Color(0xFFFF5900)],
      fallback: Icons.work_outline_rounded,
      destination: _ShortcutDestination.jobs,
    ),
    _ShortcutItem(
      label: '签证服务',
      assetPath: 'assets/images/mon5bjog-8hp521f.svg',
      colors: <Color>[Color(0xFF01D99B), Color(0xFF00B879)],
      fallback: Icons.assignment_outlined,
      destination: _ShortcutDestination.visa,
    ),
    _ShortcutItem(
      label: '我的简历',
      assetPath: 'assets/images/mon5bjog-wivq7ef.svg',
      colors: <Color>[Color(0xFF52A9FF), Color(0xFF0887FF)],
      fallback: Icons.badge_outlined,
      destination: _ShortcutDestination.resumeList,
    ),
  ];

  static const List<_VisaMiniCardData> _visaCards = <_VisaMiniCardData>[
    _VisaMiniCardData(
      title: '厨师专属签证',
      subtitle: '包含材料审核、翻译、面签辅导',
      price: '¥15,000',
      rating: '4.8',
      casesText: '200+案例',
      country: '德国',
      ribbonAssetPath: 'assets/images/mon5bjog-lmu6456.svg',
      actionAssetPath: 'assets/images/mon5bjog-9ler7sj.png',
    ),
    _VisaMiniCardData(
      title: '电工专属签证',
      subtitle: '包含材料审核、翻译、面签辅导',
      price: '¥15,000',
      rating: '4.8',
      casesText: '200+案例',
      country: '德国',
      ribbonAssetPath: 'assets/images/mon5bjog-xpp1qgm.svg',
      actionAssetPath: 'assets/images/mon5bjog-9ler7sj.png',
    ),
  ];

  static const List<JobPositionCardData> _jobCards = <JobPositionCardData>[
    JobPositionCardData(
      title: '中餐厨师 (包食宿)',
      salary: '€2,000/月',
      requirementTags: <String>[],
      highlightTags: <String>['德国柏林', '提供签证支持'],
      company: '柏林老四川餐厅',
      location: '',
      companyAvatarAssetPath: 'assets/images/mon5bjog-zwr9bsu.png',
      showApplyButton: true,
    ),
    JobPositionCardData(
      title: '中餐厨师 (包食宿)',
      salary: '€2,000/月',
      requirementTags: <String>[],
      highlightTags: <String>['德国柏林', '提供签证支持'],
      company: '柏林老四川餐厅',
      location: '',
      companyAvatarAssetPath: 'assets/images/mon5bjog-zwr9bsu.png',
      showApplyButton: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 20),
      children: <Widget>[
        _HomeTopHeader(
          onShortcutTap: (_ShortcutItem item) => _handleShortcutTap(context, item),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/mon5bjog-qq5tufd.png',
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionHeader(title: '热门签证套餐'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _visaCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              return _VisaMiniCard(data: _visaCards[index]);
            },
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionHeader(title: '最新欧洲岗位'),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List<Widget>.generate(_jobCards.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _jobCards.length - 1 ? 0 : 12,
                ),
                child: JobPositionCard(data: _jobCards[index], onApply: () {}),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 处理顶部快捷入口点击，根据入口类型跳转到对应页面或 Tab。
  void _handleShortcutTap(BuildContext context, _ShortcutItem item) {
    switch (item.destination) {
      case _ShortcutDestination.aiAssistant:
        // 跳转到底部 Tab 的 AI 助手页。
        context.go(RoutePaths.ai);
      case _ShortcutDestination.jobs:
        // 跳转到底部 Tab 的招聘页。
        context.go(RoutePaths.jobs);
      case _ShortcutDestination.visa:
        // 跳转到底部 Tab 的签证页。
        context.go(RoutePaths.visa);
      case _ShortcutDestination.resumeList:
        // 简历入口进入独立的简历列表页。
        context.push(RoutePaths.myResume);
    }
  }
}

class _HomeTopHeader extends StatelessWidget {
  const _HomeTopHeader({required this.onShortcutTap});

  final ValueChanged<_ShortcutItem> onShortcutTap;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return JobSeekerPageBackground(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topPadding + 6, 15, 12),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
              const _HeaderProfileRow(),
              const SizedBox(height: 12),
              const _HomeSearchBar(),
              const SizedBox(height: 20),
              _ShortcutRow(
                items: JobSeekerHomePage._shortcutItems,
                onItemTap: onShortcutTap,
              ),
            ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items, required this.onItemTap});

  final List<_ShortcutItem> items;
  final ValueChanged<_ShortcutItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => _ShortcutButton(item: item, onTap: () => onItemTap(item)))
          .toList(growable: false),
    );
  }
}

class _HeaderProfileRow extends StatelessWidget {
  const _HeaderProfileRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/mon5bjog-wv3qvoa.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '早上好，程先生',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const AppSvgIcon(
                    assetPath: 'assets/images/mon5bjog-7bcl82r.svg',
                    fallback: Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF595959),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '德国',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF595959),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _MessageButton(),
      ],
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppSvgIcon(
                assetPath: 'assets/images/mon5bjog-vgesd2k.svg',
                fallback: Icons.chat_bubble_outline_rounded,
                size: 24,
                color: Color(0xFF171A1D),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF24C3D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

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
          const AppSvgIcon(
            assetPath: 'assets/images/mon5bjog-j2j6s3e.svg',
            fallback: Icons.search_rounded,
            size: 16,
            color: Color(0xFFBFBFBF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '搜索签证服务/欧洲岗位',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFBFBFBF),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({required this.item, required this.onTap});

  final _ShortcutItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: item.colors,
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: item.assetPath,
                    fallback: item.fallback,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF171A1D),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ShortcutDestination { aiAssistant, jobs, visa, resumeList }

class _ShortcutItem {
  const _ShortcutItem({
    required this.label,
    required this.assetPath,
    required this.colors,
    required this.fallback,
    required this.destination,
  });

  final String label;
  final String assetPath;
  final List<Color> colors;
  final IconData fallback;
  final _ShortcutDestination destination;
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '更多',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8C8C8C),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Image.asset('assets/images/mon5bjog-34xqksz.png', width: 16, height: 16),
      ],
    );
  }
}

class _VisaMiniCardData {
  const _VisaMiniCardData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.casesText,
    required this.country,
    required this.ribbonAssetPath,
    required this.actionAssetPath,
  });

  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final String casesText;
  final String country;
  final String ribbonAssetPath;
  final String actionAssetPath;
}

class _VisaMiniCard extends StatelessWidget {
  const _VisaMiniCard({required this.data});

  final _VisaMiniCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFFE5815),
                          fontWeight: FontWeight.w500,
                        ),
                        children: <InlineSpan>[
                          const TextSpan(
                            text: '¥',
                            style: TextStyle(fontSize: 14, height: 24 / 14),
                          ),
                          TextSpan(
                            text: data.price.replaceFirst('¥', ''),
                            style: const TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8C8C8C),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFE5815),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.rating,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFE5815),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.casesText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8C8C8C),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Image.asset(data.actionAssetPath, width: 20, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: 63,
              height: 32,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  SvgPicture.asset(data.ribbonAssetPath, fit: BoxFit.cover),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        data.country,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
