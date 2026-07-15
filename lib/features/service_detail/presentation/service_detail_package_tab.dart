import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/localization/app_locales.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';

import 'package:europepass/shared/ui/test_style.dart';
class ServicePackageData {
  const ServicePackageData({
    required this.packageId,
    required this.tierId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.price,
    required this.description,
    required this.tags,
  });

  final int packageId;
  final int tierId;
  final String title;
  final double amount;
  final String currency;
  final String price;
  final String description;
  final List<String> tags;
}

class ServiceMaterialData {
  const ServiceMaterialData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.required,
    required this.description,
    required this.exampleFileUrls,
  });

  final String title;
  final String subtitle;
  final String status;
  final bool required;
  final String description;
  final List<String> exampleFileUrls;

  String get fileUrl =>
      exampleFileUrls.isEmpty ? '' : exampleFileUrls.first.trim();
}

class ServiceDetailPackageTab extends ConsumerWidget {
  const ServiceDetailPackageTab({
    super.key,
    required this.packages,
    required this.selectedPackageIndex,
    required this.onPackageSelected,
    required this.materials,
    required this.onMaterialTap,
    required this.onPreviewTap,
    this.downloadingFileUrls = const <String>{},
  });

  final List<ServicePackageData> packages;
  final int selectedPackageIndex;
  final ValueChanged<int> onPackageSelected;
  final List<ServiceMaterialData> materials;
  final ValueChanged<ServiceMaterialData> onMaterialTap;
  final VoidCallback onPreviewTap;
  final Set<String> downloadingFileUrls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TagItemVO>> serviceTagsAsync = ref.watch(
      tagDictionaryProvider(TagCategory.service),
    );
    final List<TagItemVO> serviceTags =
        serviceTagsAsync.asData?.value ?? const <TagItemVO>[];
    final Map<String, String> serviceTagLabelMap = <String, String>{
      for (final TagItemVO item in serviceTags)
        item.tagCode.trim(): _resolveTagLabel(context, item),
    };
    return ListView(
      key: const PageStorageKey<String>('service-detail-package-tab'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: <Widget>[
        ...List<Widget>.generate(packages.length, (index) {
          final data = packages[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == packages.length - 1 ? 0 : 12,
            ),
            child: _PackageOptionCard(
              data: data,
              serviceTagLabelMap: serviceTagLabelMap,
              selected: index == selectedPackageIndex,
              onTap: () => onPackageSelected(index),
            ),
          );
        }),
        const SizedBox(height: 16),
        _MaterialsSection(
          materials: materials,
          downloadingFileUrls: downloadingFileUrls,
          onMaterialTap: onMaterialTap,
          onPreviewTap: onPreviewTap,
        ),
      ],
    );
  }

  String _resolveTagLabel(BuildContext context, TagItemVO item) {
    if (context.isChineseLocale) {
      final String zh = item.tagNameZh.trim();
      if (zh.isNotEmpty) {
        return zh;
      }
      final String en = item.tagNameEn.trim();
      return en.isNotEmpty ? en : item.tagCode.trim();
    }
    final String en = item.tagNameEn.trim();
    if (en.isNotEmpty) {
      return en;
    }
    final String zh = item.tagNameZh.trim();
    return zh.isNotEmpty ? zh : item.tagCode.trim();
  }
}

class _PackageOptionCard extends StatelessWidget {
  const _PackageOptionCard({
    required this.data,
    required this.serviceTagLabelMap,
    required this.selected,
    required this.onTap,
  });

  final ServicePackageData data;
  final Map<String, String> serviceTagLabelMap;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F8FF) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF096DD9)
                  : const Color(0xFFD9D9D9),
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
                      (String tag) => _PackageTag(
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
        ),
      ),
    );
  }
}

class _MaterialsSection extends StatelessWidget {
  const _MaterialsSection({
    required this.materials,
    required this.downloadingFileUrls,
    required this.onMaterialTap,
    required this.onPreviewTap,
  });

  final List<ServiceMaterialData> materials;
  final Set<String> downloadingFileUrls;
  final ValueChanged<ServiceMaterialData> onMaterialTap;
  final VoidCallback onPreviewTap;

  @override
  Widget build(BuildContext context) {
    final bool hasExampleFiles = materials.any(
      (ServiceMaterialData material) => material.exampleFileUrls.any(
        (String fileUrl) => fileUrl.trim().isNotEmpty,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '服务详情.所需材料'.tr(),
                  style: TestStyle.numberBold(fontSize: 16, color: const Color(0xFF262626)),
                ),
              ),
              TextButton(
                onPressed: hasExampleFiles ? onPreviewTap : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF096DD9),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('服务详情.查看样例'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(materials.length, (index) {
            final material = materials[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == materials.length - 1 ? 0 : 12,
              ),
              child: _MaterialCard(
                material: material,
                isDownloading: downloadingFileUrls.contains(
                  material.fileUrl.trim(),
                ),
                onTap: () => onMaterialTap(material),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.isDownloading,
    required this.onTap,
  });

  static const String _materialIconAsset =
      'assets/images/service_detail_material_file.svg';

  final ServiceMaterialData material;
  final bool isDownloading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool canTap = material.fileUrl.trim().isNotEmpty && !isDownloading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canTap ? onTap : null,
        child: Container(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isDownloading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _MaterialStatusTag(
                  label: material.status,
                  required: material.required,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageTag extends StatelessWidget {
  const _PackageTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: TestStyle.semibold(fontSize: 10, color: const Color(0xFF546D96)),
      ),
    );
  }
}

class _MaterialStatusTag extends StatelessWidget {
  const _MaterialStatusTag({required this.label, required this.required});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final color = required ? const Color(0xFFFF0B03) : const Color(0xFF546D96);
    final borderColor = required
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
