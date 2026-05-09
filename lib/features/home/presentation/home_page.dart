import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../shell/application/shell_role_provider.dart';
import 'role_pages/company_home_page.dart';
import 'role_pages/job_seeker_home_page.dart';
import 'role_pages/service_provider_home_page.dart';

/// 首页：按角色切换内容，当前仅实现求职者场景。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellRole currentRole = ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        // 关键保护：Shell 多分支会同时保活，必须为 FAB 指定唯一 heroTag。
        heroTag: 'home_switch_role_fab',
        child: Text('切换\n角色'),
        onPressed: () {
          context.pushNamed(RoutePaths.selectRoleName);
        },
      ),
      body: switch (currentRole) {
        ShellRole.jobSeeker => const JobSeekerHomePage(),
        ShellRole.company => const CompanyHomePage(),
        ShellRole.serviceProvider => const ServiceProviderHomePage(),
      },
    );
  }
}
