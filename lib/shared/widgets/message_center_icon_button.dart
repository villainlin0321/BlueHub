import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_paths.dart';

/// 首页顶部统一的消息中心入口按钮。
class MessageCenterIconButton extends StatelessWidget {
  const MessageCenterIconButton({super.key});

  static const String _assetPath = 'assets/images/home_message_center.svg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: () => context.push(RoutePaths.messageCenter),
        padding: EdgeInsets.zero,
        splashRadius: 20,
        icon: SvgPicture.asset(
          _assetPath,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
