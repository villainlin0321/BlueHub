import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/app_colors.dart';
import '../../shell/application/shell_role_provider.dart';
import 'role_pages/company_jobs_page.dart';
import 'role_pages/job_seeker_jobs_page.dart';
import 'role_pages/service_provider_jobs_page.dart';

/// 招聘页：按角色切换内容，当前仅实现求职者场景。
class JobsPage extends ConsumerWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = context.locale;
    final ShellRole currentRole = ref.watch(shellRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyedSubtree(
        key: ValueKey<String>(
          '${currentRole.name}_${locale.languageCode}_${locale.countryCode ?? ''}',
        ),
        child: switch (currentRole) {
          ShellRole.jobSeeker => const JobSeekerJobsPage(),
          ShellRole.company => const CompanyJobsPage(),
          ShellRole.serviceProvider => const ServiceProviderJobsPage(),
        },
      ),
    );
  }
}
