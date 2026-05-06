import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 服务商端个人中心，按 Figma 设计图还原。
class ServiceProviderMePage extends StatelessWidget {
  const ServiceProviderMePage({super.key});

  static const String _headerBgAsset = 'assets/images/mou588hj-8pcermw.png';
  static const String _avatarAsset = 'assets/images/mou588hj-vpl779h.png';
  static const String _chevronAsset = 'assets/images/mou588hj-xcqwdgc.png';
  static const String _menuChevronAsset = 'assets/images/mou588hj-hrfxjua.png';
  static const String _messageAsset = 'assets/images/mou588hj-ehihl8o.svg';
  static const String _settingsAsset = 'assets/images/mou588hj-ycjdz35.svg';
  static const String _badgeBgAsset = 'assets/images/mou588hj-umrxyv9.svg';
  static const String _badgeVAsset = 'assets/images/mou588hj-j0ju7dc.svg';

  static const List<_StatData> _stats = <_StatData>[
    _StatData(value: '88', label: '待处理订单'),
    _StatData(value: '24', label: '已上架套餐'),
    _StatData(value: '1.2k', label: '累计服务'),
    _StatData(value: '4.87', label: '综合评分'),
  ];

  static const List<_MenuData> _menus = <_MenuData>[
    _MenuData(
      label: '资质管理',
      iconAsset: 'assets/images/mou588hj-xulqbsk.svg',
      fallbackIcon: Icons.assignment_ind_outlined,
    ),
    _MenuData(
      label: '订单管理',
      iconAsset: 'assets/images/mou588hj-2n6zjy8.svg',
      fallbackIcon: Icons.checklist_rounded,
    ),
    _MenuData(
      label: '财务结算',
      iconAsset: 'assets/images/mou588hj-e95qx7y.svg',
      fallbackIcon: Icons.currency_yen_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _HeaderSection(),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MenuCard(
              items: _menus,
              onTap: (String label) => _showPlaceholderToast(context, label),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceholderToast(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label（占位）')));
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: 248,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            height: 220,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              image: DecorationImage(
                image: AssetImage(ServiceProviderMePage._headerBgAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 80),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _HeaderActions(),
                  SizedBox(height: 10),
                  _ProviderProfileRow(),
                ],
              ),
            ),
          ),
          const Positioned(left: 12, right: 12, bottom: 0, child: _StatCard()),
        ],
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Spacer(),
        _TopIconButton(
          assetPath: ServiceProviderMePage._messageAsset,
          fallbackIcon: Icons.chat_bubble_outline,
          onTap: () => _showPlaceholderToast(context, '消息中心'),
        ),
        const SizedBox(width: 16),
        _TopIconButton(
          assetPath: ServiceProviderMePage._settingsAsset,
          fallbackIcon: Icons.settings_outlined,
          onTap: () => _showPlaceholderToast(context, '设置'),
        ),
      ],
    );
  }

  void _showPlaceholderToast(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label（占位）')));
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: 19,
            height: 19,
            placeholderBuilder: (_) =>
                Icon(fallbackIcon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ProviderProfileRow extends StatelessWidget {
  const _ProviderProfileRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('机构资料（占位）')));
      },
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: <Widget>[
          Image.asset(
            ServiceProviderMePage._avatarAsset,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ProviderNameRow(),
                SizedBox(height: 4),
                Text(
                  '服务评分 4.9  累计服务 1,205',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 14 / 11,
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: 0.7,
            child: Image.asset(
              ServiceProviderMePage._chevronAsset,
              width: 16,
              height: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderNameRow extends StatelessWidget {
  const _ProviderNameRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Flexible(
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
        const SizedBox(width: 8),
        SizedBox(
          width: 47,
          height: 14,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 11,
                right: 0,
                top: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  ServiceProviderMePage._badgeBgAsset,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: SvgPicture.asset(
                  ServiceProviderMePage._badgeVAsset,
                  width: 15,
                  height: 14,
                ),
              ),
              const Positioned(
                left: 18,
                top: 2,
                child: Text(
                  '认证',
                  style: TextStyle(
                    color: Color(0xFF784301),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 10 / 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(9, 20, 10, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ServiceProviderMePage._stats
            .map(
              (_StatData item) => Expanded(
                child: _StatItem(value: item.value, label: item.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 20 / 18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 12,
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onTap});

  final List<_MenuData> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items
            .map(
              (_MenuData item) =>
                  _MenuTile(item: item, onTap: () => onTap(item.label)),
            )
            .toList(),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onTap});

  final _MenuData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                item.iconAsset,
                width: 24,
                height: 24,
                placeholderBuilder: (_) => Icon(
                  item.fallbackIcon,
                  size: 22,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                ),
              ),
            ),
            Image.asset(
              ServiceProviderMePage._menuChevronAsset,
              width: 16,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({required this.value, required this.label});

  final String value;
  final String label;
}

class _MenuData {
  const _MenuData({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
  });

  final String label;
  final String iconAsset;
  final IconData fallbackIcon;
}
