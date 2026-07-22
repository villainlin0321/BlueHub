import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/models/app_currency.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../visa/data/provider_models.dart'
    hide MaterialVO, TierVO, VisaPackageVO;
import '../../visa/data/visa_package_models.dart';
import 'service_detail_package_tab.dart';

import 'package:europepass/shared/ui/test_style.dart';
class ServiceDetailShareCard extends StatelessWidget {
  const ServiceDetailShareCard({
    super.key,
    required this.package,
    required this.provider,
    required this.packages,
    required this.selectedPackageIndex,
    required this.materials,
    required this.verifiedBadgeAsset,
    required this.serviceTagLabelMap,
    required this.countryLabelMap,
    required this.visaTypeLabelMap,
  });

  static const double shareWidth = 375;
  static const String _heroAsset =
      'assets/images/service_detail_top_background.png';

  final VisaPackageVO package;
  final ProviderVO? provider;
  final List<ServicePackageData> packages;
  final int selectedPackageIndex;
  final List<ServiceMaterialData> materials;
  final String verifiedBadgeAsset;
  final Map<String, String> serviceTagLabelMap;
  final Map<String, String> countryLabelMap;
  final Map<String, String> visaTypeLabelMap;

  @override
  Widget build(BuildContext context) {
    final ServicePackageData? selectedPackage = packages.isEmpty
        ? null
        : packages[selectedPackageIndex.clamp(0, packages.length - 1)];

    return Material(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: SizedBox(
          width: shareWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ShareHeroSection(
                imageUrl: package.coverImages.isEmpty
                    ? ''
                    : package.coverImages.first,
                fallbackAsset: _heroAsset,
              ),
              _ShareSummarySection(
                serviceTitle: package.name.trim().isEmpty
                    ? '服务详情.标题'.tr()
                    : package.name.trim(),
                selectedPackage: selectedPackage,
                packageDetail: package,
                provider: provider,
                verifiedBadgeAsset: verifiedBadgeAsset,
                countryLabelMap: countryLabelMap,
                visaTypeLabelMap: visaTypeLabelMap,
              ),
              _SharePackageSection(
                packages: packages,
                selectedPackageIndex: selectedPackageIndex,
                materials: materials,
                serviceTagLabelMap: serviceTagLabelMap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareHeroSection extends StatelessWidget {
  const _ShareHeroSection({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  static const String _qrCodeAsset = 'assets/images/apk_link_qr_code.apk.png';

  // static const String _qrCodeAsset = 'assets/images/apk_link_qr_code_transparent.png';

  final String imageUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 292,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _ShareHeroBackground(
            imageUrl: imageUrl,
            fallbackAsset: fallbackAsset,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const Positioned(
            right: 16,
            bottom: 34,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image(image: AssetImage(_qrCodeAsset), fit: BoxFit.cover),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareHeroBackground extends StatelessWidget {
  const _ShareHeroBackground({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  final String imageUrl;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) =>
          Image.asset(fallbackAsset, fit: BoxFit.cover),
    );
  }
}

class _ShareSummarySection extends StatelessWidget {
  const _ShareSummarySection({
    required this.serviceTitle,
    required this.selectedPackage,
    required this.packageDetail,
    required this.provider,
    required this.verifiedBadgeAsset,
    required this.countryLabelMap,
    required this.visaTypeLabelMap,
  });

  final String serviceTitle;
  final ServicePackageData? selectedPackage;
  final VisaPackageVO packageDetail;
  final ProviderVO? provider;
  final String verifiedBadgeAsset;
  final Map<String, String> countryLabelMap;
  final Map<String, String> visaTypeLabelMap;

  @override
  Widget build(BuildContext context) {
    final String summaryDescription = provider?.brief.trim().isNotEmpty == true
        ? provider!.brief
        : '服务详情.预计办理天数'.tr(
            namedArgs: <String, String>{
              'days': packageDetail.estimatedDays > 0
                  ? packageDetail.estimatedDays.toString()
                  : '--',
            },
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  serviceTitle,
                  style: TestStyle.numberBold(fontSize: 22, color: const Color(0xFF262626)),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text:
                          selectedPackage?.price ??
                          _formatPrice(0, packageDetail.currency),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFFFE5815),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    TextSpan(
                      text: '服务详情.起'.tr(),
                      style: TestStyle.pingFangSemibold(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (provider?.isVerified == true)
                Image.asset(
                  verifiedBadgeAsset,
                  width: 55.67,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              _SummaryTag(
                label: _resolveCountryLabel(
                  packageDetail.targetCountry,
                  countryLabelMap: countryLabelMap,
                ),
              ),
              _SummaryTag(
                label: _resolveVisaTypeLabel(
                  packageDetail.visaType,
                  visaTypeLabelMap: visaTypeLabelMap,
                ),
              ),
              if (packageDetail.estimatedDays > 0)
                _SummaryTag(
                  label: '服务详情.天办结'.tr(
                    namedArgs: <String, String>{
                      'days': packageDetail.estimatedDays.toString(),
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryDescription,
            style: TestStyle.regular(fontSize: 12, color: const Color(0xFF595959)),
          ),
        ],
      ),
    );
  }
}

class _SharePackageSection extends StatelessWidget {
  const _SharePackageSection({
    required this.packages,
    required this.selectedPackageIndex,
    required this.materials,
    required this.serviceTagLabelMap,
  });

  final List<ServicePackageData> packages;
  final int selectedPackageIndex;
  final List<ServiceMaterialData> materials;
  final Map<String, String> serviceTagLabelMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (packages.isEmpty)
            _ShareEmptyCard(message: '服务详情.当前套餐暂无可申请档位'.tr())
          else
            ...List<Widget>.generate(packages.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == packages.length - 1 ? 0 : 12,
                ),
                child: _SharePackageOptionCard(
                  data: packages[index],
                  serviceTagLabelMap: serviceTagLabelMap,
                  selected: index == selectedPackageIndex,
                ),
              );
            }),
          const SizedBox(height: 16),
          _ShareMaterialsSection(materials: materials),
        ],
      ),
    );
  }
}

class _SharePackageOptionCard extends StatelessWidget {
  const _SharePackageOptionCard({
    required this.data,
    required this.serviceTagLabelMap,
    required this.selected,
  });

  final ServicePackageData data;
  final Map<String, String> serviceTagLabelMap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5F8FF) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF096DD9) : const Color(0xFFD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? const Color(0xFF096DD9)
                    : const Color(0xFFB8C2D8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: TestStyle.numberBold(fontSize: 16, color: const Color(0xFF262626)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                data.price,
                style: TestStyle.numberBold(fontSize: 16, color: const Color(0xFFFE5815)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.tags
                .map(
                  (String tag) => _SharePackageTag(
                    label: serviceTagLabelMap[tag.trim()] ?? tag,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  data.description,
                  style: TestStyle.regular(fontSize: 12, color: const Color(0xFF595959)),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF8C8C8C),
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareMaterialsSection extends StatelessWidget {
  const _ShareMaterialsSection({required this.materials});

  final List<ServiceMaterialData> materials;

  @override
  Widget build(BuildContext context) {
    final bool hasExampleFiles = materials.any(
      (ServiceMaterialData material) => material.exampleFileUrls.any(
        (String fileUrl) => fileUrl.trim().isNotEmpty,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '服务详情.所需材料'.tr(),
                  style: TestStyle.numberBold(fontSize: 16, color: const Color(0xFF262626)),
                ),
              ),
              Text(
                '服务详情.查看样例'.tr(),
                style: TestStyle.pingFangMedium(fontSize: 14, color: hasExampleFiles
                      ? const Color(0xFF096DD9)
                      : const Color(0xFFBFBFBF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (materials.isEmpty)
            _ShareEmptyHint(message: '服务详情.请按服务要求准备相关材料'.tr())
          else
            ...List<Widget>.generate(materials.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == materials.length - 1 ? 0 : 12,
                ),
                child: _ShareMaterialCard(material: materials[index]),
              );
            }),
        ],
      ),
    );
  }
}

class _ShareMaterialCard extends StatelessWidget {
  const _ShareMaterialCard({required this.material});

  static const String _materialIconAsset =
      'assets/images/service_detail_material_file.svg';

  final ServiceMaterialData material;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(12, 12, 17, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            _materialIconAsset,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  material.title,
                  style: TestStyle.medium(fontSize: 14, color: const Color(0xFF262626)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  material.subtitle,
                  style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ShareMaterialStatusTag(
            label: material.status,
            required: material.required,
          ),
        ],
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TestStyle.semibold(fontSize: 12, color: const Color(0xFF096DD9)),
      ),
    );
  }
}

class _SharePackageTag extends StatelessWidget {
  const _SharePackageTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: TestStyle.semibold(fontSize: 11, color: const Color(0xFF546D96)),
      ),
    );
  }
}

