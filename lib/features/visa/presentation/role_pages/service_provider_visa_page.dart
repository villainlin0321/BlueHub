import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 服务商签证页。
class ServiceProviderVisaPage extends StatelessWidget {
  const ServiceProviderVisaPage({super.key});

  static const List<_FilterItem> _filters = <_FilterItem>[
    _FilterItem(label: '全部国家'),
    _FilterItem(label: '订单状态'),
  ];

  static const List<_OrderCardData> _orders = <_OrderCardData>[
    _OrderCardData(
      orderNo: 'SJEH9823964875',
      customerName: '程*彬',
      visaTitle: '德国厨师工签',
      price: '¥15,000',
      updateTime: '10分钟前更新',
      status: '待审核',
      statusType: _OrderStatusType.danger,
      avatarAssetPath: 'assets/images/visa/mon8ysqa-s0y5kqs.png',
      urgentTag: '紧急',
    ),
    _OrderCardData(
      orderNo: 'SJEH9823964875',
      customerName: '程*彬',
      visaTitle: '法国建筑工签',
      price: '¥22,000',
      updateTime: '2小时前更新',
      status: '待用户上传材料',
      statusType: _OrderStatusType.info,
      avatarAssetPath: 'assets/images/visa/mon8ysqa-s0y5kqs.png',
    ),
    _OrderCardData(
      orderNo: 'SJEH9823964875',
      customerName: '程*彬',
      visaTitle: '法国建筑工签',
      price: '¥15,000',
      updateTime: '2小时前更新',
      status: '使馆审核中',
      statusType: _OrderStatusType.info,
      avatarAssetPath: 'assets/images/visa/mon8ysqa-s0y5kqs.png',
    ),
    _OrderCardData(
      orderNo: 'SJEH9823964875',
      customerName: '程*彬',
      visaTitle: '法国建筑工签',
      price: '¥15,000',
      updateTime: '2小时前更新',
      status: '待付款',
      statusType: _OrderStatusType.info,
      avatarAssetPath: 'assets/images/visa/mon8ysqa-s0y5kqs.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _OrderTopSection(topPadding: topPadding),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 7, 0, 7),
            child: Row(
              children: _filters
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 11),
                      child: _OrderFilterChip(item: item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orders.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return _OrderCard(data: _orders[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTopSection extends StatelessWidget {
  const _OrderTopSection({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, topPadding, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '订单',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 24 / 17,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/images/visa/mon8ysqa-n6jz78w.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({required this.item});

  final _FilterItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.label,
            style: const TextStyle(
              color: Color(0xFF171A1D),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(width: 6),
          Image.asset(
            'assets/images/visa/mon8ysqa-i6uxhdr.png',
            width: 12,
            height: 12,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.data});

  final _OrderCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                      children: <InlineSpan>[
                        const TextSpan(text: '订单号：'),
                        TextSpan(text: data.orderNo),
                      ],
                    ),
                  ),
                ),
                _OrderStatusChip(label: data.status, type: data.statusType),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Image.asset(data.avatarAssetPath, width: 40, height: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            data.customerName,
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 24 / 16,
                            ),
                          ),
                          if (data.urgentTag != null) ...<Widget>[
                            const SizedBox(width: 6),
                            _UrgentChip(label: data.urgentTag!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.visaTitle,
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.price,
                  style: const TextStyle(
                    color: Color(0xFFFE5815),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  data.updateTime,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
                const Spacer(),
                const _GhostActionButton(label: '联系客户'),
                const SizedBox(width: 8),
                const _PrimaryActionButton(label: '处理订单'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.label, required this.type});

  final String label;
  final _OrderStatusType type;

  @override
  Widget build(BuildContext context) {
    final bool isDanger = type == _OrderStatusType.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDanger ? const Color(0xFFFFEBEB) : const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDanger ? const Color(0xFFFF4D4F) : const Color(0xFF386EF8),
          fontSize: 11,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class _UrgentChip extends StatelessWidget {
  const _UrgentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF6661)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFF0B03),
          fontSize: 10,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF096DD9),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.label});

  final String label;
}

class _OrderCardData {
  const _OrderCardData({
    required this.orderNo,
    required this.customerName,
    required this.visaTitle,
    required this.price,
    required this.updateTime,
    required this.status,
    required this.statusType,
    required this.avatarAssetPath,
    this.urgentTag,
  });

  final String orderNo;
  final String customerName;
  final String visaTitle;
  final String price;
  final String updateTime;
  final String status;
  final _OrderStatusType statusType;
  final String avatarAssetPath;
  final String? urgentTag;
}

enum _OrderStatusType { danger, info }
