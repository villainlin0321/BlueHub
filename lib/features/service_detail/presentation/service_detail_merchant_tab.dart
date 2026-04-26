import 'package:flutter/material.dart';

class ServiceDetailMerchantTab extends StatelessWidget {
  const ServiceDetailMerchantTab({super.key, required this.verifiedBadgeAsset});

  final String verifiedBadgeAsset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('service-detail-merchant-tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: <Widget>[
        _MerchantHeaderCard(verifiedBadgeAsset: verifiedBadgeAsset),
        const SizedBox(height: 16),
        const _MerchantInfoPanel(),
      ],
    );
  }
}

class _MerchantHeaderCard extends StatelessWidget {
  const _MerchantHeaderCard({required this.verifiedBadgeAsset});

  final String verifiedBadgeAsset;
  static const _merchantAvatarAsset =
      'assets/images/service_detail_merchant_avatar-56586a.png';

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
              child: Image.asset(
                _merchantAvatarAsset,
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
                        Text('中欧出海签证服务', style: titleStyle),
                        const SizedBox(width: 8),
                        Image.asset(
                          verifiedBadgeAsset,
                          width: 47,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('服务评分 4.9  累计服务 1,205', style: metaStyle),
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
  const _MerchantInfoPanel();

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
          '专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及，专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及。',
          style: contentStyle,
        ),
        const SizedBox(height: 24),
        Text('基础信息', style: titleStyle),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '商家资质',
          value: '已上传',
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 12),
        _MerchantInfoRow(
          label: '认证状态',
          value: '已认证',
          labelStyle: infoLabelStyle,
          valueStyle: infoValueStyle,
        ),
        const SizedBox(height: 24),
        Text('服务承诺', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          '本店郑重承诺：全程透明收费，无隐形消费；专业团队一对一服务，资料严格审核把关；及时同步办理进度，耐心解答各类疑问；严格保护客户隐私，确保信息安全。以专业、高效、诚信为宗旨，全力保障您的权益，让办理省心更放心。',
          style: contentStyle,
        ),
      ],
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
