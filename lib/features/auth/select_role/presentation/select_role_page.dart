import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../presentation/widgets/auth_language_switch.dart';
import '../../../../shared/ui/app_colors.dart';
import '../../../../shared/ui/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';

class SelectRolePage extends StatefulWidget {
  const SelectRolePage({super.key});

  @override
  State<SelectRolePage> createState() => _SelectRolePageState();
}

class _SelectRolePageState extends State<SelectRolePage> {
  String? _selectedRoleId;
  bool _isChineseSelected = true;

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.loginPhone);
  }

  void _handleConfirm() {
    final role = _roles.firstWhere((item) => item.id == _selectedRoleId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已选择${role.title}（占位）')));
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedRoleId != null;

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
          '选择角色',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pagePadding),
            child: AuthLanguageSwitch(
              isChineseSelected: _isChineseSelected,
              onChanged: (isChineseSelected) {
                setState(() => _isChineseSelected = isChineseSelected);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '不同角色将看到不同的首页与功能。后续可在 “我的” 中切换不同角色',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 28),
                      for (final role in _roles) ...<Widget>[
                        _RoleCard(
                          role: role,
                          selected: _selectedRoleId == role.id,
                          onTap: () => setState(() => _selectedRoleId = role.id),
                        ),
                        if (role != _roles.last) const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '确认选择',
                enabled: hasSelection,
                onPressed: hasSelection ? _handleConfirm : null,
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
                      role.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.description,
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
    id: 'worker',
    title: '工人/求职者',
    description: '寻找海外工作、办理签证',
    icon: Icons.person_outline_rounded,
  ),
  _RoleItem(
    id: 'employer',
    title: '企业/雇主',
    description: '发布职位、筛选候选人',
    icon: Icons.business_center_outlined,
  ),
  _RoleItem(
    id: 'visaProvider',
    title: '签证服务商',
    description: '提供签证服务、管理案件',
    icon: Icons.fact_check_outlined,
  ),
];
