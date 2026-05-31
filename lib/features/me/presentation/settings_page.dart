import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../auth/presentation/widgets/auth_language_switch.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/localization/app_locales.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../auth/data/auth_providers.dart';
import '../../message/application/message_session/message_session_controller.dart';
import '../../shell/application/shell_role_provider.dart';

/// 设置页：承接企业端“我的”页右上角设置入口，并提供基础账号操作。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoggingOut = false;

  @override
  /// 构建设置页主体，按设计稿组织顶部导航、列表项与底部操作区。
  Widget build(BuildContext context) {
    final bool isChinese = context.isChineseLocale;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _SettingsHeader(onBackTap: context.pop),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _SettingsCard(
                        children: <Widget>[
                          _LanguageRow(
                            isChinese: isChinese,
                            onChanged: _handleLanguageChanged,
                          ),
                          _SettingsActionRow(
                            title: '设置.我的信息'.tr(),
                            onTap: _handleMyInfoTap,
                          ),
                          _SettingsActionRow(
                            title: '设置.黑名单'.tr(),
                            onTap: _handleBlacklistTap,
                          ),
                        ],
                      ),
                      Expanded(child: SizedBox()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _BottomTextButton(
                          label: '设置.退出登录'.tr(),
                          onTap: _isLoggingOut ? null : _handleLogoutTap,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BottomLinkButton(
                        label: '设置.注销'.tr(),
                        onTap: _handleDeleteTap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
            if (_isLoggingOut)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x33000000),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 切换应用全局语言，并让设置页与其他页面共享同一份 Locale 状态。
  Future<void> _handleLanguageChanged(bool isChinese) async {
    await context.switchAppLocale(isChinese);
  }

  /// 按当前角色分流“我的信息”入口，避免不同身份误入不匹配的资料页。
  void _handleMyInfoTap() {
    switch (ref.read(shellRoleProvider)) {
      case ShellRole.jobSeeker:
        context.push(RoutePaths.myInfo);
        return;
      case ShellRole.company:
        context.push(RoutePaths.companyMyInfo);
        return;
      case ShellRole.serviceProvider:
        context.push(RoutePaths.serviceProviderMyInfo);
        return;
    }
  }

  /// 黑名单暂未接入真实业务，先保留占位提示避免点击无反馈。
  void _handleBlacklistTap() {
    context.push(RoutePaths.blacklist);
  }

  /// 注销能力尚未接入接口，先提示用户当前状态。
  void _handleDeleteTap() {
    _showMessage('设置.注销未开放'.tr());
  }

  /// 确认退出登录后调用服务端注销，并清空本地会话回到登录页。
  Future<void> _handleLogoutTap() async {
    final bool confirmed = await _showLogoutConfirmDialog();
    if (!mounted || !confirmed) {
      return;
    }
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });
    bool hasStoppedMessageSession = false;
    try {
      // 关键流程：退出登录前先关闭消息 SSE，避免登出过程中继续消费推送。
      await ref.read(messageSessionControllerProvider.notifier).stopSession();
      hasStoppedMessageSession = true;
      // 关键流程：先通知服务端登出，再清理本地登录态。
      await ref.read(authServiceProvider).logout();
      await ref
          .read(authSessionProvider.notifier)
          .clearSession(reason: 'manual_logout');
      if (!mounted) {
        return;
      }
      context.go(RoutePaths.loginPhone);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (hasStoppedMessageSession) {
        await ref.read(messageSessionControllerProvider.notifier).startSession();
      }
      _showMessage(_resolveErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  /// 展示退出登录确认框，避免误触直接丢失当前会话。
  Future<bool> _showLogoutConfirmDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('设置.退出登录标题'.tr()),
          content: Text('设置.退出登录内容'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('通用.取消'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('通用.确定'.tr()),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  /// 将异常转换成适合页面提示的文案，优先展示接口返回信息。
  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '设置.退出登录失败'.tr();
  }

  /// 统一通过页面级 Snackbar 反馈点击结果或异常信息。
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  /// 构建顶部标题栏，保持与设计稿一致的返回位置和标题层级。
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 44,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 44,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: onBackTap,
        icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
      ),
      title: Text(
        '设置.标题'.tr(),
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 17,
          fontWeight: FontWeight.w500,
          height: 24 / 17,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  /// 构建设置分组卡片，统一承载卡片圆角和白底样式。
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.isChinese, required this.onChanged});

  final bool isChinese;
  final ValueChanged<bool> onChanged;

  @override
  /// 构建语言切换行，用分段按钮模拟设计稿中的中英切换效果。
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '设置.系统语言'.tr(),
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
          AuthLanguageSwitch(
            isChineseSelected: isChinese,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  /// 构建可点击的设置项，复用统一的行高、文案和箭头样式。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBFBFBF)),
          ],
        ),
      ),
    );
  }
}

class _BottomTextButton extends StatelessWidget {
  const _BottomTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  /// 构建底部主操作按钮，用于承载“退出登录”这类高频设置动作。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 16,
            height: 22 / 16,
          ),
        ),
      ),
    );
  }
}

class _BottomLinkButton extends StatelessWidget {
  const _BottomLinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  /// 构建底部文本入口，适合承载次级设置动作。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
