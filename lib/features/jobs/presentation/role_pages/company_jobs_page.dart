import 'package:flutter/material.dart';

/// 企业招聘页。
///
/// 当前需求只提供了求职者端设计稿，这里先接入企业端独立文件，
/// 后续拿到 Figma 后可在此文件继续扩展发布与管理职位能力。
class CompanyJobsPage extends StatelessWidget {
  const CompanyJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: _RolePlaceholder(
        title: '企业招聘',
        subtitle: '后续将在这里承载发布职位、筛选候选人等功能。',
        icon: Icons.business_center_outlined,
      ),
    );
  }
}

class _RolePlaceholder extends StatelessWidget {
  const _RolePlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF096DD9)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                height: 22 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
