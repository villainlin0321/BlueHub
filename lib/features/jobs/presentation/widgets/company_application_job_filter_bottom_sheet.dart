import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_currency.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';
import 'filter_bottom_sheet_chip.dart';

import 'package:europepass/shared/ui/test_style.dart';
class CompanyApplicationJobFilterResult {
  const CompanyApplicationJobFilterResult({
    required this.jobId,
    required this.jobTitle,
  });

  final int? jobId;
  final String? jobTitle;
}

Future<CompanyApplicationJobFilterResult?>
showCompanyApplicationJobFilterBottomSheet({
  required BuildContext context,
  int? initialJobId,
  String? initialJobTitle,
}) {
  final ValueNotifier<CompanyApplicationJobFilterResult> selectionNotifier =
      ValueNotifier<CompanyApplicationJobFilterResult>(
        CompanyApplicationJobFilterResult(
          jobId: initialJobId,
          jobTitle: initialJobTitle,
        ),
      );

  final Future<CompanyApplicationJobFilterResult?> future =
      showFilterActionBottomSheet<CompanyApplicationJobFilterResult?>(
    context: context,
    title: '应聘管理.岗位筛选'.tr(),
    onReset: () {
      selectionNotifier.value = const CompanyApplicationJobFilterResult(
        jobId: null,
        jobTitle: null,
      );
    },
    onConfirm: () {
      Navigator.of(context).pop(selectionNotifier.value);
    },
    child: _CompanyApplicationJobFilterSheet(
      selectionNotifier: selectionNotifier,
    ),
  );
  future.whenComplete(selectionNotifier.dispose);
  return future;
}

class _CompanyApplicationJobFilterSheet extends ConsumerStatefulWidget {
  const _CompanyApplicationJobFilterSheet({required this.selectionNotifier});

  final ValueNotifier<CompanyApplicationJobFilterResult> selectionNotifier;

  @override
  ConsumerState<_CompanyApplicationJobFilterSheet> createState() =>
      _CompanyApplicationJobFilterSheetState();
}

class _CompanyApplicationJobFilterSheetState
    extends ConsumerState<_CompanyApplicationJobFilterSheet> {
  List<JobDetailVO> _jobs = const <JobDetailVO>[];
  bool _isLoading = true;
  String? _errorMessage;
  int? _draftSelectedJobId;

  @override
  void initState() {
    super.initState();
    _draftSelectedJobId = widget.selectionNotifier.value.jobId;
    widget.selectionNotifier.addListener(_syncSelectionFromNotifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  @override
  void dispose() {
    widget.selectionNotifier.removeListener(_syncSelectionFromNotifier);
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PageResult<JobDetailVO> response = await ref
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
        _errorMessage = _normalizeError(error);
      });
    }
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length).trim();
    }
    return message.isEmpty ? '企业岗位.加载失败'.tr() : message;
  }

  void _syncSelectionFromNotifier() {
    if (!mounted) {
      return;
    }
    setState(() {
      _draftSelectedJobId = widget.selectionNotifier.value.jobId;
    });
  }

  void _handleSelectJob(JobDetailVO job) {
    final String title = job.title.trim().isEmpty
        ? '招聘.未命名岗位'.tr()
        : job.title.trim();
    widget.selectionNotifier.value = CompanyApplicationJobFilterResult(
      jobId: job.jobId,
      jobTitle: title,
    );
    setState(() {
      _draftSelectedJobId = job.jobId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CompanyApplicationJobFilterSheetLayout(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      jobs: _jobs,
      selectedJobId: _draftSelectedJobId,
      onRetryTap: _loadJobs,
      onJobTap: _handleSelectJob,
    );
  }
}

class _CompanyApplicationJobFilterSheetLayout extends StatelessWidget {
  const _CompanyApplicationJobFilterSheetLayout({
    required this.isLoading,
    required this.errorMessage,
    required this.jobs,
    required this.selectedJobId,
    required this.onRetryTap,
    required this.onJobTap,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<JobDetailVO> jobs;
  final int? selectedJobId;
  final Future<void> Function() onRetryTap;
  final ValueChanged<JobDetailVO> onJobTap;

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetryTap,
                child: Text('通用.重试'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (jobs.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(
          child: AppEmptyState(message: '招聘.暂无发布岗位'.tr()),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final JobDetailVO job = jobs[index];
        return _CompanyApplicationJobFilterCard(
          job: job,
          isSelected: selectedJobId == job.jobId,
          onTap: () => onJobTap(job),
        );
      },
    );
  }
}

class _CompanyApplicationJobFilterCard extends StatelessWidget {
  const _CompanyApplicationJobFilterCard({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final JobDetailVO job;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF096DD9)
                  : const Color(0xFFF0F0F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  job.title.trim().isEmpty ? '招聘.未命名岗位'.tr() : job.title,
                  style: TestStyle.pingFangMedium(fontSize: 16, color: Color(0xFF262626)),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildTags(job)
                        .map(
                          (String tag) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _CompanyApplicationJobFilterTag(label: tag),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      _formatSalary(job),
                      style: TestStyle.pingFangMedium(fontSize: 14, color: Color(0xFFFE5815)),
                    ),
                    const Spacer(),
                    Text(
                      '企业岗位.浏览数'.tr(
                        namedArgs: <String, String>{
                          'count': job.viewCount.toString(),
                        },
                      ),
                      style: TestStyle.pingFangRegular(fontSize: 12, color: Color(0xFF8C8C8C)),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '企业岗位.收到简历数'.tr(
                        namedArgs: <String, String>{
                          'count': job.applyCount.toString(),
                        },
                      ),
                      style: TestStyle.regular(fontSize: 12, color: Color(0xFF096DD9)),
                    ),
                  ],
                ),
                if (job.publishedAt.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '企业岗位.发布时间'.tr(
                      namedArgs: <String, String>{'time': job.publishedAt},
                    ),
                    style: TestStyle.pingFangRegular(fontSize: 12, color: Color(0xFF8C8C8C)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _buildTags(JobDetailVO job) {
    final List<String> tags = <String>[];

    void addTag(String value) {
      final String tag = value.trim();
      if (tag.isEmpty || tags.contains(tag)) {
        return;
      }
      tags.add(tag);
    }

    addTag(job.employmentType);
    addTag(_formatLocation(job));
    if (job.hasVisaSupport) {
      addTag('招聘卡片.提供签证'.tr());
    }
    for (final TagVO tag in job.tags) {
      addTag(tag.label);
      if (tags.length >= 4) {
        break;
      }
    }

    return tags;
  }

  String _formatLocation(JobDetailVO job) {
    if (job.country.isEmpty && job.city.isEmpty) {
      return '';
    }
    if (job.country.isEmpty) {
      return job.city;
    }
    if (job.city.isEmpty) {
      return job.country;
    }
    return '${job.country}·${job.city}';
  }

  String _formatSalary(JobDetailVO job) {
    if (job.salaryMin <= 0 && job.salaryMax <= 0) {
      return '企业岗位.薪资面议'.tr();
    }
    return AppCurrency.formatRange(
      min: job.salaryMin,
      max: job.salaryMax,
      rawCurrency: job.salaryCurrency,
      period: job.salaryPeriod,
    );
  }
}

class _CompanyApplicationJobFilterTag extends StatelessWidget {
  const _CompanyApplicationJobFilterTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TestStyle.regular(fontSize: 10, color: Color(0xFF546D96)),
      ),
    );
  }
}
