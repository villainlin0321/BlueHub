import 'package:flutter/material.dart';

import 'role_placeholder_me_page.dart';

/// 企业端我的页。
class CompanyMePage extends StatelessWidget {
  const CompanyMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderMePage(
      title: '企业我的',
      subtitle: '当前仅实现求职者端设计稿，后续会在这里补齐企业账号信息与设置能力。',
      icon: Icons.business_center_outlined,
    );
  }
}
