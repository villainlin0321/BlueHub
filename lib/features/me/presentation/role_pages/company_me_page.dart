import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../../../shared/widgets/message_center_icon_button.dart';
import '../../../employer/data/employer_models.dart';
import '../../../employer/data/employer_providers.dart';
import '../../../auth/presentation/qualification_certification_flow.dart';
import '../../../home/data/home_models.dart';
import '../../../home/data/home_providers.dart';
import '../country_options_bottom_sheet.dart';

import 'package:europepass/shared/ui/test_style.dart';
final _currentEmployerProfileProvider =
    FutureProvider.autoDispose<EmployerProfileVO>((ref) async {
      final service = ref.watch(employerServiceProvider);
      return service.getEmployerProfile();
    });

/// 企业端我的页，按 Figma 设计图还原。
class CompanyMePage extends ConsumerWidget {
  const CompanyMePage({super.key});

  static const String _headerBackgroundAsset =
      'assets/images/company_me_header_bg_figma.svg';
  static const String _settingsAsset = 'assets/images/mou4gf12-hem78nx.svg';
  static const String _avatarAsset = 'assets/images/mou64ult-sj15mxj.png';

  static const List<_StatData> _stats = <_StatData>[
    _StatData(value: '88', labelKey: '我的.在招岗位'),
    _StatData(value: '24', labelKey: '我的.收到简历'),
    _StatData(value: '1.2k', labelKey: '我的.待面试'),
    _StatData(value: '4.87', labelKey: '我的.已录用'),
  ];

