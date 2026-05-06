import 'package:flutter/material.dart';

import 'role_placeholder_me_page.dart';

/// 服务商端我的页。
class ServiceProviderMePage extends StatelessWidget {
  const ServiceProviderMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderMePage(
      title: '服务商我的',
      subtitle: '当前仅实现求职者端设计稿，后续会在这里补齐服务商资料、订单和经营能力。',
      icon: Icons.fact_check_outlined,
    );
  }
}
