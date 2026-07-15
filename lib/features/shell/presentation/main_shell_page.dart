import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_session_provider.dart';
import '../../config/data/config_providers.dart';
import '../../message/application/message_session/message_session_controller.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/logging/app_logger.dart';
import '../../../shared/ui/app_colors.dart';
import '../application/shell_role_provider.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 主框架页：承载底部 5 个 Tab（go_router 的 StatefulShellRoute）。
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell, this.role});

  final StatefulNavigationShell navigationShell;
  final ShellRole? role;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  bool _isExitDialogShowing = false;

  void _refreshTagDictionaryForIndex(int index) {
    if (index != 0) {
      return;
    }
    unawaited(ref.read(tagDictionaryCacheControllerProvider).refreshAll());
  }

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
      _refreshTagDictionaryForIndex(widget.navigationShell.currentIndex);
    });
  }

  @override
  void dispose() {
    unawaited(
      ref.read(messageSessionControllerProvider.notifier).stopSession(),
    );
    super.dispose();
  }

  Future<void> _handleExitApp() async {
    if (_isExitDialogShowing) {
      return;
    }

    _isExitDialogShowing = true;
    final bool shouldExit = await showAppConfirmDialog(
      context: context,
      title: '通用.退出应用标题'.tr(),
      message: '通用.退出应用内容'.tr(),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '通用.确定'.tr(),
      barrierDismissible: false,
    );
    _isExitDialogShowing = false;

    if (!mounted || !shouldExit) {
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  /// 构建主壳层，并在 Tab 切换时记录当前角色和目标索引。
  Widget build(BuildContext context) {
    final Locale locale = context.locale;
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

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (didPop) {
          return;
        }
        unawaited(_handleExitApp());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.navigationShell,
        bottomNavigationBar: _BottomBar(
          key: ValueKey<String>(
            '${currentRole.name}_${locale.languageCode}_${locale.countryCode ?? ''}',
          ),
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
            if (index == 0 && index != widget.navigationShell.currentIndex) {
              _refreshTagDictionaryForIndex(index);
            }
            // 切换分支时保留各 Tab 的导航栈，符合 Figma 对应业务场景的保活体验。
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
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
                        style: TestStyle.medium(
                          fontSize: 10,
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
