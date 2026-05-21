import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../messages/data/message_models.dart';
import '../../messages/data/message_providers.dart';
import '../../../shared/network/page_result.dart';
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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
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

  Future<void> _markChatAsRead(int index) async {
    if (!_chatItems[index].isUnread) {
      return;
    }
    final int conversationId = _chatItems[index].conversationId;
    final int previousUnreadCount = _chatItems[index].unreadCount;
    setState(() {
      _chatItems[index] = _chatItems[index].copyWith(unreadCount: 0);
    });
    try {
      await ref
          .read(messageServiceProvider)
          .markRead(conversationId: conversationId);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _chatItems[index] = _chatItems[index].copyWith(
          unreadCount: previousUnreadCount,
        );
      });
    }
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
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double contentWidth = screenWidth.clamp(0, 420);
    final double scale = (contentWidth / 375).clamp(0.85, 1.12);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: _MessageHeader(
        scale: scale,
        onBack: () => Navigator.of(context).maybePop(),
        onMarkAllRead: _markAllAsRead,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: contentWidth,
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                child: _MessageTabBar(
                  controller: _tabController,
                  scale: scale,
                  hasUnreadChat: _hasUnreadChat,
                  hasUnreadSystem: _hasUnreadSystem,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _ChatTabView(
                      scale: scale,
                      items: _chatItems,
                      isLoading: _isLoadingChat,
                      errorText: _chatError,
                      onTapItem: _markChatAsRead,
                      onRetry: _loadConversations,
                    ),
                    _SystemTabView(
                      scale: scale,
                      items: _systemItems,
                      noticeIconAsset: _noticeIconAsset,
                      onTapItem: _markSystemAsRead,
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

class _MessageHeader extends StatelessWidget implements PreferredSizeWidget {
  const _MessageHeader({
    required this.scale,
    required this.onBack,
    required this.onMarkAllRead,
  });

  final double scale;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  @override
  Size get preferredSize => Size.fromHeight(48 * scale);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 48 * scale,
      centerTitle: true,
      titleSpacing: 0,
      leadingWidth: 44 * scale,
      leading: IconButton(
        onPressed: onBack,
        padding: EdgeInsets.zero,
        splashRadius: 22 * scale,
        icon: SvgPicture.asset(
          _MessageCenterPageState._backAsset,
          width: 12 * scale,
          height: 24 * scale,
        ),
      ),
      title: Text(
        '消息中心',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.9),
          fontSize: 17 * scale,
          fontWeight: FontWeight.w500,
          height: 24 / 17,
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 8 * scale),
          child: SizedBox(
            width: 92 * scale,
            child: TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                foregroundColor: _MessageCenterPageState._secondaryText,
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                minimumSize: Size(80 * scale, 32 * scale),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SvgPicture.asset(
                    _MessageCenterPageState._markAllReadAsset,
                    width: 11 * scale,
                    height: 13 * scale,
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    '全部已读',
                    style: TextStyle(
                      color: _MessageCenterPageState._secondaryText,
                      fontSize: 14 * scale,
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
    required this.scale,
    required this.hasUnreadChat,
    required this.hasUnreadSystem,
  });

  final TabController controller;
  final double scale;
  final bool hasUnreadChat;
  final bool hasUnreadSystem;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicator: _FixedWidthUnderlineIndicator(
        color: _MessageCenterPageState._primaryBlue,
        width: 20 * scale,
        thickness: 2 * scale,
      ),
      indicatorPadding: EdgeInsets.only(bottom: 0.5 * scale),
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      padding: EdgeInsets.only(top: 10 * scale),
      labelPadding: EdgeInsets.zero,
      tabs: <Widget>[
        _MessageTab(
          label: '聊天',
          scale: scale,
          isSelected: controller.index == 0,
          hasUnread: hasUnreadChat,
        ),
        _MessageTab(
          label: '系统通知',
          scale: scale,
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
    required this.scale,
    required this.isSelected,
    required this.hasUnread,
  });

  final String label;
  final double scale;
  final bool isSelected;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46 * scale,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 22 * scale,
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
                    fontSize: 14 * scale,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    height: 22 / 14,
                  ),
                ),
                if (hasUnread) ...<Widget>[
                  SizedBox(width: 2 * scale),
                  Container(
                    margin: EdgeInsets.only(top: 1 * scale),
                    width: 8 * scale,
                    height: 8 * scale,
                    decoration: const BoxDecoration(
                      color: _MessageCenterPageState._dangerDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10 * scale),
        ],
      ),
    );
  }
}

