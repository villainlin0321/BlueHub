import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';

/// 主框架页：承载底部 5 个 Tab（go_router 的 StatefulShellRoute）。
class MainShellPage extends StatelessWidget {
  const MainShellPage({
    super.key,
    required this.title,
    required this.navigationShell,
  });

  final String title;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // 关键点：切换分支时不要重置当前分支栈，符合“Tab 保活”的产品体验。
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_BottomItem>[
    _BottomItem(
      label: '首页',
      activeAsset: '.figma/image/moe2f6t1-ssqasqs.svg',
      inactiveAsset: '.figma/image/moe2fcad-bumifo2.svg',
      fallback: Icons.home_rounded,
    ),
    _BottomItem(
      label: '签证',
      activeAsset: '.figma/image/moe2f6t1-qs1abxr.svg',
      inactiveAsset: '.figma/image/moe2fcad-sqx5z6f.svg',
      fallback: Icons.assignment_rounded,
    ),
    _BottomItem(
      label: '招聘',
      activeAsset: '.figma/image/moe2f6t1-ssqasqs.svg',
      inactiveAsset: '.figma/image/moe2fcad-v86762a.svg',
      fallback: Icons.work_rounded,
    ),
    _BottomItem(
      label: 'AI助手',
      activeAsset: '.figma/image/moe2f6t1-p1ml2b6.svg',
      inactiveAsset: '.figma/image/moe2fcad-v86762a.svg',
      fallback: Icons.smart_toy_rounded,
    ),
    _BottomItem(
      label: '我的',
      activeAsset: '.figma/image/moe2f6t1-nd3ved1.svg',
      inactiveAsset: '.figma/image/moe2fcad-z53wpdi.svg',
      fallback: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: List<Widget>.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = index == currentIndex;
            final color = isActive ? AppColors.brand : AppColors.textTertiary;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppSvgIcon(
                        assetPath: isActive ? item.activeAsset : item.inactiveAsset,
                        fallback: item.fallback,
                        size: 22,
                        color: color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
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
