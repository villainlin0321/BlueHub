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
    final Map<TagCategory, Map<String, TagItemVO>> tagLookupByCategory =
        ref.watch(jobCardTagLookupProvider).asData?.value ??
        const <TagCategory, Map<String, TagItemVO>>{};

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
          tagLookupByCategory: tagLookupByCategory,
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
    final List<JobPositionCardTagData> apiTags = tags
        .map(
          (TagVO tag) => JobPositionCardTagData(
            label: tag.label.trim(),
            type: tag.type.trim(),
          ),
        )
        .where((JobPositionCardTagData tag) => tag.label.isNotEmpty)
        .toList(growable: false);
    final List<JobPositionCardTagData> requirementTags = <JobPositionCardTagData>[
      ...apiTags.where(
        (JobPositionCardTagData tag) => tag.type != TagCategory.highlight.value,
      ),
      if (hasVisaSupport)
        JobPositionCardTagData(label: visaSupportLabel, type: null),
    ].take(3).toList(growable: false);
    final List<JobPositionCardTagData> highlightTags = <JobPositionCardTagData>[
      ...apiTags.where(
        (JobPositionCardTagData tag) => tag.type == TagCategory.highlight.value,
      ),
      if (isUrgent)
        JobPositionCardTagData(
          label: urgentLabel,
          type: TagCategory.highlight.value,
        ),
    ];

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
