import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_paths.dart';
import '../../features/message/application/message_session/message_session_controller.dart';

/// 首页顶部统一的消息中心入口按钮。
class MessageCenterIconButton extends ConsumerWidget {
  final Color color;

  const MessageCenterIconButton({super.key, this.color = Colors.white});

  static const String _assetPath = 'assets/images/home_message_center.svg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasUnread = ref.watch(
      messageSessionControllerProvider.select(
        (state) => state.hasUnreadConversations,
      ),
    );
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          IconButton(
            onPressed: () => context.push(RoutePaths.messageCenter),
            padding: EdgeInsets.zero,
            splashRadius: 20,
            icon: SvgPicture.asset(
              _assetPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              fit: BoxFit.contain,
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF24C3D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
