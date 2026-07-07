import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/data/config_models.dart';
import '../../../config/data/config_providers.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/network/services/config_service.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../data/job_models.dart';

class JobListCards extends ConsumerWidget {
  const JobListCards({
    super.key,
    required this.jobs,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onTap,
    this.onApply,
    this.padding = EdgeInsets.zero,
    this.separatorHeight = 12,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<JobListVO> jobs;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final ValueChanged<JobListVO> onTap;
  final Future<void> Function(JobListVO job)? onApply;
  final EdgeInsetsGeometry padding;
  final double separatorHeight;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, TagItemVO> requirementTagLookup =
        ConfigService.buildTagLookup(
          ref
                  .watch(tagDictionaryProvider(TagCategory.requirement))
                  .asData
                  ?.value ??
              const <TagItemVO>[],
        );

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: jobs.length,
      separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: (BuildContext context, int index) {
        final JobListVO item = jobs[index];
        final bool isApplied = appliedJobIds.contains(item.jobId);
        return JobPositionCard(
          data: item.toCardData(),
          requirementTagLookup: requirementTagLookup,
          onTap: () => onTap(item),
          onApply: isApplied || onApply == null ? null : () => onApply!(item),
          isApplying: applyingJobIds.contains(item.jobId),
          applyButtonText: isApplied ? '招聘.已投递'.tr() : '招聘卡片.一键投递'.tr(),
        );
      },
    );
  }
}

extension JobListCardDataMapper on JobListVO {
  /// 将接口返回的岗位列表项映射为职位卡片数据。
  JobPositionCardData toCardData() {
    final String urgentLabel = '招聘卡片.急招'.tr();
    final String visaSupportLabel = '招聘卡片.提供签证'.tr();
    final List<String> tagLabels = tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != urgentLabel),
      if (hasVisaSupport && !tagLabels.contains(visaSupportLabel))
        visaSupportLabel,
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[if (isUrgent) urgentLabel];

    return JobPositionCardData(
      title: title,
      salary: _formatSalary(),
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: employer.name,
      location: _formatLocation(),
      showApplyButton: true,
    );
  }

  /// 组装职位卡片展示的薪资文案。
  String _formatSalary() {
    return AppCurrency.formatRange(
      min: salaryMin,
      max: salaryMax,
      rawCurrency: salaryCurrency,
      period: salaryPeriod,
    );
  }

  /// 组装职位卡片展示的地点文案。
  String _formatLocation() {
    final List<String> parts = <String>[
      country.trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }
}
