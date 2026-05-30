import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_user_avatar.dart';
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
    this.localAvatarPath,
    required this.fallbackAssetPath,
    this.onTap,
    super.key,
  });

  final String label;
  final String avatarUrl;
  final String? localAvatarPath;
  final String fallbackAssetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: <Widget>[
                Text(label, style: CompanyMyInfoStyles.fieldLabel),
                const Spacer(),
                _CompanyAvatar(
                  avatarUrl: avatarUrl,
                  localAvatarPath: localAvatarPath,
                  fallbackAssetPath: fallbackAssetPath,
                ),
              ],
            ),
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
    final Widget fallback = Image.asset(fallbackAssetPath, fit: BoxFit.cover);
    if (resolvedImageUrl.isEmpty) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: resolvedImageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
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

class CompanyImageSourceBottomSheet extends StatelessWidget {
  const CompanyImageSourceBottomSheet({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择头像',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
            const SizedBox(height: 12),
            _CompanyBottomSheetActionTile(label: '拍照', onTap: onCameraTap),
            _CompanyBottomSheetActionTile(label: '从相册选择', onTap: onGalleryTap),
            const SizedBox(height: 8),
            _CompanyBottomSheetActionTile(label: '取消', onTap: onClose),
          ],
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({
    required this.avatarUrl,
    required this.localAvatarPath,
    required this.fallbackAssetPath,
  });

  final String avatarUrl;
  final String? localAvatarPath;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final String resolvedLocalAvatarPath = localAvatarPath?.trim() ?? '';
    if (resolvedLocalAvatarPath.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(resolvedLocalAvatarPath),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return AppUserAvatar(
              imageUrl: avatarUrl,
              size: 40,
              placeholderAssetPath: fallbackAssetPath,
            );
          },
        ),
      );
    }

    return AppUserAvatar(
      imageUrl: avatarUrl,
      size: 40,
      placeholderAssetPath: fallbackAssetPath,
    );
  }
}

class _CompanyBottomSheetActionTile extends StatelessWidget {
  const _CompanyBottomSheetActionTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
