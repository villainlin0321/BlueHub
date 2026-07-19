import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/job_models.dart';
import '../data/job_providers.dart';
import 'job_apply_helper.dart';
import 'job_detail_page.dart';
import 'widgets/job_search_page_view.dart';

import 'package:europepass/shared/ui/test_style.dart';
class JobSearchPage extends ConsumerStatefulWidget {
  const JobSearchPage({super.key});

  @override
  ConsumerState<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends ConsumerState<JobSearchPage> {
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _searchAsset = 'assets/images/mou2x9mw-2jfef5b.svg';
  static const int _pageSize = 20;

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(_handleInputChanged);
  late final FocusNode _focusNode = FocusNode();
  final List<JobListVO> _jobs = <JobListVO>[];
  final Set<int> _submittingJobIds = <int>{};
  final Set<int> _appliedJobIds = <int>{};

  String? _submittedKeyword;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasSubmittedKeyword => (_submittedKeyword ?? '').trim().isNotEmpty;

  void _handleInputChanged() {
    if (_searchController.text.trim().isNotEmpty || !_hasSubmittedKeyword) {
      return;
    }
    setState(() {
      _submittedKeyword = null;
      _errorMessage = null;
      _jobs.clear();
    });
  }

  Future<void> _handleSubmit([String? value]) async {
    final String normalized = (value ?? _searchController.text).trim();
    FocusScope.of(context).unfocus();
    if (normalized.isEmpty) {
      setState(() {
        _submittedKeyword = null;
        _errorMessage = null;
        _jobs.clear();
      });
      return;
    }

    setState(() {
      _submittedKeyword = normalized;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(jobServiceProvider)
          .listJobs(
            page: 1,
            pageSize: _pageSize,
            keyword: normalized,
            sort: 'latest',
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _jobs
          ..clear()
          ..addAll(result.list);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _jobs.clear();
        _errorMessage = _resolveErrorMessage(error);
      });
    }
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '招聘.岗位列表加载失败'.tr();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.jobs);
  }

  void _handleJobTap(JobListVO job) {
    context.push(
      RoutePaths.jobDetail,
      extra: JobDetailPageArgs(jobId: job.jobId),
    );
  }

  Future<void> _handleApply(JobListVO job) async {
    if (_submittingJobIds.contains(job.jobId) ||
        _appliedJobIds.contains(job.jobId)) {
      return;
    }

    setState(() {
      _submittingJobIds.add(job.jobId);
    });

    final JobApplySubmissionResult result = await submitJobApplication(
      context,
      jobId: job.jobId,
    );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _submittingJobIds.remove(job.jobId);
        _appliedJobIds.add(job.jobId);
      });
      AppToast.show('招聘.投递成功'.tr());
      return;
    }

    setState(() {
      _submittingJobIds.remove(job.jobId);
    });
    if (result.shouldShowError) {
      AppToast.show(result.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const AppSvgIcon(
            assetPath: _backAsset,
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: _SearchAppBarField(
          controller: _searchController,
          focusNode: _focusNode,
          searchAssetPath: _searchAsset,
          onSubmitted: _handleSubmit,
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _handleSubmit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF096DD9),
                minimumSize: const Size(52, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '通用.搜索'.tr(),
                style: TestStyle.pingFangRegular(fontSize: 15, color: Color(0xFF096DD9)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: JobSearchPageView(
          hasSubmittedKeyword: _hasSubmittedKeyword,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          jobs: _jobs,
          applyingJobIds: _submittingJobIds,
          appliedJobIds: _appliedJobIds,
          onTap: _handleJobTap,
          onApply: _handleApply,
          onRetry: _handleSubmit,
        ),
      ),
    );
  }
}

class _SearchAppBarField extends StatelessWidget {
  const _SearchAppBarField({
    required this.controller,
    required this.focusNode,
    required this.searchAssetPath,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchAssetPath;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          AppSvgIcon(
            assetPath: searchAssetPath,
            fallback: Icons.search_rounded,
            size: 16,
            color: const Color(0xFFBFBFBF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: const Color(0xFF096DD9),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF262626)),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '招聘.搜索岗位占位'.tr(),
                hintStyle: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFFBFBFBF)),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 9),
        ],
      ),
    );
  }
}
