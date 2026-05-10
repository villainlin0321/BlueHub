import 'package:flutter/material.dart';

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
      return const _MerchantPlaceholder(message: '暂无商家信息');
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

    return SizedBox(
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
              child: Image.network(
                provider.logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF8C8C8C),
                      size: 20,
                    ),
                  );
                },
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
                            provider.name.isEmpty ? '签证服务商' : provider.name,
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
                    '服务评分 ${provider.rating.toStringAsFixed(1)}  累计服务 ${provider.caseCount}',
                    style: metaStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
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
        Text('简介', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          provider.brief.trim().isEmpty ? '暂无商家简介' : provider.brief,
          style: contentStyle,
        ),
        const SizedBox(height: 24),
        Text('基础信息', style: titleStyle),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '服务国家',
          value: provider.serviceCountries.isEmpty
              ? '暂无'
              : provider.serviceCountries.join(' / '),
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '认证状态',
          value: provider.isVerified ? '已认证' : '未认证',
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '服务年限',
          value: provider.yearsOfService > 0
              ? '${provider.yearsOfService}年'
              : '暂无',
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 24),
        Text('服务承诺', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          provider.servicePromise.trim().isEmpty
              ? '暂无服务承诺说明'
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