class _ShareMaterialStatusTag extends StatelessWidget {
  const _ShareMaterialStatusTag({required this.label, required this.required});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final Color color = required
        ? const Color(0xFFFF0B03)
        : const Color(0xFF546D96);
    final Color borderColor = required
        ? const Color(0xFFFF6661)
        : const Color(0xFFA3AFD4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 10, color: color),
      ),
    );
  }
}

class _ShareEmptyCard extends StatelessWidget {
  const _ShareEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Text(
        message,
        style: TestStyle.regular(fontSize: 14, color: const Color(0xFF8C8C8C)),
      ),
    );
  }
}

class _ShareEmptyHint extends StatelessWidget {
  const _ShareEmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
    );
  }
}

String _formatPrice(double amount, String currency) {
  return AppCurrency.formatAmount(amount, currency);
}

String _resolveCountryLabel(
  String country, {
  required Map<String, String> countryLabelMap,
}) {
  final String normalizedCountry = country.trim().toUpperCase();
  if (normalizedCountry.isEmpty) {
    return '国家.签证'.tr();
  }
  return countryLabelMap[normalizedCountry] ?? normalizedCountry;
}

String _resolveVisaTypeLabel(
  String visaType, {
  required Map<String, String> visaTypeLabelMap,
}) {
  final String normalizedVisaType = visaType.trim();
  if (normalizedVisaType.isEmpty) {
    return '服务详情.签证服务'.tr();
  }
  return visaTypeLabelMap[normalizedVisaType.toLowerCase()] ??
      normalizedVisaType;
}
