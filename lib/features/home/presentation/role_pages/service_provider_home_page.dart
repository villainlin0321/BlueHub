import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/app_svg_icon.dart';

/// 当前按需求承载服务商首页实现，后续如补企业端首页可再拆分。
class ServiceProviderHomePage extends ConsumerWidget {
  const ServiceProviderHomePage({super.key});

  static const List<_QuickActionItem> _quickActions = <_QuickActionItem>[
    _QuickActionItem(
      label: '发布套餐',
      assetPath: 'assets/images/mon6azmx-yws4mpq.svg',
      fallback: Icons.add_box_outlined,
    ),
    _QuickActionItem(
      label: '订单处理',
      assetPath: 'assets/images/mon6azmx-b7iu27t.svg',
      fallback: Icons.fact_check_outlined,
    ),
    _QuickActionItem(
      label: '人才中心',
      assetPath: 'assets/images/mon6azmx-gxjq4wk.svg',
      fallback: Icons.school_outlined,
    ),
    _QuickActionItem(
      label: '财务结算',
      assetPath: 'assets/images/mon6azmx-tafz6au.svg',
      fallback: Icons.account_balance_wallet_outlined,
    ),
  ];

  static const List<_PendingOrderItem> _pendingOrders = <_PendingOrderItem>[
    _PendingOrderItem(
      customerName: '程*彬 (中餐厨师)',
      serviceTag: '德国工作签',
      statusText: '待审核',
      updateText: '10分钟前更新',
      materialsText: '已上传护照、技能证书…',
      priceText: '¥15,000',
    ),
    _PendingOrderItem(
      customerName: '程*彬 (中餐厨师)',
      serviceTag: '德国工作签',
      statusText: '待审核',
      updateText: '10分钟前更新',
      materialsText: '已上传护照、技能证书…',
      priceText: '¥15,000',
    ),
    _PendingOrderItem(
      customerName: '程*彬 (中餐厨师)',
      serviceTag: '德国工作签',
      statusText: '待审核',
      updateText: '10分钟前更新',
      materialsText: '已上传护照、技能证书…',
      priceText: '¥15,000',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView.separated(
      padding: EdgeInsets.only(bottom: bottomPadding + 28),
      itemCount: _pendingOrders.length + 4,
      separatorBuilder: (BuildContext context, int index) {
        if (index == 0 || index == 1 || index == 2) {
          return const SizedBox(height: 20);
        }
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const _TopHeroSection();
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _QuickActionsRow(items: _quickActions),
          );
        }
        if (index == 2) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _AiAssistantBanner(),
          );
        }
        if (index == 3) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _OrdersSectionHeader(),
          );
        }

        final _PendingOrderItem item = _pendingOrders[index - 4];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _PendingOrderCard(item: item),
        );
      },
    );
  }
}

class _TopHeroSection extends StatelessWidget {
  const _TopHeroSection();

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/mon6azmx-levpzde.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 13, 16, 76),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _StatusBarRow(),
            SizedBox(height: 10),
            _ProviderInfoRow(),
          ],
        ),
      ),
    );
  }
}

class _StatusBarRow extends StatelessWidget {
  const _StatusBarRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: 8),
        const Text(
          '10:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 19 / 16,
          ),
        ),
        const Spacer(),
        SvgPicture.asset(
          'assets/images/mon6azmx-n37s2z8.svg',
          width: 71,
          height: 12,
        ),
      ],
    );
  }
}

class _ProviderInfoRow extends StatelessWidget {
  const _ProviderInfoRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset('assets/images/mon6azmx-ecnf5h2.png', width: 40, height: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      '中欧出海签证服务',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 24 / 17,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  _CertificationBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '服务评分 4.9  累计服务 1,205',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  height: 14 / 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _MessageActionButton(),
      ],
    );
  }
}

class _CertificationBadge extends StatelessWidget {
  const _CertificationBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 47,
      height: 14,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 11,
            child: SvgPicture.asset(
              'assets/images/mon6azmx-eeohkob.svg',
              width: 36,
              height: 14,
            ),
          ),
          Positioned(
            left: 0,
            child: SvgPicture.asset(
              'assets/images/mon6azmx-2975g0p.svg',
              width: 15,
              height: 14,
            ),
          ),
          const Positioned(
            left: 18,
            top: 2,
            child: Row(
              children: <Widget>[
                Text(
                  'V',
                  style: TextStyle(
                    color: Color(0xFF784301),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 10 / 10,
                  ),
                ),
                SizedBox(width: 1),
                Text(
                  '认证',
                  style: TextStyle(
                    color: Color(0xFF784301),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 10 / 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageActionButton extends StatelessWidget {
  const _MessageActionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned.fill(
            child: AppSvgIcon(
              assetPath: 'assets/images/mon6azmx-xwxov19.svg',
              fallback: Icons.chat_bubble_outline_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 0,
            right: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF24C3D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.items});

  final List<_QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => _QuickActionButton(item: item))
          .toList(growable: false),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: item.assetPath,
                fallback: item.fallback,
                size: 24,
                color: const Color(0xFF262626),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF171A1D),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAssistantBanner extends StatelessWidget {
  const _AiAssistantBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/mon6azmx-n75bcra.svg',
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/images/mon6azmx-7balpug.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'AI业务助手',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '发现 3 个可能需要德国工签的人才',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Text(
                      '查看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 12 / 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/images/mon6azmx-wqt9b30.png',
                      width: 12,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersSectionHeader extends StatelessWidget {
  const _OrdersSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            '待处理订单',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
        ),
        const Text(
          '全部',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 2),
        Image.asset('assets/images/mon6azmx-ic3gin6.png', width: 16, height: 16),
      ],
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  const _PendingOrderCard({required this.item});

  final _PendingOrderItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child:           Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        item.customerName,
                        style: const TextStyle(
                          color: Color(0xFF262626),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                        ),
                      ),
                      _OutlineTag(label: item.serviceTag),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusTag(label: item.statusText),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  item.updateText,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.materialsText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  item.priceText,
                  style: const TextStyle(
                    color: Color(0xFFFE5815),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                ),
                const Spacer(),
                const _GhostActionButton(label: '联系客户'),
                const SizedBox(width: 8),
                const _PrimaryActionButton(label: '审核材料'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineTag extends StatelessWidget {
  const _OutlineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 10,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFF4D4F),
          fontSize: 11,
          height: 12 / 11,
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

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.assetPath,
    required this.fallback,
  });

  final String label;
  final String assetPath;
  final IconData fallback;
}

class _PendingOrderItem {
  const _PendingOrderItem({
    required this.customerName,
    required this.serviceTag,
    required this.statusText,
    required this.updateText,
    required this.materialsText,
    required this.priceText,
  });

  final String customerName;
  final String serviceTag;
  final String statusText;
  final String updateText;
  final String materialsText;
  final String priceText;
}
