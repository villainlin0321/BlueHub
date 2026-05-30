import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import 'role_pages/company_jobs_page.dart';

/// 服务商首页“人才中心”独立页，复用企业人才中心内容组件。
class ServiceProviderTalentCenterPage extends StatelessWidget {
  const ServiceProviderTalentCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: CompanyJobsPage(),
    );
  }
}
