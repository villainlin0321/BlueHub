import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/config/data/config_models.dart';
import '../network/services/config_service.dart';
import 'package:europepass/shared/ui/test_style.dart';

class JobPositionCardTagData {
  const JobPositionCardTagData({required this.label, this.type});

  final String label;
  final String? type;
}

class JobPositionCardData {
  const JobPositionCardData({
    required this.title,
    required this.salary,
    required this.requirementTags,
    required this.highlightTags,
    required this.company,
    required this.location,
    this.companyAvatarAssetPath,
    this.locationIconAssetPath,
    this.showApplyButton = false,
    this.archived = false,
    this.statusText,
    this.previewImageAssetPath,
  });

  final String title;
  final String salary;
  final List<JobPositionCardTagData> requirementTags;
  final List<JobPositionCardTagData> highlightTags;
  final String company;
  final String location;
  final String? companyAvatarAssetPath;
  final String? locationIconAssetPath;
  final bool showApplyButton;
  final bool archived;
  final String? statusText;
  final String? previewImageAssetPath;
}

class JobPositionCard extends StatelessWidget {
  const JobPositionCard({
    super.key,
    required this.data,
    this.tagLookupByCategory = const <TagCategory, Map<String, TagItemVO>>{},
    this.onApply,
    this.onTap,
    this.isApplying = false,
    this.applyButtonText = '',
  });

  final JobPositionCardData data;
  final Map<TagCategory, Map<String, TagItemVO>> tagLookupByCategory;
  final VoidCallback? onApply;
  final VoidCallback? onTap;
  final bool isApplying;
  final String applyButtonText;

  /// 构建职位卡片，并根据外部状态展示投递按钮的禁用或加载文案。
  @override
  Widget build(BuildContext context) {
    // 未显式传入按钮文案时，统一回退到国际化默认值。
    final String resolvedApplyButtonText = applyButtonText.trim().isEmpty
        ? '招聘卡片.一键投递'.tr()
        : applyButtonText;
    final Locale locale = context.locale;
    final Widget cardBody = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.medium(
                      fontSize: 16,
                      color: Color(0xFF262626),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.salary,
                  style: TestStyle.medium(
                    fontSize: 14,
                    color: Color(0xFFFE5815),
                  ),
                ),
              ],
            ),
            if (data.requirementTags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: data.requirementTags
                    .map((tag) => _buildRequirementTag(tag, locale))
                    .toList(),
              ),
            ],
            if (data.highlightTags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: data.highlightTags
                    .map((tag) => _buildHighlightTag(tag, locale))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: _CompanyInfo(
                          name: data.company,
                          avatarAssetPath: data.companyAvatarAssetPath,
                        ),
                      ),
                      if (data.location.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(width: 12),
                        Flexible(
                          child: _LocationInfo(
                            location: data.location,
                            iconAssetPath: data.locationIconAssetPath,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.archived && data.statusText != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Text(
                    data.statusText!,
                    style: TestStyle.regular(
                      fontSize: 12,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                ] else if (data.showApplyButton) ...<Widget>[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 28,
                    child: FilledButton(
                      onPressed: isApplying ? null : onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF096DD9),
                        disabledBackgroundColor: const Color(0xFF91C3F7),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        resolvedApplyButtonText,
                        style: TestStyle.medium(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // if (data.previewImageAssetPath != null) ...<Widget>[
            //   const SizedBox(height: 12),
            //   ClipRRect(
            //     borderRadius: BorderRadius.circular(12),
            //     child: Image.asset(
            //       data.previewImageAssetPath!,
            //       width: double.infinity,
            //       height: 120,
            //       fit: BoxFit.cover,
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );

    final Widget card = Stack(
      children: <Widget>[
        cardBody,
        if (data.archived)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }

  Widget _buildRequirementTag(JobPositionCardTagData tag, Locale locale) {
    return const _JobPositionTagStyle.requirement().build(
      _resolveTagLabel(tag, locale),
    );
  }

  Widget _buildHighlightTag(JobPositionCardTagData tag, Locale locale) {
    final String resolvedLabel = _resolveTagLabel(tag, locale);
    final String urgentLabel = '招聘卡片.急招'.tr();
    if (resolvedLabel == urgentLabel) {
      return _JobPositionTagStyle.urgent().build(urgentLabel);
    }
    return const _JobPositionTagStyle.highlightBlue().build(resolvedLabel);
  }

  String _resolveTagLabel(JobPositionCardTagData tag, Locale locale) {
    return ConfigService.resolveTagLabelByCategory(
      rawLabel: tag.label,
      rawCategory: tag.type,
      tagLookupByCategory: tagLookupByCategory,
      locale: locale,
    );
  }
}

class _CompanyInfo extends StatelessWidget {
  const _CompanyInfo({required this.name, this.avatarAssetPath});

  final String name;
  final String? avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CompanyAvatar(assetPath: avatarAssetPath),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TestStyle.regular(fontSize: 12, color: Color(0xFF595959)),
          ),
        ),
      ],
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({required this.location, this.iconAssetPath});

  final String location;
  final String? iconAssetPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LocationIcon(assetPath: iconAssetPath),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TestStyle.regular(fontSize: 12, color: Color(0xFF595959)),
          ),
        ),
      ],
    );
  }
}

class _LocationIcon extends StatelessWidget {
  const _LocationIcon({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null || assetPath!.isEmpty) {
      return const Icon(
        Icons.place_outlined,
        size: 16,
        color: Color(0xFFBCBCBC),
      );
    }

    if (assetPath!.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath!,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(
          Icons.place_outlined,
          size: 16,
          color: Color(0xFFBCBCBC),
        ),
      );
    }

    return Image.asset(
      assetPath!,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.place_outlined,
          size: 16,
          color: Color(0xFFBCBCBC),
        );
      },
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath == null
          ? const Icon(
              Icons.business_rounded,
              size: 12,
              color: Color(0xFF8C8C8C),
            )
          : Image.asset(
              assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.business_rounded,
                  size: 12,
                  color: Color(0xFF8C8C8C),
                );
              },
            ),
    );
  }
}

class _JobPositionTagStyle {
  const _JobPositionTagStyle._({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  const _JobPositionTagStyle.requirement()
    : this._(
        backgroundColor: Colors.transparent,
        textColor: const Color(0xFF546D96),
        borderColor: const Color(0xFFA3AFD4),
      );

  const _JobPositionTagStyle.urgent()
    : this._(
        backgroundColor: const Color(0xFFFFEBEB),
        textColor: const Color(0xFFFF4D4F),
      );

  const _JobPositionTagStyle.highlightBlue()
    : this._(
        backgroundColor: const Color(0xFFEDF5FF),
        textColor: const Color(0xFF386EF8),
      );

  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  Widget build(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 0.5),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 10, color: textColor),
      ),
    );
  }
}
