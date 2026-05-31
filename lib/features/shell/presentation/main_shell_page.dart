import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_session_provider.dart';
import '../../message/application/message_session/message_session_controller.dart';
import '../../../shared/logging/app_logger.dart';
import '../../../shared/ui/app_colors.dart';
import '../application/shell_role_provider.dart';

/// 主框架页：承载底部 5 个 Tab（go_router 的 StatefulShellRoute）。
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell, this.role});

  final StatefulNavigationShell navigationShell;
  final ShellRole? role;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref.read(messageSessionControllerProvider.notifier).startSession(),
      );
    });
  }

  @override
  void dispose() {
    unawaited(
      ref.read(messageSessionControllerProvider.notifier).stopSession(),
    );
    super.dispose();
  }

  @override
  /// 构建主壳层，并在 Tab 切换时记录当前角色和目标索引。
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        unawaited(
          ref
              .read(messageSessionControllerProvider.notifier)
              .stopSession(clearState: true),
        );
      }
    });
    final ShellRole currentRole = widget.role ?? ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: _BottomBar(
        key: ValueKey(currentRole),
        role: currentRole,
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          AppLogger.instance.info(
            'SHELL',
            '底部 Tab 切换',
            context: <String, Object?>{
              'role': currentRole.name,
              'fromIndex': widget.navigationShell.currentIndex,
              'toIndex': index,
            },
          );
          // 切换分支时保留各 Tab 的导航栈，符合 Figma 对应业务场景的保活体验。
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
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

  static const Color _inactiveTextColor = Color(0xFF5B708E);

  static const Map<ShellRole, List<_BottomItem>> _itemsByRole =
      <ShellRole, List<_BottomItem>>{
        ShellRole.jobSeeker: <_BottomItem>[
          _BottomItem(
            labelKey: '导航.首页',
            activeAsset: 'assets/images/icon_home.svg',
            inactiveAsset: 'assets/images/icon_home_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.签证',
            activeAsset: 'assets/images/icon_home_visa.svg',
            inactiveAsset: 'assets/images/icon_home_visa_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.招聘',
            activeAsset: 'assets/images/icon_home_job.svg',
            inactiveAsset: 'assets/images/icon_home_job_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.AI助手',
            activeAsset: 'assets/images/icon_home_ai_active.svg',
            inactiveAsset: 'assets/images/icon_home_ai.svg',
          ),
          _BottomItem(
            labelKey: '导航.我的',
            activeAsset: 'assets/images/icon_home_me.svg',
            inactiveAsset: 'assets/images/icon_home_me_inactive.svg',
          ),
        ],
        ShellRole.serviceProvider: <_BottomItem>[
          _BottomItem(
            labelKey: '导航.首页',
            activeAsset: 'assets/images/icon_home.svg',
            inactiveAsset: 'assets/images/icon_home_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.订单',
            activeAsset: 'assets/images/icon_home_order.svg',
            inactiveAsset: 'assets/images/icon_home_order_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.套餐',
            activeAsset: 'assets/images/icon_home_package.svg',
            inactiveAsset: 'assets/images/icon_home_package_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.AI助手',
            activeAsset: 'assets/images/icon_home_ai_active.svg',
            inactiveAsset: 'assets/images/icon_home_ai.svg',
          ),
          _BottomItem(
            labelKey: '导航.我的',
            activeAsset: 'assets/images/icon_home_me.svg',
            inactiveAsset: 'assets/images/icon_home_me_inactive.svg',
          ),
        ],
        ShellRole.company: <_BottomItem>[
          _BottomItem(
            labelKey: '导航.首页',
            activeAsset: 'assets/images/icon_home.svg',
            inactiveAsset: 'assets/images/icon_home_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.岗位',
            activeAsset: 'assets/images/icon_home_job.svg',
            inactiveAsset: 'assets/images/icon_home_job_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.人才',
            activeAsset: 'assets/images/icon_home_talent.svg',
            inactiveAsset: 'assets/images/icon_home_talent_inactive.svg',
          ),
          _BottomItem(
            labelKey: '导航.AI助手',
            activeAsset: 'assets/images/icon_home_ai_active.svg',
            inactiveAsset: 'assets/images/icon_home_ai.svg',
          ),
          _BottomItem(
            labelKey: '导航.我的',
            activeAsset: 'assets/images/icon_home_me.svg',
            inactiveAsset: 'assets/images/icon_home_me_inactive.svg',
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
            final textColor = isActive ? AppColors.brand : _inactiveTextColor;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        isActive ? item.activeAsset : item.inactiveAsset,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.labelKey.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ).copyWith(color: textColor),
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
    required this.labelKey,
    required this.activeAsset,
    required this.inactiveAsset,
  });

  final String labelKey;
  final String activeAsset;
  final String inactiveAsset;
}
