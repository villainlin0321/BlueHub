import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_error_feedback.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';
Future<JobDetailVO?> showInviteJobPickerSheet(BuildContext context) {
  return showModalBottomSheet<JobDetailVO>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return const _InviteJobPickerSheet();
    },
  );
}

class _InviteJobPickerSheet extends ConsumerStatefulWidget {
  const _InviteJobPickerSheet();

  @override
  ConsumerState<_InviteJobPickerSheet> createState() =>
      _InviteJobPickerSheetState();
}

class _InviteJobPickerSheetState extends ConsumerState<_InviteJobPickerSheet> {
  List<JobDetailVO> _jobs = const <JobDetailVO>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ref
          .read(jobServiceProvider)
          .listMyJobs(page: 1, pageSize: 50, status: 'active');
      if (!mounted) {
        return;
      }
      setState(() {
        _jobs = response.list;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorFeedback.resolveMessage(
          error,
          fallback: '企业岗位.加载失败'.tr(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '招聘.邀约面试'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadJobs, child: Text('通用.重试'.tr())),
          ],
        ),
      );
    }
    if (_jobs.isEmpty) {
      return Center(
        child: Text(
          '招聘.暂无发布岗位'.tr(),
          style: TestStyle.pingFangRegular(color: Color(0xFF8C8C8C)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.separated(
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final JobDetailVO job = _jobs[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              job.title.trim().isEmpty ? '招聘.未命名岗位'.tr() : job.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${job.country} ${job.city} · ${_formatSalary(job)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).pop(job),
          );
        },
      ),
    );
  }

  String _formatSalary(JobDetailVO job) {
    final String min = job.salaryMin.toStringAsFixed(
      job.salaryMin % 1 == 0 ? 0 : 1,
    );
    final String max = job.salaryMax.toStringAsFixed(
      job.salaryMax % 1 == 0 ? 0 : 1,
    );
    final String currency = job.salaryCurrency.trim().isEmpty
        ? 'EUR'
        : job.salaryCurrency;
    return '$currency $min-$max';
  }
}
