import 'package:flutter/material.dart';

import '../company_my_info_styles.dart';

class CompanyMyInfoHeader extends StatelessWidget {
  const CompanyMyInfoHeader({required this.onBackTap, super.key});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          const Text('我的信息', style: CompanyMyInfoStyles.navTitle),
        ],
      ),
    );
  }
}

class CompanyMyInfoSectionCard extends StatelessWidget {
  const CompanyMyInfoSectionCard({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 16, 12, 0),
    super.key,
  });

  final String title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CompanyMyInfoStyles.cardBackground,
        borderRadius: BorderRadius.circular(CompanyMyInfoStyles.sectionRadius),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: CompanyMyInfoStyles.sectionTitle),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class CompanyMyInfoValueRow extends StatelessWidget {
  const CompanyMyInfoValueRow({
    required this.label,
    required this.value,
    this.showDivider = true,
    super.key,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: <Widget>[
              Text(label, style: CompanyMyInfoStyles.fieldLabel),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CompanyMyInfoStyles.fieldValue,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: CompanyMyInfoStyles.divider,
          ),
      ],
    );
  }
}

class CompanyMyInfoAvatarRow extends StatelessWidget {
  const CompanyMyInfoAvatarRow({
    required this.label,
    required this.avatarUrl,
    required this.fallbackAssetPath,
    super.key,
  });

  final String label;
  final String avatarUrl;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: <Widget>[
              Text(label, style: CompanyMyInfoStyles.fieldLabel),
              const Spacer(),
              _CompanyAvatar(
                avatarUrl: avatarUrl,
                fallbackAssetPath: fallbackAssetPath,
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: CompanyMyInfoStyles.divider,
        ),
      ],
    );
  }
}

class CompanyQualificationPreview extends StatelessWidget {
  const CompanyQualificationPreview({
    required this.title,
    required this.fallbackAssetPath,
    this.imageUrl,
    super.key,
  });

  final String title;
  final String fallbackAssetPath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CompanyMyInfoStyles.qualificationPreviewWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: const TextStyle(
                color: CompanyMyInfoStyles.primaryText,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: CompanyMyInfoStyles.qualificationPreviewWidth,
            height: CompanyMyInfoStyles.qualificationPreviewHeight,
            decoration: BoxDecoration(
              color: CompanyMyInfoStyles.placeholderBackground,
              borderRadius: BorderRadius.circular(
                CompanyMyInfoStyles.qualificationPreviewRadius,
              ),
              border: Border.all(
                color: CompanyMyInfoStyles.placeholderBorder,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                CompanyMyInfoStyles.qualificationPreviewRadius,
              ),
              child: _CompanyQualificationImage(
                imageUrl: imageUrl,
                fallbackAssetPath: fallbackAssetPath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyQualificationImage extends StatelessWidget {
  const _CompanyQualificationImage({
    required this.imageUrl,
    required this.fallbackAssetPath,
  });

  final String? imageUrl;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final String resolvedImageUrl = imageUrl?.trim() ?? '';
    final Widget fallback = Image.asset(
      fallbackAssetPath,
      fit: BoxFit.cover,
    );
    if (resolvedImageUrl.isEmpty) {
      return fallback;
    }

    return Image.network(
      resolvedImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) {
              return child;
            }
            return fallback;
          },
    );
  }
}

class CompanyMyInfoPrimaryButton extends StatelessWidget {
  const CompanyMyInfoPrimaryButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: CompanyMyInfoStyles.primaryButtonHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CompanyMyInfoStyles.primaryButton,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: CompanyMyInfoStyles.buttonText),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({
    required this.avatarUrl,
    required this.fallbackAssetPath,
  });

  final String avatarUrl;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = ClipOval(
      child: Image.asset(
        fallbackAssetPath,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
    if (avatarUrl.trim().isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? progress) {
              if (progress == null) {
                return child;
              }
              return fallback;
            },
      ),
    );
  }
}
