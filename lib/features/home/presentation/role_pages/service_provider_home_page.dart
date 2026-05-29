import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../features/auth/application/auth_session_provider.dart';
import '../../../../features/me/presentation/current_user_view_data.dart';
import '../../../../features/order/data/visa_order_models.dart'
    show MaterialVO, VisaOrderVO;
import '../../../../features/visa/data/provider_models.dart' show VisaProviderProfileVO;
import '../../../../features/visa/data/provider_providers.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/message_center_icon_button.dart';
import '../../data/home_models.dart';
import '../../data/home_providers.dart';

final _currentProviderProfileProvider =
    FutureProvider.autoDispose<VisaProviderProfileVO>((ref) async {
  final service = ref.watch(providerServiceProvider);
  return service.getMyProfile();
});

/// 当前按需求承载服务商首页实现，后续如补企业端首页可再拆分。
class ServiceProviderHomePage extends ConsumerWidget {
  const ServiceProviderHomePage({super.key});

  static const List<_QuickActionItem> _quickActions = <_QuickActionItem>[
    _QuickActionItem(
      label: '发布套餐',
      assetPath: 'assets/images/mon6azmx-yws4mpq.svg',
      fallback: Icons.add_box_outlined,
      routePath: RoutePaths.editVisaPackage,
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
      routePath: RoutePaths.financeSettlement,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _TopHeroSection(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _QuickActionsRow(items: _quickActions),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _AiAssistantBanner(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _OrdersSectionHeader(),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _PendingOrdersSection(),
          ),
        ],
      ),
    );
  }
}

