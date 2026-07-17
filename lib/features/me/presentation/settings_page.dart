import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_toast.dart';
import '../../../shared/logging/app_logger.dart';
import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/localization/app_locales.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../auth/data/auth_providers.dart';
import '../data/user_providers.dart';
import '../../shell/application/shell_role_provider.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 设置页：承接企业端“我的”页右上角设置入口，并提供基础账号操作。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSubmittingAccountAction = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  /// 构建设置页主体，按设计稿组织顶部导航、列表项与底部操作区。
  Widget build(BuildContext context) {
    final bool isChinese = context.isChineseLocale;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // 顶部区域独立使用白底，保证状态栏和导航栏与设计稿一致。
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: _SettingsHeader(onBackTap: context.pop),
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F7FA),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                              _SettingsActionRow(
                                title: '设置.关于我们'.tr(),
                                onTap: _handleAboutTap,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _BottomTextButton(
                            label: '日志分享',
                            onTap: _handleShareLogTap,
                          ),
                          const Spacer(),
                          // 通过额外 4pt 内边距，把底部主按钮控制在设计稿的 16pt 左右边距。
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _BottomTextButton(
                              label: '设置.退出登录'.tr(),
                              onTap: _isSubmittingAccountAction
                                  ? null
                                  : _handleLogoutTap,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BottomLinkButton(
                            label: '设置.注销'.tr(),
                            onTap: _isSubmittingAccountAction
                                ? null
                                : _handleDeleteTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isSubmittingAccountAction)
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

  /// 打开黑名单页，复用“我的”模块已注册的真实路由入口。
  void _handleBlacklistTap() {
    context.push(RoutePaths.blacklist);
  }

  /// 打开关于我们页，便于用户查看应用版本和公司主体信息。
  void _handleAboutTap() {
    context.push(RoutePaths.aboutApp);
  }

  /// 分享当前运行会话日志文件，便于用户快速导出问题现场给研发排查。
  Future<void> _handleShareLogTap() async {
    final String? logFilePath = AppLogger.instance.currentLogFilePath;
    if (logFilePath == null || logFilePath.trim().isEmpty) {
      _showMessage('当前暂无可分享日志');
      return;
    }

    final File logFile = File(logFilePath);
    if (!await logFile.exists()) {
      if (!mounted) {
        return;
      }
      _showMessage('日志文件不存在');
      return;
    }
    if (!mounted) {
      return;
    }

    final String fileName = logFile.uri.pathSegments.isNotEmpty
        ? logFile.uri.pathSegments.last
        : 'bluehub.log';
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: fileName,
          subject: fileName,
          files: <XFile>[XFile(logFile.path, name: fileName)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '日志分享失败'));
    }
  }

  /// 确认注销账号后调用软删除接口，并清空本地会话返回登录页。
  Future<void> _handleDeleteTap() async {
    final bool confirmed = await _showDeleteConfirmDialog();
    if (!mounted || !confirmed) {
      return;
    }
    if (_isSubmittingAccountAction) {
      return;
    }

    setState(() {
      _isSubmittingAccountAction = true;
    });
    try {
      await ref
          .read(userServiceProvider)
          .deleteAccount(reason: 'user_requested');
      await ref
          .read(authSessionProvider.notifier)
          .clearSession(reason: 'manual_delete_account');
      if (!mounted) {
        return;
      }
      context.go(RoutePaths.loginPhone);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '设置.注销失败'.tr()));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAccountAction = false;
        });
      }
    }
  }

  /// 确认退出登录后调用服务端注销，并清空本地会话回到登录页。
  Future<void> _handleLogoutTap() async {
    final bool confirmed = await _showLogoutConfirmDialog();
    if (!mounted || !confirmed) {
      return;
    }
    if (_isSubmittingAccountAction) {
      return;
    }

    setState(() {
      _isSubmittingAccountAction = true;
    });
    try {
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
      _showMessage(_resolveErrorMessage(error, fallback: '设置.退出登录失败'.tr()));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAccountAction = false;
        });
      }
    }
  }

  /// 展示退出登录确认框，避免误触直接丢失当前会话。
  Future<bool> _showLogoutConfirmDialog() async {
    return showAppConfirmDialog(
      context: context,
      title: '设置.退出登录标题'.tr(),
      message: '设置.退出登录内容'.tr(),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '通用.确定'.tr(),
    );
  }

  /// 展示注销账号确认框，避免误删导致当前账号不可继续使用。
  Future<bool> _showDeleteConfirmDialog() async {
    return showAppConfirmDialog(
      context: context,
      title: '设置.注销标题'.tr(),
      message: '设置.注销内容'.tr(),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '通用.确定'.tr(),
    );
  }

  /// 将异常转换成适合页面提示的文案，优先展示接口返回信息。
  String _resolveErrorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }
    return fallback;
  }

  /// 统一通过全局 Toast 反馈点击结果或异常信息。
  void _showMessage(String message) {
    AppToast.show(message);
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  /// 构建顶部标题栏，保持与设计稿一致的返回位置和标题层级。
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Center(
            child: Text(
              '设置.标题'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 17,
                color: const Color(0xFF262626),
              ),
            ),
          ),
          Positioned(
            left: 0,
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onBackTap,
                padding: EdgeInsets.zero,
                splashRadius: 20,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ),
        ],
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
              style: TestStyle.pingFangRegular(
                fontSize: 16,
                color: const Color(0xFF262626),
              ),
            ),
          ),
          _SettingsLanguageSwitch(
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: TestStyle.pingFangRegular(
                  fontSize: 16,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFFBFBFBF),
            ),
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
    final double opacity = onTap == null ? 0.5 : 1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TestStyle.pingFangRegular(
              fontSize: 17,
              color: const Color(0xFF262626),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomLinkButton extends StatelessWidget {
  const _BottomLinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  /// 构建底部文本入口，适合承载次级设置动作。
  Widget build(BuildContext context) {
    final double opacity = onTap == null ? 0.5 : 1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: TestStyle.pingFangRegular(
                fontSize: 16,
                color: const Color(0xFF595959),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsLanguageSwitch extends StatelessWidget {
  const _SettingsLanguageSwitch({
    required this.isChineseSelected,
    required this.onChanged,
  });

  final bool isChineseSelected;
  final ValueChanged<bool> onChanged;

  @override
  /// 构建设置页专用语言切换器，避免修改全局共享组件影响其他页面。
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SettingsLanguageOption(
              label: '语言.中文简称'.tr(),
              selected: isChineseSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SettingsLanguageOption(
              label: '语言.英文简称'.tr(),
              selected: !isChineseSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLanguageOption extends StatelessWidget {
  const _SettingsLanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  /// 构建切换器内部选项，通过蓝底白字突出当前语言。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1890FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TestStyle.pingFangSemibold(
            fontSize: 12,
            color: selected ? Colors.white : const Color(0xFF262626),
          ),
        ),
      ),
    );
  }
}
