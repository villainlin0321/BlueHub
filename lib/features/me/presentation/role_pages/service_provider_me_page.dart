import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../auth/application/auth_session_provider.dart';
import '../../../auth/presentation/qualification_certification_flow.dart';
import '../../../me/presentation/current_user_view_data.dart';
import '../../../visa/data/provider_models.dart';
import '../../../visa/data/provider_providers.dart';

final _currentProviderProfileProvider = FutureProvider.autoDispose<ProviderVO>((
  ref,
) async {
  final service = ref.watch(providerServiceProvider);
  return service.getMyProfile();
});

/// 服务商端个人中心，按 Figma 设计图还原。
class ServiceProviderMePage extends StatelessWidget {
  const ServiceProviderMePage({super.key});

  static const String _headerBgAsset = 'assets/images/mou588hj-8pcermw.png';
  static const String _avatarAsset = 'assets/images/mou588hj-vpl779h.png';
  static const String _messageAsset = 'assets/images/mou588hj-ehihl8o.svg';
  static const String _settingsAsset = 'assets/images/mou4gf12-hem78nx.svg';
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
    if (label == '资质管理') {
      context.push(
        RoutePaths.qualificationCertification,
        extra: QualificationCertificationPageArgs(
          role: QualificationCertificationRole.serviceProvider,
        ),
      );
      return;
    }
    if (label == '订单管理') {
      context.push(RoutePaths.orderManagement);
      return;
    }
    _showPlaceholderToast(context, label);
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
          onTap: () => context.push(RoutePaths.messageCenter),
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

class _ProviderProfileRow extends ConsumerWidget {
  const _ProviderProfileRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProviderVO? providerProfile =
        ref.watch(_currentProviderProfileProvider).asData?.value;
    final String providerSummary = providerProfile == null
        ? ''
        : '服务评分 ${_formatProviderRating(providerProfile.rating)}  累计服务 ${_formatProviderCaseCount(providerProfile.caseCount)}';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _ProviderNameRow(),
                if (providerSummary.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    providerSummary,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 14 / 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Opacity(
            opacity: 0.7,
            child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ProviderNameRow extends ConsumerWidget {
  const _ProviderNameRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CurrentUserViewData userViewData = CurrentUserViewData.fromAuthUser(
      ref.watch(authSessionProvider).user,
    );
    final ProviderVO? providerProfile =
        ref.watch(_currentProviderProfileProvider).asData?.value;
    final String providerName = providerProfile?.name.trim() ?? '';
    final String displayName = providerName.isNotEmpty
        ? providerName
        : userViewData.nickname;
    final bool isVerified = providerProfile?.isVerified ?? false;

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 24 / 17,
            ),
          ),
        ),
        if (isVerified) ...<Widget>[
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

String _formatProviderRating(double value) => value.toStringAsFixed(2);

String _formatProviderCaseCount(int value) {
  final String digits = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    final int reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
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