  static const List<_MenuData> _menus = <_MenuData>[
    _MenuData(
      labelKey: '我的.企业资质',
      iconAsset: 'assets/images/company_me_menu_qualification_figma.svg',
      fallbackIcon: Icons.assignment_ind_outlined,
    ),
    _MenuData(
      labelKey: '我的.应聘管理',
      iconAsset: 'assets/images/company_me_menu_application_figma.svg',
      fallbackIcon: Icons.business_center_outlined,
      iconRenderSize: 20,
    ),
    _MenuData(
      labelKey: '我的.人才中心',
      iconAsset: 'assets/images/company_me_menu_talent_figma.svg',
      fallbackIcon: Icons.groups_outlined,
    ),
    _MenuData(
      labelKey: '我的.订单管理',
      iconAsset: 'assets/images/company_me_menu_order_figma.svg',
      fallbackIcon: Icons.checklist_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _CompanyHeaderSection(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MenuCard(
              items: _menus,
              onTap: (String label) => _handleMenuTap(context, ref, label),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuTap(
    BuildContext context,
    WidgetRef ref,
    String label,
  ) async {
    if (label == '我的.企业资质') {
      await _openQualificationCertification(context, ref);
      return;
    }
    if (label == '我的.订单管理') {
      context.push(RoutePaths.orderManagement);
      return;
    }
    if (label == '我的.应聘管理') {
      context.push(RoutePaths.companyApplications);
      return;
    }
    if (label == '我的.人才中心') {
      context.go(RoutePaths.jobs);
      return;
    }
  }

  Future<void> _openQualificationCertification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final profile = await ref.read(_currentEmployerProfileProvider.future);
      final countries = await loadCountries(ref);
      final draft = QualificationCertificationDraft()
        ..fillFromEmployerProfile(
          profile,
          countryLabelMap: buildCountryLabelMap(countries),
        );
      if (!context.mounted) {
        return;
      }
      context.push(
        RoutePaths.qualificationCertification,
        extra: QualificationCertificationPageArgs(
          role: QualificationCertificationRole.company,
          draft: draft,
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final String message = error is ApiException
          ? error.message
          : '我的.资料加载失败'.tr();
      AppToast.show(message);
    }
  }
}

class _CompanyHeaderSection extends StatelessWidget {
  const _CompanyHeaderSection();

  static const double _figmaSafeAreaHeight = 44;
  static const double _figmaTotalHeight = 220;
  static const double _statCardHeight = 88;
  static const double _statCardOffset = 26;

  /// 构建企业端“我的”页面头部，按设计稿 220 总高重排蓝底与统计卡。
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double contentHeight = _figmaTotalHeight - _figmaSafeAreaHeight;
    final double headerHeight = topPadding + contentHeight;
    final double totalHeaderHeight = headerHeight + _statCardOffset;

    return SizedBox(
      height: totalHeaderHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    // 直接使用 Figma 头部背景切图，避免代码渐变带来的色差。
                    child: SvgPicture.asset(
                      CompanyMePage._headerBackgroundAsset,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: topPadding + 10,
                    right: 16,
                    // 企业资料区与统计卡拉开距离，同时名称与副信息间距按设计稿收紧。
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _HeaderActions(),
                        SizedBox(height: 8),
                        _CompanyProfileRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SizedBox(height: _statCardHeight, child: _StatCard()),
          ),
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
        const MessageCenterIconButton(),
        const SizedBox(width: 12),
        _TopIconButton(
          assetPath: CompanyMePage._settingsAsset,
          fallbackIcon: Icons.settings_outlined,
          onTap: () => context.push(RoutePaths.settings),
        ),
      ],
    );
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
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            placeholderBuilder: (_) =>
                Icon(fallbackIcon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _CompanyProfileRow extends ConsumerWidget {
  const _CompanyProfileRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmployerProfileVO? profile = ref
        .watch(_currentEmployerProfileProvider)
        .asData
        ?.value;
    final bool isVerified = profile?.isVerified ?? true;

    return InkWell(
      onTap: () {
        context.push(RoutePaths.companyMyInfo);
      },
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: <Widget>[
          AppUserAvatar(
            imageUrl: profile?.logoUrl ?? '',
            size: 40,
            placeholderAssetPath: CompanyMePage._avatarAsset,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _CompanyInfo(profile: profile)),
                if (isVerified) ...<Widget>[
                  const SizedBox(width: 12),
                  const _CompanyBadge(),
                ],
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
  const _CompanyInfo({this.profile});

  final EmployerProfileVO? profile;

  @override
  Widget build(BuildContext context) {
    final String companyName = _buildCompanyName(profile);
    final String industry = _buildIndustry(profile);
    final String location = _buildLocation(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          companyName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TestStyle.semibold(fontSize: 17, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Text(
              industry,
              style: TestStyle.regular(fontSize: 11, color: Colors.white),
            ),
            if (location.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              const _VerticalDivider(),
              const SizedBox(width: 8),
              Text(
                location,
                style: TestStyle.regular(fontSize: 11, color: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _buildCompanyName(EmployerProfileVO? profile) {
    final String name = profile?.companyName.trim() ?? '';
    return name.isEmpty ? '我的.企业名称待完善'.tr() : name;
  }

  String _buildIndustry(EmployerProfileVO? profile) {
    final String industry = profile?.industry.trim() ?? '';
    return industry.isEmpty ? '我的.行业待完善'.tr() : industry;
  }

  String _buildLocation(EmployerProfileVO? profile) {
    final List<String> parts = <String>[
      profile?.country.trim() ?? '',
      profile?.city.trim() ?? '',
    ].where((String item) => item.isNotEmpty).toList(growable: false);
    return parts.join('·');
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
      child: Text(
        '通用.企业简称'.tr(),
        style: TestStyle.pingFangSemibold(fontSize: 9, color: Color(0xFF784301)),
      ),
    );
  }
}

class _StatCard extends ConsumerWidget {
  const _StatCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeDashboardStatsVO? stats = ref
        .watch(homeDashboardStatsProvider)
        .asData
        ?.value;
    final List<_StatData> items = stats == null
        ? CompanyMePage._stats
        : <_StatData>[
            _StatData(
              value: _formatCompanyCount(stats.activeJobs),
              labelKey: '我的.在招岗位',
            ),
            _StatData(
              value: _formatCompanyCount(stats.receivedResumes),
              labelKey: '我的.收到简历',
            ),
            _StatData(
              value: _formatCompanyCount(stats.pendingInterviews),
              labelKey: '我的.待面试',
            ),
            _StatData(
              value: _formatCompanyCount(stats.hired),
              labelKey: '我的.已录用',
            ),
          ];

    return Container(
      height: 88,
      // 在保持卡片总高 88 不变的前提下，收紧上下留白以容纳更大的数字字号。
      padding: const EdgeInsets.fromLTRB(9, 16, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (_StatData item) => Expanded(
                child: _StatItem(value: item.value, label: item.labelKey.tr()),
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
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          style: TestStyle.semibold(fontSize: 20, color: Color(0xFF262626)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TestStyle.regular(fontSize: 12, color: Color(0xFF595959)),
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
                  _MenuTile(item: item, onTap: () => onTap(item.labelKey)),
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
              child: Center(
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: item.iconRenderSize,
                  height: item.iconRenderSize,
                  placeholderBuilder: (_) => Icon(
                    item.fallbackIcon,
                    size: item.iconRenderSize,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.labelKey.tr(),
                style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
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
  const _StatData({required this.value, required this.labelKey});

  final String value;
  final String labelKey;
}

String _formatCompanyCount(int? value) => (value ?? 0).toString();

class _MenuData {
  const _MenuData({
    required this.labelKey,
    required this.iconAsset,
    required this.fallbackIcon,
    this.iconRenderSize = 24,
  });

  final String labelKey;
  final String iconAsset;
  final IconData fallbackIcon;
  final double iconRenderSize;
}
