import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/app_colors.dart';
import '../../shell/application/shell_role_provider.dart';
import 'role_pages/company_visa_page.dart';
import 'role_pages/job_seeker_visa_page.dart';
import 'role_pages/service_provider_visa_page.dart';

/// 签证页：按角色切换内容。
class VisaPage extends ConsumerWidget {
  const VisaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellRole currentRole = ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: switch (currentRole) {
        ShellRole.jobSeeker => const JobSeekerVisaPage(),
        ShellRole.company => const CompanyVisaPage(),
        ShellRole.serviceProvider => const ServiceProviderVisaPage(),
      },
    );
  }
}
