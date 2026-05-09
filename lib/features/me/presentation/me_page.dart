import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../shell/application/shell_role_provider.dart';
import 'role_pages/company_me_page.dart';
import 'role_pages/job_seeker_me_page.dart';
import 'role_pages/service_provider_me_page.dart';

/// 我的页：按角色切换内容，当前仅实现求职者场景。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellRole currentRole = ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(RoutePaths.selectRoleName);
        },
        child: const Text('切换\n角色'),
      ),
      body: switch (currentRole) {
        ShellRole.jobSeeker => const JobSeekerMePage(),
        ShellRole.company => const CompanyMePage(),
        ShellRole.serviceProvider => const ServiceProviderMePage(),
      },
    );
  }
}
