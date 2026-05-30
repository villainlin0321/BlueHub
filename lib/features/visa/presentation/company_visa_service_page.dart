import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import 'role_pages/job_seeker_visa_page.dart';

/// 企业首页“签证服务”独立页，复用求职者签证内容组件。
class CompanyVisaServicePage extends StatelessWidget {
  const CompanyVisaServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: JobSeekerVisaPage(),
    );
  }
}
