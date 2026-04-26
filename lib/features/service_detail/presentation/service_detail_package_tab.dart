import 'package:flutter/material.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';

class ServicePackageData {
  const ServicePackageData({
    required this.title,
    required this.price,
    required this.description,
    required this.tags,
  });

  final String title;
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
  });

  final String title;
  final String subtitle;
  final String status;
  final bool required;
}

class ServiceDetailPackageTab extends StatelessWidget {
  const ServiceDetailPackageTab({
    super.key,
    required this.packages,
    required this.selectedPackageIndex,
    required this.onPackageSelected,
    required this.materials,
  });

  final List<ServicePackageData> packages;
  final int selectedPackageIndex;
  final ValueChanged<int> onPackageSelected;
  final List<ServiceMaterialData> materials;

  @override
  Widget build(BuildContext context) {
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
              selected: index == selectedPackageIndex,
              onTap: () => onPackageSelected(index),
            ),
          );
        }),
        const SizedBox(height: 16),
        _MaterialsSection(materials: materials),
      ],
    );
  }
}

class _PackageOptionCard extends StatelessWidget {
  const _PackageOptionCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final ServicePackageData data;
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF262626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    data.price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFE5815),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.tags
                    .map((tag) => _PackageTag(label: tag))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF595959),
                        height: 1.45,
                      ),
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
  const _MaterialsSection({required this.materials});

  final List<ServiceMaterialData> materials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  '所需材料',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF096DD9),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('查看样例'),
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
              child: _MaterialCard(material: material),
            );
          }),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});

  final ServiceMaterialData material;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF8FA0C9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  material.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  material.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8C8C8C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _MaterialStatusTag(
                label: material.status,
                required: material.required,
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8C8C8C),
                size: 18,
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF546D96),
          fontWeight: FontWeight.w600,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
