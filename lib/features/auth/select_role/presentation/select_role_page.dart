import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/localization/app_locales.dart';
import '../../application/auth_session_provider.dart';
import '../../application/auth_role_mapper.dart';
import '../application/select_role_controller.dart';
import '../../presentation/widgets/auth_language_switch.dart';
import '../../../../shared/ui/app_colors.dart';
import '../../../../shared/ui/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';

class SelectRolePage extends ConsumerStatefulWidget {
  const SelectRolePage({super.key});

  @override
  ConsumerState<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends ConsumerState<SelectRolePage> {
  /// 处理返回行为：首次登录选角色时返回登录页，其他场景优先正常回退。
  Future<void> _handleBack() async {
    final authSession = ref.read(authSessionProvider);
    if (authSession.needSelectRole) {
      await ref
          .read(authSessionProvider.notifier)
          .clearSession(reason: 'select_role_back_to_login');
      if (!mounted) {
        return;
      }
      context.goNamed(RoutePaths.loginPhoneName);
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(RoutePaths.loginPhoneName);
  }

  /// 提交当前角色选择，成功后进入首页。
  Future<void> _handleConfirm() async {
    final success = await ref
        .read(selectRoleControllerProvider.notifier)
        .submitSelection();
    if (!mounted || !success) {
      return;
    }
    context.goNamed(RoutePaths.homeName);
  }

  @override
  /// 构建角色选择页，并把顶部语言切换接到全局 Locale。
  Widget build(BuildContext context) {
    final state = ref.watch(selectRoleControllerProvider);
    final hasSelection = state.selectedRoleId != null;
    final isChineseSelected = context.isChineseLocale;

    ref.listen(selectRoleControllerProvider, (previous, next) {
      if (previous?.feedbackId == next.feedbackId ||
          next.feedbackMessage == null) {
        return;
      }

      AppToast.show(next.feedbackMessage!);
      ref.read(selectRoleControllerProvider.notifier).clearFeedback();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          '认证.选择角色标题'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pagePadding),
            child: AuthLanguageSwitch(
              isChineseSelected: isChineseSelected,
              onChanged: (isChineseSelected) async {
                await context.switchAppLocale(isChineseSelected);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '认证.选择角色说明'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      for (final role in _roles) ...<Widget>[
                        _RoleCard(
                          role: role,
                          selected: state.selectedRoleId == role.id,
                          onTap: () => ref
                              .read(selectRoleControllerProvider.notifier)
                              .setSelectedRole(role.id),
                        ),
                        if (role != _roles.last) const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: state.isSubmitting ? '认证.提交中'.tr() : '认证.确认选择'.tr(),
                enabled: hasSelection && !state.isSubmitting,
                onPressed: hasSelection && !state.isSubmitting
                    ? _handleConfirm
                    : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final _RoleItem role;
  final bool selected;
  final VoidCallback onTap;

  @override
  /// 构建单个角色卡片，选中时提升边框和背景强调。
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.brand : AppColors.divider;
    final backgroundColor = selected
        ? AppColors.brand.withValues(alpha: 0.08)
        : AppColors.surface;
    final iconBackgroundColor = selected
        ? AppColors.brand
        : AppColors.chipBackground;
    final iconColor = selected ? Colors.white : AppColors.brand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(role.icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.title.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.description.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleItem {
  const _RoleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

const List<_RoleItem> _roles = <_RoleItem>[
  _RoleItem(
    id: workerRoleId,
    title: '认证.工人求职者',
    description: '认证.工人求职者说明',
    icon: Icons.person_outline_rounded,
  ),
  _RoleItem(
    id: employerRoleId,
    title: '认证.企业雇主',
    description: '认证.企业雇主说明',
    icon: Icons.business_center_outlined,
  ),
  _RoleItem(
    id: visaProviderRoleId,
    title: '认证.签证服务商',
    description: '认证.签证服务商说明',
    icon: Icons.fact_check_outlined,
  ),
];
