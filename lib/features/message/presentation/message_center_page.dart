import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 消息中心页，按 Figma 设计稿还原顶部导航、Tab 及系统通知列表。
class MessageCenterPage extends StatefulWidget {
  const MessageCenterPage({super.key});

  @override
  State<MessageCenterPage> createState() => _MessageCenterPageState();
}

class _MessageCenterPageState extends State<MessageCenterPage>
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _chatItems = _buildInitialChatItems();
    _systemItems = _buildInitialSystemItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasUnreadChat => _chatItems.any((item) => item.isUnread);
  bool get _hasUnreadSystem => _systemItems.any((item) => item.isUnread);

  void _markAllAsRead() {
    setState(() {
      _chatItems = _chatItems
          .map((item) => item.copyWith(isUnread: false))
          .toList(growable: false);
      _systemItems = _systemItems
          .map((item) => item.copyWith(isUnread: false))
          .toList(growable: false);
    });
  }

  void _markChatAsRead(int index) {
    if (!_chatItems[index].isUnread) {
      return;
    }
    setState(() {
      _chatItems[index] = _chatItems[index].copyWith(isUnread: false);
    });
  }

  void _markSystemAsRead(int index) {
    if (!_systemItems[index].isUnread) {
      return;
    }
    setState(() {
      _systemItems[index] = _systemItems[index].copyWith(isUnread: false);
    });
  }

  List<_ChatMessageItem> _buildInitialChatItems() {
    return const <_ChatMessageItem>[
      _ChatMessageItem(
        name: 'BlueHub 官方客服',
        time: '10:41',
        preview: '您好，您提交的企业资料已进入审核流程，请耐心等待结果通知。',
        avatarLabel: '官',
        avatarColor: Color(0xFF3C8DFF),
        isUnread: true,
      ),
      _ChatMessageItem(
        name: '招聘顾问',
        time: '昨天',
        preview: '新的岗位套餐已准备完成，您可以前往发布页继续操作。',
        avatarLabel: '顾',
        avatarColor: Color(0xFF3FB27F),
      ),
      _ChatMessageItem(
        name: '面试通知',
        time: '周二',
        preview: '候选人已确认面试时间，请及时查看详情并做好安排。',
        avatarLabel: '面',
        avatarColor: Color(0xFFF5A623),
      ),
    ];
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
                      onTapItem: _markChatAsRead,
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
    required this.onTapItem,
  });

  final double scale;
  final List<_ChatMessageItem> items;
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
        final _ChatMessageItem item = items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scale),
          child: InkWell(
            borderRadius: BorderRadius.circular(16 * scale),
            onTap: () => onTapItem(index),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 14 * scale,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 20 * scale,
                        backgroundColor: item.avatarColor,
                        child: Text(
                          item.avatarLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (item.isUnread)
                        Positioned(
                          top: -1 * scale,
                          right: -1 * scale,
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
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  color: _MessageCenterPageState._titleColor,
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.w500,
                                  height: 20 / 15,
                                ),
                              ),
                            ),
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
                          item.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _MessageCenterPageState._secondaryText,
                            fontSize: 13 * scale,
                            height: 18 / 13,
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
      },
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
    required this.name,
    required this.time,
    required this.preview,
    required this.avatarLabel,
    required this.avatarColor,
    this.isUnread = false,
  });

  final String name;
  final String time;
  final String preview;
  final String avatarLabel;
  final Color avatarColor;
  final bool isUnread;

  _ChatMessageItem copyWith({bool? isUnread}) {
    return _ChatMessageItem(
      name: name,
      time: time,
      preview: preview,
      avatarLabel: avatarLabel,
      avatarColor: avatarColor,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}

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
