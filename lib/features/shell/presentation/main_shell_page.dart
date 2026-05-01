import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../application/shell_role_provider.dart';

/// 主框架页：承载底部 5 个 Tab（go_router 的 StatefulShellRoute）。
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key, required this.navigationShell, this.role});

  final StatefulNavigationShell navigationShell;
  final ShellRole? role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellRole currentRole = role ?? ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        key: ValueKey(currentRole),
        role: currentRole,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // 切换分支时保留各 Tab 的导航栈，符合 Figma 对应业务场景的保活体验。
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTap,
  });

  final ShellRole role;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Color _inactiveColor = Color(0xFF5B708E);
  static const String _homeInactiveAsset = '.figma/image/moe2fcad-bumifo2.svg';

  static const Map<ShellRole, List<_BottomItem>> _itemsByRole =
      <ShellRole, List<_BottomItem>>{
        ShellRole.jobSeeker: <_BottomItem>[
          _BottomItem(
            label: '首页',
            activeAsset: '.figma/image/mon1zl1k-xdjbb8t.svg',
            inactiveAsset: _homeInactiveAsset,
            fallback: Icons.home_rounded,
          ),
          _BottomItem(
            label: '签证',
            activeAsset: '.figma/image/mon1zl1k-8vikm4z.svg',
            inactiveAsset: '.figma/image/mon1zl1k-8vikm4z.svg',
            fallback: Icons.assignment_rounded,
          ),
          _BottomItem(
            label: '招聘',
            activeAsset: '.figma/image/mon1zl1k-loy1tez.svg',
            inactiveAsset: '.figma/image/mon1zl1k-loy1tez.svg',
            fallback: Icons.work_rounded,
          ),
          _BottomItem(
            label: 'AI助手',
            activeAsset: '.figma/image/mon1zl1k-3r846kq.svg',
            inactiveAsset: '.figma/image/mon1zl1k-3r846kq.svg',
            fallback: Icons.smart_toy_rounded,
          ),
          _BottomItem(
            label: '我的',
            activeAsset: '.figma/image/mon1zl1k-xuo8q82.svg',
            inactiveAsset: '.figma/image/mon1zl1k-xuo8q82.svg',
            fallback: Icons.person_rounded,
          ),
        ],
        ShellRole.serviceProvider: <_BottomItem>[
          _BottomItem(
            label: '首页',
            activeAsset: '.figma/image/mon1zpec-y8912h0.svg',
            inactiveAsset: _homeInactiveAsset,
            fallback: Icons.home_rounded,
          ),
          _BottomItem(
            label: '订单',
            activeAsset: '.figma/image/mon1zpec-q3kkmca.svg',
            inactiveAsset: '.figma/image/mon1zpec-q3kkmca.svg',
            fallback: Icons.receipt_long_rounded,
          ),
          _BottomItem(
            label: '套餐',
            activeAsset: '.figma/image/mon1zpec-8rwalq7.svg',
            inactiveAsset: '.figma/image/mon1zpec-8rwalq7.svg',
            fallback: Icons.shopping_bag_rounded,
          ),
          _BottomItem(
            label: 'AI助手',
            activeAsset: '.figma/image/mon1zpec-3ck1bes.svg',
            inactiveAsset: '.figma/image/mon1zpec-3ck1bes.svg',
            fallback: Icons.smart_toy_rounded,
          ),
          _BottomItem(
            label: '我的',
            activeAsset: '.figma/image/mon1zpeb-ntefo96.svg',
            inactiveAsset: '.figma/image/mon1zpeb-ntefo96.svg',
            fallback: Icons.person_rounded,
          ),
        ],
        ShellRole.company: <_BottomItem>[
          _BottomItem(
            label: '首页',
            activeAsset: '.figma/image/mon1zsur-pq619ml.svg',
            inactiveAsset: _homeInactiveAsset,
            fallback: Icons.home_rounded,
          ),
          _BottomItem(
            label: '岗位',
            activeAsset: '.figma/image/mon1zsur-xb20l62.svg',
            inactiveAsset: '.figma/image/mon1zsur-xb20l62.svg',
            fallback: Icons.work_outline_rounded,
          ),
          _BottomItem(
            label: '人才',
            activeAsset: '.figma/image/mon1zsur-q8s6lmr.svg',
            inactiveAsset: '.figma/image/mon1zsur-q8s6lmr.svg',
            fallback: Icons.school_rounded,
          ),
          _BottomItem(
            label: 'AI助手',
            activeAsset: '.figma/image/mon1zsur-0uz78we.svg',
            inactiveAsset: '.figma/image/mon1zsur-0uz78we.svg',
            fallback: Icons.smart_toy_rounded,
          ),
          _BottomItem(
            label: '我的',
            activeAsset: '.figma/image/mon1zsur-0oz9j5d.svg',
            inactiveAsset: '.figma/image/mon1zsur-0oz9j5d.svg',
            fallback: Icons.person_rounded,
          ),
        ],
      };

  @override
  Widget build(BuildContext context) {
    final items = _itemsByRole[role]!;
    final bottomPadding = math.max(34.0, MediaQuery.paddingOf(context).bottom);

    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.only(top: 7, bottom: bottomPadding),
        child: Row(
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            final color = isActive ? AppColors.brand : _inactiveColor;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppSvgIcon(
                        assetPath: isActive
                            ? item.activeAsset
                            : item.inactiveAsset,
                        fallback: item.fallback,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ).copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomItem {
  const _BottomItem({
    required this.label,
    required this.activeAsset,
    required this.inactiveAsset,
    required this.fallback,
  });

  final String label;
  final String activeAsset;
  final String inactiveAsset;
  final IconData fallback;
}
