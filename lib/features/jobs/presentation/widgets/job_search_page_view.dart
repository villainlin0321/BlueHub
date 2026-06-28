import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/job_models.dart';
import 'job_list_cards.dart';

class JobSearchPageView extends StatelessWidget {
  const JobSearchPageView({
    super.key,
    required this.hasSubmittedKeyword,
    required this.isLoading,
    required this.errorMessage,
    required this.jobs,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onTap,
    required this.onApply,
    required this.onRetry,
  });

  final bool hasSubmittedKeyword;
  final bool isLoading;
  final String? errorMessage;
  final List<JobListVO> jobs;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final ValueChanged<JobListVO> onTap;
  final Future<void> Function(JobListVO job) onApply;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!hasSubmittedKeyword) {
      return Center(child: AppEmptyState(message: '招聘.请输入关键词开始搜索'.tr()));
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _JobSearchErrorState(message: errorMessage!, onRetry: onRetry);
    }

    if (jobs.isEmpty) {
      return Center(child: AppEmptyState(message: '招聘.未找到相关岗位'.tr()));
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      child: JobListCards(
        jobs: jobs,
        applyingJobIds: applyingJobIds,
        appliedJobIds: appliedJobIds,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        onTap: onTap,
        onApply: onApply,
      ),
    );
  }
}

class _JobSearchErrorState extends StatelessWidget {
  const _JobSearchErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}