class _ChatTabView extends StatelessWidget {
  const _ChatTabView({
    required this.scale,
    required this.items,
    required this.isLoading,
    required this.errorText,
    required this.onTapItem,
    required this.onRetry,
  });

  final double scale;
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
            scale: scale,
            onTap: () => onTapItem(index),
          );
        },
      ),
    );
  }
}

class _ChatConversationTile extends StatelessWidget {
  const _ChatConversationTile({
    required this.item,
    required this.scale,
    required this.onTap,
  });

  final _ChatMessageItem item;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72 * scale,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 72 * scale,
                right: 0,
                bottom: 0,
                child: Container(height: 0.5, color: const Color(0xFFF0F0F0)),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16 * scale),
                child: Row(
                  children: <Widget>[
                    AppUserAvatar(
                      imageUrl: item.avatarUrl,
                      size: 44 * scale,
                      backgroundColor: const Color(0xFF487BFE),
                      borderRadius: BorderRadius.circular(22 * scale),
                      placeholder: _AvatarFallbackText(
                        text: item.avatarFallbackText,
                        scale: scale,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12 * scale,
                          13 * scale,
                          16 * scale,
                          13 * scale,
                        ),
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
                                      color:
                                          _MessageCenterPageState._titleColor,
                                      fontSize: 16 * scale,
                                      height: 22 / 16,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8 * scale),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    color: const Color(0xFFBFBFBF),
                                    fontSize: 12 * scale,
                                    height: 18 / 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6 * scale),
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
                                      fontSize: 14 * scale,
                                      height: 18 / 14,
                                    ),
                                  ),
                                ),
                                if (item.isUnread) ...<Widget>[
                                  SizedBox(width: 8 * scale),
                                  _UnreadBadge(
                                    count: item.unreadCount,
                                    scale: scale,
                                  ),
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
      ),
    );
  }
}

class _AvatarFallbackText extends StatelessWidget {
  const _AvatarFallbackText({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14 * scale,
          height: 20 / 14,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final String text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(minWidth: 18 * scale, minHeight: 18 * scale),
      padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: _MessageCenterPageState._dangerDot,
        borderRadius: BorderRadius.circular(9 * scale),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * scale,
          height: 14 / 12,
        ),
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
    required this.scale,
    required this.items,
    required this.noticeIconAsset,
    required this.onTapItem,
  });

  final double scale;
  final List<_SystemNoticeItem> items;
  final String noticeIconAsset;
  final ValueChanged<int> onTapItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        12 * scale,
        12 * scale,
        MediaQuery.paddingOf(context).bottom + 24 * scale,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
      itemBuilder: (BuildContext context, int index) {
        final _SystemNoticeItem item = items[index];
        return _SystemNoticeCard(
          item: item,
          scale: scale,
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
    required this.scale,
    required this.noticeIconAsset,
    required this.onTap,
  });

  final _SystemNoticeItem item;
  final double scale;
  final String noticeIconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(19.2 * scale);

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
                padding: EdgeInsets.fromLTRB(
                  12 * scale,
                  14 * scale,
                  12 * scale,
                  14 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        SvgPicture.asset(
                          noticeIconAsset,
                          width: 32 * scale,
                          height: 32 * scale,
                        ),
                        if (item.isUnread)
                          Positioned(
                            top: 3 * scale,
                            right: 2 * scale,
                            child: Container(
                              width: 8 * scale,
                              height: 8 * scale,
                              decoration: const BoxDecoration(
                                color: _MessageCenterPageState._dangerDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12 * scale),
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
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12 * scale),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: _MessageCenterPageState._hintText,
                                  fontSize: 12 * scale,
                                  height: 18 / 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),
                          Text(
                            item.content,
                            style: TextStyle(
                              color: _MessageCenterPageState._secondaryText,
                              fontSize: 12 * scale,
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
    return _ChatMessageItem(
      conversationId: conversation.conversationId,
      name: nickname,
      time: _formatConversationTime(conversation.lastMessage.sentAt),
      preview: _buildConversationPreview(conversation.lastMessage),
      avatarUrl: conversation.targetUser.avatarUrl,
      avatarFallbackText: _buildAvatarFallbackText(nickname),
      unreadCount: conversation.unreadCount,
    );
  }

  final int conversationId;
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
