import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_toast.dart';
import '../application/message_session/message_session_controller.dart';
import '../../jobs/presentation/job_detail_page.dart';
import '../../order/presentation/order_detail_page.dart';
import '../../service_detail/presentation/service_detail_page.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../messages/data/message_models.dart';
import '../application/chat/chat_page_args.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_user_avatar.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 消息中心页，按 Figma 设计稿还原顶部导航、Tab 及系统通知列表。
class MessageCenterPage extends ConsumerStatefulWidget {
  const MessageCenterPage({super.key});

  @override
  ConsumerState<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends ConsumerState<MessageCenterPage>
    with SingleTickerProviderStateMixin {
  static const Color _pageBackground = Color(0xFFF5F7FA);
  static const Color _primaryBlue = Color(0xFF096DD9);
  static const Color _titleColor = Color(0xFF262626);
  static const Color _secondaryText = Color(0xFF595959);
  static const Color _hintText = Color(0xFF8C8C8C);
  static const Color _dangerDot = Color(0xFFF24C3D);

  static const String _backAsset = 'assets/images/mpflx21r-d5apiyu.svg';
  static const String _markAllReadAsset = 'assets/images/mpflx21q-dvkf9hj.svg';
  static const String _noticeIconAsset = 'assets/images/mpflx21r-e7zb1k4.svg';
  static const String _noticeCardPrimaryAsset =
      'assets/images/mpflx21r-n2v37z6.svg';
  static const String _noticeCardSecondaryAsset =
      'assets/images/mpflx21r-5oozz2u.svg';
  static const String _noticeCardPendingAsset =
      'assets/images/mpflx21r-qvw8ip7.svg';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    // 自定义 Tab 文案颜色依赖 controller.index，切换时主动刷新页面以同步选中态。
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 监听 Tab 切换，确保自定义 Tab 文字颜色和红点位置能跟随选中状态即时刷新。
  void _handleTabChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _markAllAsRead(List<_ChatMessageItem> chatItems) async {
    if (_tabController.index == 1) {
      await ref
          .read(messageSessionControllerProvider.notifier)
          .markAllNotificationsRead();
      return;
    }
    final List<int> unreadConversationIds = chatItems
        .where((item) => item.isUnread)
        .map((item) => item.conversationId)
        .toList(growable: false);
    await ref
        .read(messageSessionControllerProvider.notifier)
        .markAllConversationsRead(unreadConversationIds);
  }

  Future<void> _openChat(_ChatMessageItem item) async {
    if (item.isUnread) {
      await ref
          .read(messageSessionControllerProvider.notifier)
          .markConversationRead(item.conversationId);
    }

    if (!mounted) {
      return;
    }

    final Object? result = await context.push(
      RoutePaths.chat,
      extra: ChatPageArgs(
        targetUserId: item.targetUserId,
        targetUserRole: item.targetUserRole,
        nickname: item.name,
        avatarUrl: item.avatarUrl,
        conversationId: item.conversationId,
        isOnline: item.isOnline,
        relatedOrderId: item.relatedOrderId,
        packageName: item.packageName,
        orderStatus: item.orderStatus,
      ),
    );

    if (result == true && mounted) {
      await ref
          .read(messageSessionControllerProvider.notifier)
          .refreshConversations();
    }
  }

  Future<void> _handleSystemNotificationTap(NotificationVO item) async {
    if (!item.isRead) {
      await ref
          .read(messageSessionControllerProvider.notifier)
          .markNotificationRead(item.notificationId);
    }
    if (!mounted) {
      return;
    }
    _openNotificationTarget(item);
  }

  void _openNotificationTarget(NotificationVO item) {
    final String bizType = item.bizType.trim().toLowerCase();
    final int bizId = item.bizId;
    switch (bizType) {
      case 'order':
        if (bizId <= 0) {
          AppToast.show('暂不支持该通知跳转');
          return;
        }
        context.push(
          RoutePaths.orderDetail,
          extra: OrderDetailPageArgs(orderId: bizId),
        );
        return;
      case 'job':
        if (bizId <= 0) {
          AppToast.show('暂不支持该通知跳转');
          return;
        }
        context.push(
          RoutePaths.jobDetail,
          extra: JobDetailPageArgs(jobId: bizId),
        );
        return;
      case 'package':
        if (bizId <= 0) {
          AppToast.show('暂不支持该通知跳转');
          return;
        }
        context.push(
          RoutePaths.serviceDetail,
          extra: ServiceDetailPageArgs(packageId: bizId),
        );
        return;
      case 'application':
        final ShellRole role = ref.read(shellRoleProvider);
        context.push(
          role == ShellRole.company
              ? RoutePaths.companyApplications
              : RoutePaths.myApplications,
        );
        return;
      default:
        AppToast.show('暂不支持该通知跳转');
        return;
    }
  }

  String _resolveNotificationCardAsset(String type) {
    switch (type.trim()) {
      case 'order_status':
        return _noticeCardPrimaryAsset;
      case 'application':
        return _noticeCardSecondaryAsset;
      default:
        return _noticeCardPendingAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(messageSessionControllerProvider);
    final List<_ChatMessageItem> chatItems = sessionState.conversations
        .map(_ChatMessageItem.fromConversation)
        .toList(growable: false);
    final bool hasUnreadSystem = sessionState.hasUnreadNotifications;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: _MessageHeader(
        onBack: () => Navigator.of(context).maybePop(),
        onMarkAllRead: () => unawaited(_markAllAsRead(chatItems)),
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: Colors.white,
            child: _MessageTabBar(
              controller: _tabController,
              hasUnreadChat: chatItems.any((item) => item.isUnread),
              hasUnreadSystem: hasUnreadSystem,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _ChatTabView(
                  items: chatItems,
                  isLoading: sessionState.isInitializing,
                  errorText: sessionState.loadErrorMessage,
                  onTapItem: _openChat,
                  onRetry: () => ref
                      .read(messageSessionControllerProvider.notifier)
                      .refreshConversations(),
                ),
                _SystemTabView(
                  items: sessionState.notifications,
                  isLoading: sessionState.isNotificationsInitializing,
                  errorText: sessionState.notificationLoadErrorMessage,
                  noticeIconAsset: _noticeIconAsset,
                  resolveCardAssetPath: _resolveNotificationCardAsset,
                  onTapItem: _handleSystemNotificationTap,
                  onRetry: () => ref
                      .read(messageSessionControllerProvider.notifier)
                      .refreshNotifications(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget implements PreferredSizeWidget {
  const _MessageHeader({required this.onBack, required this.onMarkAllRead});

  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 44,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: onBack,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        icon: SvgPicture.asset(
          _MessageCenterPageState._backAsset,
          width: 12,
          height: 24,
        ),
      ),
      title: Text(
        '消息.消息中心'.tr(),
        textAlign: TextAlign.center,
        style: TestStyle.pingFangMedium(
          fontSize: 17,
          color: Colors.black.withValues(alpha: 0.9),
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            height: 44,
            child: TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                foregroundColor: _MessageCenterPageState._secondaryText,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SvgPicture.asset(
                    _MessageCenterPageState._markAllReadAsset,
                    width: 11,
                    height: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '消息.全部已读'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 14,
                      color: _MessageCenterPageState._secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageTabBar extends StatelessWidget {
  const _MessageTabBar({
    required this.controller,
    required this.hasUnreadChat,
    required this.hasUnreadSystem,
  });

  final TabController controller;
  final bool hasUnreadChat;
  final bool hasUnreadSystem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: controller,
        indicator: _FixedWidthUnderlineIndicator(
          color: _MessageCenterPageState._primaryBlue,
          width: 20,
          thickness: 2,
        ),
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: const EdgeInsets.only(top: 10),
        labelPadding: EdgeInsets.zero,
        tabs: <Widget>[
          _MessageTab(
            label: '消息.聊天'.tr(),
            isSelected: controller.index == 0,
            hasUnread: hasUnreadChat,
          ),
          _MessageTab(
            label: '消息.系统通知'.tr(),
            isSelected: controller.index == 1,
            hasUnread: hasUnreadSystem,
          ),
        ],
      ),
    );
  }
}

class _MessageTab extends StatelessWidget {
  const _MessageTab({
    required this.label,
    required this.isSelected,
    required this.hasUnread,
  });

  final String label;
  final bool isSelected;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                label,
                style:
                    (isSelected
                            ? TestStyle.pingFangMedium(
                                fontSize: 14,
                                color: _MessageCenterPageState._primaryBlue,
                              )
                            : TestStyle.pingFangRegular(
                                fontSize: 14,
                                color: _MessageCenterPageState._titleColor,
                              ))
                        .copyWith(height: 22 / 14),
              ),
            ),
            if (hasUnread)
              const Positioned(
                top: -1,
                right: -8,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _MessageCenterPageState._dangerDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatTabView extends StatelessWidget {
  const _ChatTabView({
    required this.items,
    required this.isLoading,
    required this.errorText,
    required this.onTapItem,
    required this.onRetry,
  });

  final List<_ChatMessageItem> items;
  final bool isLoading;
  final String? errorText;
  final Future<void> Function(_ChatMessageItem item) onTapItem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorText != null) {
      return _ChatStatusView(
        message: errorText!,
        actionLabel: '消息.重新加载'.tr(),
        onAction: onRetry,
      );
    }

    if (items.isEmpty) {
      return _ChatStatusView(message: '消息.暂无聊天消息'.tr());
    }

    return ColoredBox(
      color: Colors.white,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox.shrink(),
        itemBuilder: (BuildContext context, int index) {
          final _ChatMessageItem item = items[index];
          return _ChatConversationTile(
            item: item,
            onTap: () => onTapItem(item),
          );
        },
      ),
    );
  }
}

class _ChatConversationTile extends StatelessWidget {
  const _ChatConversationTile({required this.item, required this.onTap});

  final _ChatMessageItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 72,
                right: 0,
                bottom: 0,
                child: Container(height: 0.5, color: const Color(0xFFF0F0F0)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: <Widget>[
                    AppUserAvatar(
                      imageUrl: item.avatarUrl,
                      size: 44,
                      backgroundColor: const Color(0xFF487BFE),
                      borderRadius: BorderRadius.circular(22),
                      placeholder: _AvatarFallbackText(
                        text: item.avatarFallbackText,
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 72,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 13, 16, 13),
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 84,
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TestStyle.pingFangRegular(
                                    fontSize: 16,
                                    color: _MessageCenterPageState._titleColor,
                                  ).copyWith(height: 22 / 16),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 0,
                                child: Text(
                                  item.time,
                                  textAlign: TextAlign.right,
                                  style: TestStyle.regular(
                                    fontSize: 12,
                                    color: const Color(0xFFBFBFBF),
                                  ).copyWith(height: 18 / 12),
                                ),
                              ),
                              Positioned(
                                top: 28,
                                left: 0,
                                right: item.isUnread ? 30 : 0,
                                child: Text(
                                  item.preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TestStyle.pingFangRegular(
                                    fontSize: 14,
                                    color: _MessageCenterPageState._hintText,
                                  ).copyWith(height: 18 / 14),
                                ),
                              ),
                              if (item.isUnread)
                                Positioned(
                                  right: 0,
                                  top: 28,
                                  child: _UnreadBadge(count: item.unreadCount),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _MessageCenterPageState._dangerDot,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TestStyle.regular(
          fontSize: 12,
          color: Colors.white,
        ).copyWith(height: 14 / 12),
      ),
    );
  }
}

class _AvatarFallbackText extends StatelessWidget {
  const _AvatarFallbackText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TestStyle.pingFangRegular(fontSize: 14, color: Colors.white),
      ),
    );
  }
}

class _ChatStatusView extends StatelessWidget {
  const _ChatStatusView({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    if (actionLabel == null && onAction == null) {
      return Center(
        child: AppEmptyState(
          message: message,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.regular(
                fontSize: 14,
                color: _MessageCenterPageState._hintText,
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SystemTabView extends StatelessWidget {
  const _SystemTabView({
    required this.items,
    required this.isLoading,
    required this.errorText,
    required this.noticeIconAsset,
    required this.resolveCardAssetPath,
    required this.onTapItem,
    required this.onRetry,
  });

  final List<NotificationVO> items;
  final bool isLoading;
  final String? errorText;
  final String noticeIconAsset;
  final String Function(String type) resolveCardAssetPath;
  final Future<void> Function(NotificationVO item) onTapItem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorText != null) {
      return _ChatStatusView(
        message: errorText!,
        actionLabel: '消息.重新加载'.tr(),
        onAction: onRetry,
      );
    }

    if (items.isEmpty) {
      return const _ChatStatusView(message: '暂无系统通知');
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        0,
        0,
        0,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (BuildContext context, int index) {
        final NotificationVO item = items[index];
        return _SystemNoticeCard(
          item: item,
          cardAssetPath: resolveCardAssetPath(item.type),
          noticeIconAsset: noticeIconAsset,
          onTap: () => onTapItem(item),
        );
      },
    );
  }
}

class _SystemNoticeCard extends StatelessWidget {
  const _SystemNoticeCard({
    required this.item,
    required this.cardAssetPath,
    required this.noticeIconAsset,
    required this.onTap,
  });

  final NotificationVO item;
  final String cardAssetPath;
  final String noticeIconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(19.2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SvgPicture.asset(cardAssetPath, fit: BoxFit.fill),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          SvgPicture.asset(
                            noticeIconAsset,
                            width: 32,
                            height: 32,
                          ),
                          if (!item.isRead)
                            Positioned(
                              top: 3,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _MessageCenterPageState._dangerDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TestStyle.pingFangMedium(
                                      fontSize: 14,
                                      color:
                                          _MessageCenterPageState._titleColor,
                                    ).copyWith(height: 20 / 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatConversationTime(item.createdAt),
                                  style: TestStyle.regular(
                                    fontSize: 12,
                                    color: _MessageCenterPageState._hintText,
                                  ).copyWith(height: 18 / 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.content,
                              style: TestStyle.pingFangRegular(
                                fontSize: 12,
                                color: _MessageCenterPageState._secondaryText,
                              ).copyWith(height: 18 / 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedWidthUnderlineIndicator extends Decoration {
  const _FixedWidthUnderlineIndicator({
    required this.color,
    required this.width,
    required this.thickness,
  });

  final Color color;
  final double width;
  final double thickness;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthUnderlinePainter(
      color: color,
      width: width,
      thickness: thickness,
    );
  }
}

class _FixedWidthUnderlinePainter extends BoxPainter {
  const _FixedWidthUnderlinePainter({
    required this.color,
    required this.width,
    required this.thickness,
  });

  final Color color;
  final double width;
  final double thickness;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null) {
      return;
    }

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double left = offset.dx + (size.width - width) / 2;
    final double top = offset.dy + size.height - thickness;
    final RRect indicator = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, thickness),
      Radius.circular(thickness / 2),
    );
    canvas.drawRRect(indicator, paint);
  }
}

class _ChatMessageItem {
  const _ChatMessageItem({
    required this.conversationId,
    required this.targetUserId,
    required this.targetUserRole,
    required this.isOnline,
    required this.relatedOrderId,
    required this.packageName,
    required this.orderStatus,
    required this.name,
    required this.time,
    required this.preview,
    required this.avatarUrl,
    required this.avatarFallbackText,
    required this.unreadCount,
  });

  factory _ChatMessageItem.fromConversation(ConversationVO conversation) {
    final String nickname = conversation.targetUser.nickname.trim().isEmpty
        ? '消息.未命名用户'.tr()
        : conversation.targetUser.nickname.trim();
    final RelatedOrderVO? relatedOrder = conversation.relatedOrder;
    return _ChatMessageItem(
      conversationId: conversation.conversationId,
      targetUserId: conversation.targetUser.userId,
      targetUserRole: conversation.targetUser.role,
      isOnline: conversation.targetUser.isOnline,
      relatedOrderId: relatedOrder?.orderId ?? 0,
      packageName: relatedOrder?.packageName ?? '',
      orderStatus: relatedOrder?.status ?? '',
      name: nickname,
      time: _formatConversationTime(conversation.lastMessage.sentAt),
      preview: _buildConversationPreview(conversation.lastMessage),
      avatarUrl: conversation.targetUser.avatarUrl,
      avatarFallbackText: _buildAvatarFallbackText(nickname),
      unreadCount: conversation.unreadCount,
    );
  }

  final int conversationId;
  final int targetUserId;
  final String targetUserRole;
  final bool isOnline;
  final int relatedOrderId;
  final String packageName;
  final String orderStatus;
  final String name;
  final String time;
  final String preview;
  final String avatarUrl;
  final String avatarFallbackText;
  final int unreadCount;

  bool get isUnread => unreadCount > 0;

  _ChatMessageItem copyWith({int? unreadCount}) {
    return _ChatMessageItem(
      conversationId: conversationId,
      targetUserId: targetUserId,
      targetUserRole: targetUserRole,
      isOnline: isOnline,
      relatedOrderId: relatedOrderId,
      packageName: packageName,
      orderStatus: orderStatus,
      name: name,
      time: time,
      preview: preview,
      avatarUrl: avatarUrl,
      avatarFallbackText: avatarFallbackText,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

String _buildConversationPreview(LastMessageVO message) {
  final String content = message.content.trim();
  if (content.isNotEmpty) {
    return content;
  }

  switch (message.type) {
    case 'image':
      return '消息.图片'.tr();
    case 'file':
      return '消息.文件'.tr();
    default:
      return '消息.暂无内容'.tr();
  }
}

String _formatConversationTime(String sentAt) {
  final DateTime? dateTime = DateTime.tryParse(sentAt);
  if (dateTime != null) {
    return '${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  final RegExp matchDate = RegExp(r'(\d{2})[-/](\d{2})');
  final RegExpMatch? match = matchDate.firstMatch(sentAt);
  if (match != null) {
    return '${match.group(1)}-${match.group(2)}';
  }

  return sentAt.trim();
}

String _buildAvatarFallbackText(String nickname) {
  final String trimmed = nickname.trim();
  if (trimmed.isEmpty) {
    return '消息.用户'.tr();
  }

  final String compact = trimmed.replaceAll(' ', '');
  final RegExp englishOrNumber = RegExp(r'^[A-Za-z0-9]+$');
  if (englishOrNumber.hasMatch(compact)) {
    final int end = compact.length >= 2 ? 2 : compact.length;
    return compact.substring(0, end).toUpperCase();
  }

  final List<int> runes = compact.runes.take(2).toList(growable: false);
  return String.fromCharCodes(runes);
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
