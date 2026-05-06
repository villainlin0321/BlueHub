import 'package:flutter/material.dart';

/// 服务商招聘页。
///
/// 当前需求只提供了求职者端设计稿，这里先接入服务商端独立文件，
/// 后续拿到设计后可在此扩展岗位合作、服务匹配等功能。
class ServiceProviderJobsPage extends StatelessWidget {
  const ServiceProviderJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: _RolePlaceholder(
        title: '服务商招聘',
        subtitle: '后续将在这里承载服务商跟进岗位、匹配服务方案等能力。',
        icon: Icons.fact_check_outlined,
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
