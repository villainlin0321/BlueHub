import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

/// 求职者端我的页，按 Figma 设计图还原。
class JobSeekerMePage extends StatelessWidget {
  const JobSeekerMePage({super.key});

  static const String _profileCardBgAsset =
      'assets/images/me/mou4gf12-37h742f.svg';
  static const String _menuCardBgAsset =
      'assets/images/me/mou4gf12-4znlacm.svg';
  static const String _verifiedBadgeBgAsset =
      'assets/images/me/mou4gf12-gd4t3xy.svg';
  static const String _avatarAsset = 'assets/images/me/mou4gf12-gby6i3c.png';
  static const String _chevronAsset = 'assets/images/me/mou4gf12-khnjije.png';
  static const String _messageAsset = 'assets/images/me/mou4gf12-spcrp36.svg';
  static const String _settingsAsset = 'assets/images/me/mou4gf12-hem78nx.svg';

  static const List<_MenuActionItem> _menuItems = <_MenuActionItem>[
    _MenuActionItem(
      label: '简历管理',
      iconAsset: 'assets/images/me/mou4gf13-1hzw3yt.svg',
      fallbackIcon: Icons.badge_outlined,
    ),
    _MenuActionItem(
      label: '订单进度',
      iconAsset: 'assets/images/me/mou4gf13-o2ya2qn.svg',
      fallbackIcon: Icons.assignment_outlined,
    ),
    _MenuActionItem(
      label: '我的收藏',
      iconAsset: 'assets/images/me/mou4gf13-2yasg57.svg',
      fallbackIcon: Icons.star_outline_rounded,
    ),
    _MenuActionItem(
      label: '客服中心',
      iconAsset: 'assets/images/me/mou4gf13-lra1z08.svg',
      fallbackIcon: Icons.support_agent_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              onMessageTap: () => _showPlaceholderToast(context, '消息中心'),
              onSettingsTap: () => _showPlaceholderToast(context, '设置'),
            ),
            const SizedBox(height: 11),
            _ProfileCard(
              onTap: () => _showPlaceholderToast(context, '个人资料'),
              onOrderTap: () => context.push(RoutePaths.myOrders),
              onResumeTap: () => context.push(RoutePaths.myResume),
              onApplicationTap: () => context.push(RoutePaths.myApplications),
              onFavoriteTap: () => context.push(RoutePaths.myFavorites),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              items: _menuItems,
              onItemTap: (String label) => _handleMenuTap(context, label),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String label) {
    switch (label) {
      case '简历管理':
        context.push(RoutePaths.myResume);
      case '订单进度':
        context.push(RoutePaths.myOrders);
      case '我的收藏':
        context.push(RoutePaths.myFavorites);
      case '客服中心':
        _showPlaceholderToast(context, label);
    }
  }

  void _showPlaceholderToast(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label（占位）')));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMessageTap, required this.onSettingsTap});

  final VoidCallback onMessageTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: <Widget>[
          Text(
            '我的',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xE5000000),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
          const Spacer(),
          _TopIconButton(
            assetPath: JobSeekerMePage._messageAsset,
            fallbackIcon: Icons.chat_bubble_outline,
            onTap: onMessageTap,
          ),
          const SizedBox(width: 16),
          _TopIconButton(
            assetPath: JobSeekerMePage._settingsAsset,
            fallbackIcon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 19,
            height: 19,
            placeholderBuilder: (_) =>
                Icon(fallbackIcon, size: 20, color: const Color(0xFF262626)),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.onTap,
    required this.onOrderTap,
    required this.onResumeTap,
    required this.onApplicationTap,
    required this.onFavoriteTap,
  });

  final VoidCallback onTap;
  final VoidCallback onOrderTap;
  final VoidCallback onResumeTap;
  final VoidCallback onApplicationTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19.2),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SvgPicture.asset(
              JobSeekerMePage._profileCardBgAsset,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 15, 16),
            child: Column(
              children: <Widget>[
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        JobSeekerMePage._avatarAsset,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    '程先生',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF262626),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      height: 26 / 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 42,
                                  height: 18,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        JobSeekerMePage._verifiedBadgeBgAsset,
                                        fit: BoxFit.fill,
                                      ),
                                      const Center(
                                        child: Text(
                                          '已实名',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            height: 14 / 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '132****3456',
                              style: TextStyle(
                                color: Color(0xFF595959),
                                fontSize: 13,
                                height: 16 / 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        JobSeekerMePage._chevronAsset,
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatItem(
                        value: '3',
                        label: '我的订单',
                        onTap: onOrderTap,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        value: '85%',
                        label: '我的简历',
                        onTap: onResumeTap,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        value: '3',
                        label: '我的应聘',
                        onTap: onApplicationTap,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        value: '24',
                        label: '我的收藏',
                        onTap: onFavoriteTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: <Widget>[
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF313656),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 20 / 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onItemTap});

  final List<_MenuActionItem> items;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19.2),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SvgPicture.asset(
              JobSeekerMePage._menuCardBgAsset,
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: List<Widget>.generate(items.length, (int index) {
                final _MenuActionItem item = items[index];
                return _MenuTile(
                  item: item,
                  onTap: () => onItemTap(item.label),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onTap});

  final _MenuActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: 24,
                  height: 24,
                  placeholderBuilder: (_) => Icon(
                    item.fallbackIcon,
                    size: 22,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                ),
              ),
            ),
            Image.asset(JobSeekerMePage._chevronAsset, width: 16, height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuActionItem {
  const _MenuActionItem({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
  });

  final String label;
  final String iconAsset;
  final IconData fallbackIcon;
}
