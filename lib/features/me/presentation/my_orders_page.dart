import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  static const _tabs = <_OrderFilter>[
    _OrderFilter.all,
    _OrderFilter.pendingUpload,
    _OrderFilter.pendingPayment,
    _OrderFilter.processing,
    _OrderFilter.completed,
  ];

  static const _orders = <_OrderItem>[
    _OrderItem(
      filter: _OrderFilter.pendingUpload,
      tagLabel: '紧急',
      tagStyle: _OrderTagStyle.urgent,
      timeText: '今天 12:10:21',
      title: '德国厨师专属工作签证',
      price: '¥15,000.00',
      provider: '中欧出海签证服务有限公司',
      packageType: '基础套餐',
      orderNo: 'CLSKJ98793120238',
      actions: <_OrderAction>[
        _OrderAction.outline('联系商家'),
        _OrderAction.filled('上传材料'),
      ],
    ),
    _OrderItem(
      filter: _OrderFilter.pendingPayment,
      tagLabel: '待支付',
      tagStyle: _OrderTagStyle.blue,
      timeText: '2026-03-25 10:23',
      title: '法国高级技术人才签',
      price: '¥20,000.00',
      provider: '中欧出海签证服务有限公司',
      packageType: '基础套餐',
      orderNo: 'CLSKJ98793120239',
      actions: <_OrderAction>[
        _OrderAction.outline('联系商家'),
        _OrderAction.filled('去支付'),
      ],
    ),
    _OrderItem(
      filter: _OrderFilter.processing,
      tagLabel: '紧急',
      tagStyle: _OrderTagStyle.urgent,
      timeText: '2026-03-21 15:40',
      title: '荷兰焊工雇主担保签',
      price: '¥18,500.00',
      provider: '欧亚海外服务有限公司',
      packageType: '加急套餐',
      orderNo: 'CLSKJ98793120240',
      progressLabel: '当前进度',
      progressValue: '资料审核中',
      actions: <_OrderAction>[
        _OrderAction.outline('立即沟通'),
        _OrderAction.filled('查看进度'),
      ],
    ),
    _OrderItem(
      filter: _OrderFilter.processing,
      tagLabel: '紧急',
      tagStyle: _OrderTagStyle.urgent,
      timeText: '2026-03-19 09:18',
      title: '新加坡海员工作签证',
      price: '¥12,800.00',
      provider: '蓝海国际服务有限公司',
      packageType: '标准套餐',
      orderNo: 'CLSKJ98793120241',
      actions: <_OrderAction>[
        _OrderAction.outline('立即沟通'),
        _OrderAction.filled('补充材料'),
      ],
    ),
    _OrderItem(
      filter: _OrderFilter.completed,
      timeText: '2026-03-12 20:16',
      title: '德国护理岗位入境签证',
      price: '¥16,300.00',
      provider: '中欧出海签证服务有限公司',
      packageType: 'VIP套餐',
      orderNo: 'CLSKJ98793120242',
      actions: <_OrderAction>[
        _OrderAction.outline('联系商家'),
        _OrderAction.filled('查看详情'),
      ],
    ),
  ];

  _OrderFilter _selectedFilter = _OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _selectedFilter == _OrderFilter.all
        ? _orders
        : _orders.where((order) => order.filter == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(RoutePaths.me);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF262626),
          ),
        ),
        title: const Text(
          '我的订单',
          style: TextStyle(
            color: Color(0xE6262626),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _OrderStatusTabs(
            filters: _tabs,
            selected: _selectedFilter,
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: visibleOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _OrderCard(order: visibleOrders[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _OrderFilter {
  all('全部'),
  pendingUpload('待上传'),
  pendingPayment('待支付'),
  processing('办理中'),
  completed('已完成');

  const _OrderFilter(this.label);

  final String label;
}

enum _OrderTagStyle {
  urgent,
  blue,
}

class _OrderItem {
  const _OrderItem({
    required this.filter,
    required this.timeText,
    required this.title,
    required this.price,
    required this.provider,
    required this.packageType,
    required this.orderNo,
    required this.actions,
    this.tagLabel,
    this.tagStyle,
    this.progressLabel,
    this.progressValue,
  });

  final _OrderFilter filter;
  final String? tagLabel;
  final _OrderTagStyle? tagStyle;
  final String timeText;
  final String title;
  final String price;
  final String provider;
  final String packageType;
  final String orderNo;
  final String? progressLabel;
  final String? progressValue;
  final List<_OrderAction> actions;

  bool get hasProgress => progressLabel != null && progressValue != null;
}

class _OrderAction {
  const _OrderAction._({
    required this.label,
    required this.filled,
  });

  const _OrderAction.outline(String label)
      : this._(label: label, filled: false);

  const _OrderAction.filled(String label)
      : this._(label: label, filled: true);

  final String label;
  final bool filled;
}

class _OrderStatusTabs extends StatelessWidget {
  const _OrderStatusTabs({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<_OrderFilter> filters;
  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x297E868E), width: 0.5),
        ),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(filter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF096DD9)
                          : const Color(0xFF262626),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    width: 20,
                    height: 2,
                    color: isSelected
                        ? const Color(0xFF096DD9)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final _OrderItem order;

  @override
  Widget build(BuildContext context) {
    final actionButtons = order.actions
        .map((action) => _OrderActionButton(action: action))
        .toList();

    return SizedBox(
      height: order.hasProgress ? 258 : 202,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/my_orders_card_bg_blue.svg',
                fit: BoxFit.fill,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.96)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        order.timeText,
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                      const Spacer(),
                      if (order.tagLabel != null && order.tagStyle != null)
                        _OrderTag(
                          label: order.tagLabel!,
                          style: order.tagStyle!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          order.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF262626),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        order.price,
                        style: const TextStyle(
                          color: Color(0xFF262626),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 22 / 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _OrderMetaRow(label: '服务商', value: order.provider),
                  const SizedBox(height: 4),
                  _OrderMetaRow(label: '套餐类型', value: order.packageType),
                  const SizedBox(height: 4),
                  _OrderMetaRow(label: '订单号', value: order.orderNo),
                  if (order.hasProgress) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8EDF3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Color(0xFF096DD9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.progressLabel!,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              height: 18 / 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.progressValue!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 18 / 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      for (var i = 0; i < actionButtons.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 12),
                        actionButtons[i],
                      ],
                    ],
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

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTag extends StatelessWidget {
  const _OrderTag({
    required this.label,
    required this.style,
  });

  final String label;
  final _OrderTagStyle style;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = style == _OrderTagStyle.urgent
        ? const Color(0x14FF4D4F)
        : const Color(0x14096DD9);
    final foregroundColor = style == _OrderTagStyle.urgent
        ? const Color(0xFFFF4D4F)
        : const Color(0xFF096DD9);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 12 / 12,
        ),
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({required this.action});

  final _OrderAction action;

  @override
  Widget build(BuildContext context) {
    final isPayAction = action.label == '去支付';
    final backgroundColor =
        action.filled
            ? (isPayAction ? const Color(0xFFFE5815) : const Color(0xFF096DD9))
            : Colors.white;
    final borderColor =
        action.filled
            ? (isPayAction ? const Color(0xFFFE5815) : const Color(0xFF096DD9))
            : const Color(0xFFD9D9D9);
    final foregroundColor =
        action.filled ? Colors.white : const Color(0xFF262626);

    return SizedBox(
      width: 77,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            action.label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 12 / 12,
            ),
          ),
        ),
      ),
    );
  }
}
