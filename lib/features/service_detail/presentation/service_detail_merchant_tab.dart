import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../me/presentation/service_provider_my_info_page.dart';
import '../../visa/data/provider_models.dart';

class ServiceDetailMerchantTab extends StatelessWidget {
  const ServiceDetailMerchantTab({
    super.key,
    required this.verifiedBadgeAsset,
    required this.provider,
    this.isLoading = false,
    this.errorMessage,
  });

  final String verifiedBadgeAsset;
  final ProviderVO? provider;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && provider == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && provider == null) {
      return _MerchantPlaceholder(message: errorMessage!);
    }

    if (provider == null) {
      return _MerchantPlaceholder(message: '服务详情.暂无商家信息'.tr());
    }

    return ListView(
      key: const PageStorageKey<String>('service-detail-merchant-tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: <Widget>[
        _MerchantHeaderCard(
          verifiedBadgeAsset: verifiedBadgeAsset,
          provider: provider!,
        ),
        const SizedBox(height: 16),
        _MerchantInfoPanel(provider: provider!),
      ],
    );
  }
}

class _MerchantHeaderCard extends StatelessWidget {
  const _MerchantHeaderCard({
    required this.verifiedBadgeAsset,
    required this.provider,
  });

  final String verifiedBadgeAsset;
  final ProviderVO provider;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 24 / 17,
    );
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF8C8C8C),
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 14 / 11,
    );

    final Widget content = SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8C7C7), width: 0.5),
            ),
            child: ClipOval(
              child: AppUserAvatar(
                imageUrl: provider.logoUrl,
                size: 40,
                backgroundColor: Colors.white,
                placeholder: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF8C8C8C),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 24,
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            provider.name.isEmpty
                                ? '服务详情.签证服务商'.tr()
                                : provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        if (provider.isVerified) ...<Widget>[
                          const SizedBox(width: 8),
                          Image.asset(
                            verifiedBadgeAsset,
                            width: 47,
                            height: 14,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '服务详情.服务评分累计服务'.tr(
                      namedArgs: <String, String>{
                        'rating': provider.rating.toStringAsFixed(1),
                        'count': provider.caseCount.toString(),
                      },
                    ),
                    style: metaStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (provider.providerId <= 0) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          RoutePaths.serviceProviderMyInfo,
          extra: ServiceProviderMyInfoPageArgs.readonly(
            providerId: provider.providerId,
          ),
        ),
        child: content,
      ),
    );
  }
}

class _MerchantInfoPanel extends StatelessWidget {
  const _MerchantInfoPanel({required this.provider});

  final ProviderVO provider;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final contentStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF595959),
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );
    final infoLabelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );
    final infoValueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF8C8C8C),
      fontSize: 13,
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('服务详情.简介'.tr(), style: titleStyle),
        const SizedBox(height: 8),
        Text(
          provider.brief.trim().isEmpty ? '服务详情.暂无商家简介'.tr() : provider.brief,
          style: contentStyle,
        ),
        const SizedBox(height: 24),
        Text('服务详情.基础信息'.tr(), style: titleStyle),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '服务详情.服务国家'.tr(),
          value: provider.serviceCountries.isEmpty
              ? '服务详情.暂无'.tr()
              : provider.serviceCountries.join(' / '),
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '服务详情.认证状态'.tr(),
          value: provider.isVerified ? '服务详情.已认证'.tr() : '服务详情.未认证'.tr(),
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '服务详情.服务年限'.tr(),
          value: provider.yearsOfService > 0
              ? '服务详情.年数'.tr(
                  namedArgs: <String, String>{
                    'count': provider.yearsOfService.toString(),
                  },
                )
              : '服务详情.暂无'.tr(),
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 24),
        Text('服务详情.服务承诺'.tr(), style: titleStyle),
        const SizedBox(height: 8),
        Text(
          provider.servicePromise.trim().isEmpty
              ? '服务详情.暂无服务承诺说明'.tr()
              : provider.servicePromise,
          style: contentStyle,
        ),
      ],
    );
  }
}

class _MerchantPlaceholder extends StatelessWidget {
  const _MerchantPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message == '服务详情.暂无商家信息'.tr()) {
      return Center(
        child: AppEmptyState(
          message: '服务详情.暂无商家信息'.tr(),
          padding: const EdgeInsets.all(24),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8C8C8C)),
        ),
      ),
    );
  }
}

class _MerchantInfoRow extends StatelessWidget {
  const _MerchantInfoRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: <Widget>[
          Text(label, style: labelStyle),
          const Spacer(),
          Text(
            value,
            style: valueStyle?.copyWith(textBaseline: TextBaseline.alphabetic),
          ),
        ],
      ),
    );
  }
}
