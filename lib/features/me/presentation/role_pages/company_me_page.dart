import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

/// 企业端我的页，按 Figma 设计图还原。
class CompanyMePage extends StatelessWidget {
  const CompanyMePage({super.key});

  static const String _messageAsset = 'assets/images/mou64ult-r2vhiam.svg';
  static const String _settingsAsset = 'assets/images/mou64ult-u3ktrfm.svg';
  static const String _avatarAsset = 'assets/images/mou64ult-sj15mxj.png';

  static const List<_StatData> _stats = <_StatData>[
    _StatData(value: '88', label: '再招岗位'),
    _StatData(value: '24', label: '收到简历'),
    _StatData(value: '1.2k', label: '待面试'),
    _StatData(value: '4.87', label: '已录用'),
  ];

  static const List<_MenuData> _menus = <_MenuData>[
    _MenuData(
      label: '企业资质',
      iconAsset: 'assets/images/mou64ult-bsnw92y.svg',
      fallbackIcon: Icons.assignment_ind_outlined,
    ),
    _MenuData(
      label: '应聘管理',
      iconAsset: 'assets/images/mou64ulu-ebnjjum.svg',
      fallbackIcon: Icons.business_center_outlined,
    ),
    _MenuData(
      label: '人才中心',
      iconAsset: 'assets/images/mou64ulu-1l37egn.svg',
      fallbackIcon: Icons.groups_outlined,
    ),
    _MenuData(
      label: '签证服务',
      iconAsset: 'assets/images/mou64ult-83t4ndy.svg',
      fallbackIcon: Icons.public_outlined,
    ),
    _MenuData(
      label: '订单管理',
      iconAsset: 'assets/images/mou64ulu-l17h9p8.svg',
      fallbackIcon: Icons.checklist_rounded,
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
          const _CompanyHeaderSection(),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MenuCard(
              items: _menus,
              onTap: (String label) => _handleMenuTap(context, label),
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

  void _handleMenuTap(BuildContext context, String label) {
    if (label == '应聘管理') {
      context.push(RoutePaths.companyApplications);
      return;
    }
    _showPlaceholderToast(context, label);
  }
}

class _CompanyHeaderSection extends StatelessWidget {
  const _CompanyHeaderSection();

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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF3F9BF7), Color(0xFF2F73E5)],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: -36,
                  top: -36,
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[Color(0xFF1FDAFF), Color(0x003584EC)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -52,
                  bottom: -56,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[Color(0xFF456DFF), Color(0x003584EC)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: topPadding + 14,
                  right: 16,
                  // 关键修复：顶部内容仅按自身高度布局，避免固定底部留白把可用高度挤爆。
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _HeaderActions(),
                      SizedBox(height: 10),
                      _CompanyProfileRow(),
                    ],
                  ),
                ),
              ],
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
  /// 构建头部右上角操作区，并把设置按钮接入真实设置页路由。
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Spacer(),
        _TopIconButton(
          assetPath: CompanyMePage._messageAsset,
          fallbackIcon: Icons.chat_bubble_outline,
          onTap: () => _showPlaceholderToast(context, '消息中心'),
        ),
        const SizedBox(width: 16),
        _TopIconButton(
          assetPath: CompanyMePage._settingsAsset,
          fallbackIcon: Icons.settings_outlined,
          onTap: () => context.push(RoutePaths.settings),
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

class _CompanyProfileRow extends StatelessWidget {
  const _CompanyProfileRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('企业资料（占位）')));
      },
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: <Widget>[
          Image.asset(
            CompanyMePage._avatarAsset,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _CompanyInfo()),
                SizedBox(width: 12),
                _CompanyBadge(),
              ],
            ),
          ),
          const Opacity(
            opacity: 0.8,
            child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CompanyInfo extends StatelessWidget {
  const _CompanyInfo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '柏林老四川餐厅',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 20 / 17,
          ),
        ),
        SizedBox(height: 6),
        Row(
          children: <Widget>[
            Text(
              '餐饮行业',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 14 / 11,
              ),
            ),
            SizedBox(width: 8),
            _VerticalDivider(),
            SizedBox(width: 8),
            Text(
              '德国·柏林',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 14 / 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.65,
      child: Container(width: 1, height: 9, color: Colors.white),
    );
  }
}

class _CompanyBadge extends StatelessWidget {
  const _CompanyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFF6C165),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        '企',
        style: TextStyle(
          color: Color(0xFF784301),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 10 / 9,
        ),
      ),
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
        children: CompanyMePage._stats
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
              child: item.label == '签证服务'
                  ? const _VisaServiceIcon()
                  : SvgPicture.asset(
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFBFBFBF),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisaServiceIcon extends StatelessWidget {
  const _VisaServiceIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF262626), width: 1.6),
          ),
        ),
        SvgPicture.asset(
          'assets/images/mou64ulu-4e3m1j7.svg',
          width: 18,
          height: 1,
        ),
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF262626), width: 1.6),
          ),
        ),
      ],
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
