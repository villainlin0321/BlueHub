import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../auth/presentation/qualification_certification_flow.dart';
import '../../employer/data/employer_models.dart';
import '../../employer/data/employer_providers.dart';
import '../data/dictionary_providers.dart';
import 'company_my_info_styles.dart';
import 'country_options_bottom_sheet.dart';
import 'widgets/company_my_info_widgets.dart';

final _companyMyInfoProfileProvider =
    FutureProvider.autoDispose<EmployerProfileVO>((ref) async {
      final service = ref.watch(employerServiceProvider);
      return service.getEmployerProfile();
    });

/// 企业端“我的信息”页，按 Figma 设计展示企业基础资料与材料资质。
class CompanyMyInfoPage extends ConsumerWidget {
  const CompanyMyInfoPage({super.key});

  static const String _avatarFallbackAsset = 'assets/images/mou64ult-sj15mxj.png';
  static const String _qualificationPlaceholderAsset =
      'assets/images/qualification_license_placeholder.png';
  static const String _noteText =
      '注意：修改企业信息后需要重新提交审核，请确保xxxx当前业务是否都处理完成。';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EmployerProfileVO> profileAsync = ref.watch(
      _companyMyInfoProfileProvider,
    );
    final Map<String, String> countryLabelMap = ref
        .watch(countrySearchProvider(const CountrySearchQuery()))
        .maybeWhen(
          data: (result) => buildCountryLabelMap(result.list),
          orElse: () => const <String, String>{},
        );

    return Scaffold(
      backgroundColor: CompanyMyInfoStyles.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            CompanyMyInfoHeader(onBackTap: context.pop),
            Expanded(
              child: profileAsync.when(
                data: (EmployerProfileVO profile) => _CompanyMyInfoContent(
                  profile: profile,
                  countryLabelMap: countryLabelMap,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _CompanyMyInfoErrorView(
                  onRetry: () => ref.invalidate(_companyMyInfoProfileProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyMyInfoContent extends StatelessWidget {
  const _CompanyMyInfoContent({
    required this.profile,
    required this.countryLabelMap,
  });

  final EmployerProfileVO profile;
  final Map<String, String> countryLabelMap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        CompanyMyInfoStyles.pageHorizontalPadding,
        12,
        CompanyMyInfoStyles.pageHorizontalPadding,
        bottomInset + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CompanyMyInfoSectionCard(
            title: '基础信息',
            child: Column(
              children: <Widget>[
                CompanyMyInfoAvatarRow(
                  label: '头像',
                  avatarUrl: profile.logoUrl,
                  fallbackAssetPath: CompanyMyInfoPage._avatarFallbackAsset,
                ),
                CompanyMyInfoValueRow(
                  label: '企业名称',
                  value: _companyName,
                ),
                CompanyMyInfoValueRow(
                  label: '注册国家',
                  value: _registeredCountry,
                ),
                const CompanyMyInfoValueRow(
                  label: '负责人姓名',
                  value: '王晓晓',
                ),
                const CompanyMyInfoValueRow(
                  label: '联系电话',
                  value: '13290867643',
                ),
                const CompanyMyInfoValueRow(
                  label: '联系邮箱',
                  value: 'lksdoieu@126.com',
                ),
                const CompanyMyInfoValueRow(
                  label: '从业年限',
                  value: '12',
                ),
                const CompanyMyInfoValueRow(
                  label: '主营国家',
                  value: '德国/法国',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanyMyInfoSectionCard(
            title: '材料资质',
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                CompanyQualificationPreview(
                  title: '营业执照',
                  assetPath: CompanyMyInfoPage._qualificationPlaceholderAsset,
                ),
                CompanyQualificationPreview(
                  title: '特许经验许可',
                  assetPath: CompanyMyInfoPage._qualificationPlaceholderAsset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            CompanyMyInfoPage._noteText,
            style: CompanyMyInfoStyles.noteText,
          ),
          const SizedBox(height: 24),
          CompanyMyInfoPrimaryButton(
            label: '修改信息',
            onTap: () {
              context.push(
                RoutePaths.qualificationCertification,
                extra: QualificationCertificationPageArgs(
                  role: QualificationCertificationRole.company,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _companyName {
    final String value = profile.companyName.trim();
    return value.isEmpty ? '企业名称待完善' : value;
  }

  String get _registeredCountry {
    final String value = profile.country.trim();
    if (value.isEmpty) {
      return '未完善';
    }
    return resolveCountryLabel(value, countryLabelMap);
  }
}

class _CompanyMyInfoErrorView extends StatelessWidget {
  const _CompanyMyInfoErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '加载企业资料失败，请稍后重试',
              style: TextStyle(
                color: CompanyMyInfoStyles.secondaryText,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