class _TopHeroSection extends StatelessWidget {
  const _TopHeroSection();

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topPadding + 128,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          gradient: LinearGradient(
            begin: Alignment(-0.78, -1.0),
            end: Alignment(0.85, 1.0),
            colors: <Color>[Color(0xFF3F9BF7), Color(0xFF2F73E5)],
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned(
                left: -35,
                top: 8,
                child: _HeroGlow(width: 445, height: 129),
              ),
              Positioned(
                left: -12,
                right: -12,
                bottom: 0,
                child: Opacity(
                  opacity: 0.16,
                  child: Image.asset(
                    'assets/images/mon6azmx-levpzde.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: topPadding,
                left: 16,
                right: 16,
                child: const SizedBox(height: 52, child: _ProviderInfoRow()),
              ),
              const Positioned(
                left: 13,
                right: 14,
                bottom: 20,
                child: _HeroStatsRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 44.85, sigmaY: 44.85),
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.75, -1.0),
              end: Alignment(0.85, 1.0),
              colors: <Color>[Color(0xFF079EE9), Color(0xFF096DD9)],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatsRow extends ConsumerWidget {
  const _HeroStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeDashboardStatsVO? stats = ref
        .watch(homeDashboardStatsProvider)
        .asData
        ?.value;
    final List<_HeroStatItem> items = stats == null
        ? const <_HeroStatItem>[]
        : <_HeroStatItem>[
            _HeroStatItem(
              value: _formatProviderCount(stats.todayConsultations),
              label: '今日咨询',
            ),
            _HeroStatItem(
              value: _formatProviderCount(stats.inProgressOrders),
              label: '进行中订单',
            ),
            _HeroStatItem(
              value: stats.monthlyIncomeDisplay,
              label: '本月收入(${stats.incomeCurrencySymbol})',
            ),
          ];

    return Row(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          Expanded(child: items[index]),
          if (index != items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 24 / 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

class _ProviderInfoRow extends ConsumerWidget {
  const _ProviderInfoRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CurrentUserViewData userViewData = CurrentUserViewData.fromAuthUser(
      ref.watch(authSessionProvider).user,
    );
    final AsyncValue<VisaProviderProfileVO> providerProfileAsync = ref.watch(
      _currentProviderProfileProvider,
    );
    final VisaProviderProfileVO? providerProfile =
        providerProfileAsync.asData?.value;
    final String providerName = providerProfile?.companyName.trim() ?? '';
    final String displayName = providerName.isNotEmpty
        ? providerName
        : userViewData.nickname;
    final bool isVerified = providerProfile?.isVerified ?? false;
    final String providerSummary = providerProfile == null
        ? ''
        : '服务评分 ${_formatProviderRating(providerProfile.rating)}  累计服务 ${_formatProviderCaseCount(providerProfile.caseCount)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'assets/images/mon6azmx-ecnf5h2.png',
          width: 40,
          height: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
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
                    const SizedBox(width: 6),
                    const _CertificationBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (providerSummary.isNotEmpty)
                Text(
                  providerSummary,
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
        const MessageCenterIconButton(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.routePath == null
            ? null
            : () => context.push(item.routePath!),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
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
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      '查看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    SvgPicture.asset(
                      'assets/images/chat_page_order_arrow.svg',
                      width: 12,
                      height: 12,
                      color: Colors.white,
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
        const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF8C8C8C)),
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
      child: Padding(
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

class _PendingOrdersSection extends ConsumerWidget {
  const _PendingOrdersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VisaOrderVO>> ordersAsync = ref.watch(
      serviceProviderReviewingOrdersProvider,
    );

    return ordersAsync.when(
      loading: () => const _PendingOrdersStateView(
        icon: Icons.hourglass_empty_rounded,
        message: '待审核订单加载中',
      ),
      error: (Object error, StackTrace stackTrace) => _PendingOrdersStateView(
        icon: Icons.cloud_off_rounded,
        message: '待审核订单加载失败，请稍后重试',
        buttonLabel: '重新加载',
        onTap: () => ref.refresh(serviceProviderReviewingOrdersProvider),
      ),
      data: (List<VisaOrderVO> orders) {
        if (orders.isEmpty) {
          return const _PendingOrdersStateView(
            icon: Icons.receipt_long_outlined,
            message: '暂无待审核订单',
          );
        }

        final List<_PendingOrderItem> items = orders
            .map(_PendingOrderItem.fromVisaOrder)
            .toList(growable: false);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            return _PendingOrderCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _PendingOrdersStateView extends StatelessWidget {
  const _PendingOrdersStateView({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 40, color: const Color(0xFFBFBFBF)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          if (buttonLabel != null && onTap != null) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF096DD9),
              ),
              child: Text(buttonLabel!),
            ),
          ],
        ],
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
    this.routePath,
  });

  final String label;
  final String assetPath;
  final IconData fallback;
  final String? routePath;
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

  factory _PendingOrderItem.fromVisaOrder(VisaOrderVO order) {
    return _PendingOrderItem(
      customerName: _displayCustomerName(order),
      serviceTag: _displayServiceTag(order),
      statusText: _displayStatusText(order),
      updateText: _formatOrderUpdatedText(order.updatedAt),
      materialsText: _buildMaterialsText(order),
      priceText: _formatOrderAmount(order.amount),
    );
  }
}

String _formatProviderCount(int? value) => (value ?? 0).toString();

String _formatProviderRating(double value) => value.toStringAsFixed(1);

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

String _displayCustomerName(VisaOrderVO order) {
  final String nickname = order.nickname.trim();
  return nickname.isEmpty ? '订单客户' : nickname;
}

String _displayServiceTag(VisaOrderVO order) {
  final String packageName = order.packageName.trim();
  if (packageName.isNotEmpty) {
    return packageName;
  }
  final String tierName = order.tierName.trim();
  return tierName.isEmpty ? '签证服务' : tierName;
}

String _displayStatusText(VisaOrderVO order) {
  final String statusLabel = order.statusLabel.trim();
  if (statusLabel.isNotEmpty) {
    return statusLabel;
  }
  final String status = order.status.trim();
  return status.isEmpty ? '待审核' : status;
}

String _buildMaterialsText(VisaOrderVO order) {
  final List<String> names = order.materials
      .map<String>((MaterialVO item) => item.materialName.trim())
      .where((String name) => name.isNotEmpty)
      .take(3)
      .toList(growable: false);
  if (names.isEmpty) {
    return '暂未上传材料';
  }
  return '已上传${names.join('、')}';
}

String _formatOrderUpdatedText(String raw) {
  final DateTime? updatedAt = DateTime.tryParse(raw)?.toLocal();
  if (updatedAt == null) {
    return raw.trim().isEmpty ? '刚刚更新' : raw;
  }

  final Duration difference = DateTime.now().difference(updatedAt);
  if (difference.inMinutes < 1) {
    return '刚刚更新';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}分钟前更新';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}小时前更新';
  }
  return '${updatedAt.month}月${updatedAt.day}日更新';
}

String _formatOrderAmount(double amount) {
  final bool hasFraction = amount % 1 != 0;
  final String raw = hasFraction
      ? amount.toStringAsFixed(2)
      : amount.toStringAsFixed(0);
  final List<String> parts = raw.split('.');
  final String integerPart = parts.first;
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < integerPart.length; index++) {
    final int reverseIndex = integerPart.length - index;
    buffer.write(integerPart[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  if (parts.length == 2 && parts[1].isNotEmpty && parts[1] != '00') {
    return '¥${buffer.toString()}.${parts[1]}';
  }
  return '¥${buffer.toString()}';
}
