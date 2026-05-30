import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../messages/data/message_models.dart';
import '../../messages/data/message_providers.dart';
import '../application/chat/chat_page_args.dart';
import '../../../shared/network/page_result.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_user_avatar.dart';

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
  late List<_ChatMessageItem> _chatItems;
  late List<_SystemNoticeItem> _systemItems;
  bool _isLoadingChat = true;
  String? _chatError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _chatItems = const <_ChatMessageItem>[];
    _systemItems = _buildInitialSystemItems();
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasUnreadChat => _chatItems.any((item) => item.isUnread);

  bool get _hasUnreadSystem => _systemItems.any((item) => item.isUnread);

  void _markAllAsRead() {
    final List<int> unreadConversationIds = _chatItems
        .where((item) => item.isUnread)
        .map((item) => item.conversationId)
        .toList(growable: false);
    setState(() {
      _chatItems = _chatItems
          .map((item) => item.copyWith(unreadCount: 0))
          .toList(growable: false);
      _systemItems = _systemItems
          .map((item) => item.copyWith(isUnread: false))
          .toList(growable: false);
    });
    _markChatListAsRead(unreadConversationIds);
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoadingChat = true;
      _chatError = null;
    });

    try {
      final PageResult<ConversationVO> response = await ref
          .read(messageServiceProvider)
          .listConversations(page: 1, pageSize: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _chatItems = response.list
            .map(_ChatMessageItem.fromConversation)
            .toList(growable: false);
        _isLoadingChat = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingChat = false;
        _chatError = '消息加载失败，请稍后重试';
      });
    }
  }

  Future<void> _openChat(int index) async {
    final _ChatMessageItem item = _chatItems[index];
    if (item.isUnread) {
      final int previousUnreadCount = item.unreadCount;
      setState(() {
        _chatItems[index] = item.copyWith(unreadCount: 0);
      });
      try {
        await ref
            .read(messageServiceProvider)
            .markRead(conversationId: item.conversationId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _chatItems[index] = item.copyWith(unreadCount: previousUnreadCount);
          });
        }
      }
    }

    if (!mounted) {
      return;
    }

    await context.push(
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
  }

  void _markSystemAsRead(int index) {
    if (!_systemItems[index].isUnread) {
      return;
    }
    setState(() {
      _systemItems[index] = _systemItems[index].copyWith(isUnread: false);
    });
  }

  Future<void> _markChatListAsRead(List<int> conversationIds) async {
    if (conversationIds.isEmpty) {
      return;
    }
    for (final int conversationId in conversationIds) {
      try {
        await ref
            .read(messageServiceProvider)
            .markRead(conversationId: conversationId);
      } catch (_) {
        // 忽略单个会话的已读同步失败，避免打断当前页面交互。
      }
    }
  }

  List<_SystemNoticeItem> _buildInitialSystemItems() {
    return const <_SystemNoticeItem>[
      _SystemNoticeItem(
        title: '资质审核通过',
        time: '10-22 12:23:21',
        content: '您的企业资料审核已通过，赶紧去发布您的岗位套餐吧！赶紧去发布您的企业的岗位招聘信息吧',
        cardAssetPath: _noticeCardPrimaryAsset,
        isUnread: true,
      ),
      _SystemNoticeItem(
        title: '资质审核未通过',
        time: '09-22 12:23:21',
        content: '您的企业资料审核未通过，请重新编辑后提交！',
        cardAssetPath: _noticeCardSecondaryAsset,
      ),
      _SystemNoticeItem(
        title: '资质审核中',
        time: '09-18 12:23:21',
        content: '您的企业资料已提交，正在审核中，成功后将会有消息提示，您可以先去编辑相关岗位信息。',
        cardAssetPath: _noticeCardPendingAsset,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: _MessageHeader(
        onBack: () => Navigator.of(context).maybePop(),
        onMarkAllRead: _markAllAsRead,
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: Colors.white,
            child: _MessageTabBar(
              controller: _tabController,
              hasUnreadChat: _hasUnreadChat,
              hasUnreadSystem: _hasUnreadSystem,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _ChatTabView(
                  items: _chatItems,
                  isLoading: _isLoadingChat,
                  errorText: _chatError,
                  onTapItem: _openChat,
                  onRetry: _loadConversations,
                ),
                _SystemTabView(
                  items: _systemItems,
                  noticeIconAsset: _noticeIconAsset,
                  onTapItem: _markSystemAsRead,
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
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 48,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: onBack,
        padding: EdgeInsets.zero,
        splashRadius: 22,
        icon: SvgPicture.asset(
          _MessageCenterPageState._backAsset,
          width: 12,
          height: 24,
        ),
      ),
      title: Text(
        '消息中心',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.9),
          fontSize: 17,
          fontWeight: FontWeight.w500,
          height: 24 / 17,
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 92,
            child: TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                foregroundColor: _MessageCenterPageState._secondaryText,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(80, 32),
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
                    '全部已读',
                    style: TextStyle(
                      color: _MessageCenterPageState._secondaryText,
                      fontSize: 14,
                      height: 20 / 14,
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
    return TabBar(
      controller: controller,
      indicator: _FixedWidthUnderlineIndicator(
        color: _MessageCenterPageState._primaryBlue,
        width: 20,
        thickness: 2,
      ),
      indicatorPadding: const EdgeInsets.only(bottom: 0.5),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      padding: const EdgeInsets.only(top: 10),
      labelPadding: EdgeInsets.zero,
      tabs: <Widget>[
        _MessageTab(
          label: '聊天',
          isSelected: controller.index == 0,
          hasUnread: hasUnreadChat,
        ),
        _MessageTab(
          label: '系统通知',
          isSelected: controller.index == 1,
          hasUnread: hasUnreadSystem,
        ),
      ],
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
      height: 46,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? _MessageCenterPageState._primaryBlue
                        : _MessageCenterPageState._titleColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    height: 22 / 14,
                  ),
                ),
                if (hasUnread) ...<Widget>[
                  const SizedBox(width: 2),
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _MessageCenterPageState._dangerDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
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
  final Future<void> Function(int index) onTapItem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorText != null) {
      return _ChatStatusView(
        message: errorText!,
        actionLabel: '重新加载',
        onAction: onRetry,
      );
    }

    if (items.isEmpty) {
      return const _ChatStatusView(message: '暂无聊天消息');
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
            onTap: () => onTapItem(index),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 13, 16, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _MessageCenterPageState._titleColor,
                                    fontSize: 16,
                                    height: 22 / 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: const Color(0xFFBFBFBF),
                                  fontSize: 12,
                                  height: 18 / 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _MessageCenterPageState._hintText,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (item.isUnread) ...<Widget>[
                                SizedBox(width: 8),
                                _UnreadBadge(count: item.unreadCount),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _MessageCenterPageState._dangerDot,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12, height: 14 / 12),
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
        style: TextStyle(color: Colors.white, fontSize: 14, height: 20 / 14),
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
              style: const TextStyle(
                color: _MessageCenterPageState._hintText,
                fontSize: 14,
                height: 20 / 14,
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
    required this.noticeIconAsset,
    required this.onTapItem,
  });

  final List<_SystemNoticeItem> items;
  final String noticeIconAsset;
  final ValueChanged<int> onTapItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final _SystemNoticeItem item = items[index];
        return _SystemNoticeCard(
          item: item,
          noticeIconAsset: noticeIconAsset,
          onTap: () => onTapItem(index),
        );
      },
    );
  }
}

class _SystemNoticeCard extends StatelessWidget {
  const _SystemNoticeCard({
    required this.item,
    required this.noticeIconAsset,
    required this.onTap,
  });

  final _SystemNoticeItem item;
  final String noticeIconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(19.2);

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: SvgPicture.asset(item.cardAssetPath, fit: BoxFit.fill),
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
                        if (item.isUnread)
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
                                  style: TextStyle(
                                    color: _MessageCenterPageState._titleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: _MessageCenterPageState._hintText,
                                  fontSize: 12,
                                  height: 18 / 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.content,
                            style: TextStyle(
                              color: _MessageCenterPageState._secondaryText,
                              fontSize: 12,
                              height: 18 / 12,
                            ),
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
        ? '未命名用户'
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
      return '[图片]';
    case 'file':
      return '[文件]';
    default:
      return '[暂无内容]';
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
    return '用户';
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

class _SystemNoticeItem {
  const _SystemNoticeItem({
    required this.title,
    required this.time,
    required this.content,
    required this.cardAssetPath,
    this.isUnread = false,
  });

  final String title;
  final String time;
  final String content;
  final String cardAssetPath;
  final bool isUnread;

  _SystemNoticeItem copyWith({bool? isUnread}) {
    return _SystemNoticeItem(
      title: title,
      time: time,
      content: content,
      cardAssetPath: cardAssetPath,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}
