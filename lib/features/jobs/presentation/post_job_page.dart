import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../config/data/config_models.dart';
import '../../../shared/logging/app_logger.dart';
import '../data/job_models.dart';
import '../data/job_providers.dart';
import '../application/post_job/post_job_controller.dart';
import '../application/post_job/post_job_state.dart';
import 'widgets/post_job_page_view.dart';

enum PostJobPageMode { create, edit }

class PostJobPageArgs {
  const PostJobPageArgs.create()
    : mode = PostJobPageMode.create,
      jobId = null,
      prefetchedRequirementTags = null,
      prefetchedJobDetail = null;

  const PostJobPageArgs.edit({
    required this.jobId,
    this.prefetchedRequirementTags,
    this.prefetchedJobDetail,
  }) : mode = PostJobPageMode.edit;

  final PostJobPageMode mode;
  final int? jobId;
  final List<TagItemVO>? prefetchedRequirementTags;
  final JobDetailVO? prefetchedJobDetail;

  bool get isEdit => mode == PostJobPageMode.edit && jobId != null;
}

class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key, this.args = const PostJobPageArgs.create()});

  final PostJobPageArgs args;

  @override
  ConsumerState<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends ConsumerState<PostJobPage> {
  static const List<String> _jobTypes = <String>[
    'any',
    'full_time',
    'part_time',
  ];
  static const List<String> _salaryUnits = <String>[
    'month',
    'week',
    'day',
    'hour',
  ];

  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _headcountController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoadingEditData = false;
  bool _hasHydratedEditData = false;
  String? _editLoadError;

  @override
  void initState() {
    super.initState();
    final PostJobState currentState = ref.read(postJobControllerProvider);
    AppLogger.instance.info(
      'POST_JOB',
      'PostJobPage initState 触发标签加载',
      context: <String, Object?>{
        'isLoadingRequirementTags': currentState.isLoadingRequirementTags,
        'hasLoadedRequirementTags': currentState.hasLoadedRequirementTags,
        'tagCount': currentState.requirementTags.length,
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      AppLogger.instance.info('POST_JOB', '首帧完成，开始触发标签加载');
      _bootstrapPage();
    });
  }

  Future<void> _bootstrapPage() async {
    final PostJobController controller = ref.read(
      postJobControllerProvider.notifier,
    );
    if (widget.args.prefetchedRequirementTags case final List<TagItemVO> tags) {
      controller.preloadRequirementTags(tags);
    } else {
      await controller.loadRequirementTags();
    }
    if (!widget.args.isEdit || _hasHydratedEditData) {
      return;
    }
    await _loadEditJob();
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _countryController.dispose();
    _headcountController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _customTagController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    AppToast.show(message);
  }

  /// 加载编辑态需要的岗位详情，并把接口数据回填到表单控制器。
  Future<void> _loadEditJob() async {
    final int? jobId = widget.args.jobId;
    if (jobId == null || _isLoadingEditData) {
      return;
    }

    setState(() {
      _isLoadingEditData = true;
      _editLoadError = null;
    });

    final PostJobEditInitialData? initialData =
        widget.args.prefetchedJobDetail != null
        ? ref
              .read(postJobControllerProvider.notifier)
              .buildEditInitialData(widget.args.prefetchedJobDetail!)
        : await ref
              .read(postJobControllerProvider.notifier)
              .loadEditInitialData(jobId: jobId);

    if (!mounted) {
      return;
    }

    if (initialData == null) {
      setState(() {
        _isLoadingEditData = false;
        _editLoadError = '岗位发布.岗位详情加载失败'.tr();
      });
      return;
    }

    _packageNameController.text = initialData.title;
    _countryController.text = initialData.countryOrCity;
    _headcountController.text = initialData.headcount;
    _minSalaryController.text = initialData.minSalary;
    _maxSalaryController.text = initialData.maxSalary;
    _descriptionController.text = initialData.description;
    _customTagController.clear();

    setState(() {
      _isLoadingEditData = false;
      _hasHydratedEditData = true;
      _editLoadError = null;
    });
  }

  void _submitCustomTag() {
    ref
        .read(postJobControllerProvider.notifier)
        .addCustomTag(_customTagController.text);
    _customTagController.clear();
  }

  PostJobFormDraft _buildFormDraft() {
    return PostJobFormDraft(
      title: _packageNameController.text,
      countryOrCity: _countryController.text,
      headcount: _headcountController.text,
      minSalary: _minSalaryController.text,
      maxSalary: _maxSalaryController.text,
      description: _descriptionController.text,
    );
  }

  Future<void> _handlePublish() async {
    FocusScope.of(context).unfocus();
    _submitCustomTag();
    await ref
        .read(postJobControllerProvider.notifier)
        .publish(_buildFormDraft(), editingJobId: widget.args.jobId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostJobState>(postJobControllerProvider, (
      PostJobState? previous,
      PostJobState next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showToast(next.feedbackMessage!);
        ref.read(postJobControllerProvider.notifier).clearFeedback();
      }

      if (previous?.publishSuccessId != next.publishSuccessId &&
          next.publishSuccessId > 0) {
        ref.read(companyJobListRefreshTickProvider.notifier).notifyChanged();
        if (Navigator.of(context).canPop()) {
          context.pop(true);
        } else {
          context.go(RoutePaths.jobs);
        }
      }
    });

    final PostJobState state = ref.watch(postJobControllerProvider);
    final PostJobController controller = ref.read(
      postJobControllerProvider.notifier,
    );

    if (widget.args.isEdit && _isLoadingEditData && !_hasHydratedEditData) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('岗位发布.编辑岗位'.tr()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.args.isEdit && _editLoadError != null && !_hasHydratedEditData) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('岗位发布.编辑岗位'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _editLoadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadEditJob,
                  child: Text('通用.重试'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PostJobPageView(
      title: widget.args.isEdit ? '岗位发布.编辑岗位'.tr() : '岗位发布.发布岗位'.tr(),
      publishButtonLabel: '岗位发布.立即发布'.tr(),
      packageNameController: _packageNameController,
      countryController: _countryController,
      headcountController: _headcountController,
      minSalaryController: _minSalaryController,
      maxSalaryController: _maxSalaryController,
      customTagController: _customTagController,
      descriptionController: _descriptionController,
      jobTypes: _jobTypes,
      salaryUnits: _salaryUnits,
      selectedJobType: state.selectedJobType,
      selectedSalaryUnit: state.selectedSalaryUnit,
      requirementTags: state.requirementTags,
      selectedRequirementTagCodes: state.selectedRequirementTagCodes,
      customTags: state.customTags,
      isLoadingRequirementTags: state.isLoadingRequirementTags,
      requirementTagsError: state.requirementTagsError,
      isPublishing: state.isPublishing,
      onBack: () => Navigator.of(context).maybePop(),
      onSaveDraft: controller.saveDraft,
      onPublish: _handlePublish,
      onRetryLoadRequirementTags: () =>
          controller.loadRequirementTags(force: true),
      onJobTypeChanged: controller.setJobType,
      onSalaryUnitChanged: controller.setSalaryUnit,
      onRequirementTagTap: controller.toggleRequirementTag,
      onRemoveCustomTag: controller.removeCustomTag,
      onCustomTagSubmitted: (_) => _submitCustomTag(),
      tagLabelBuilder: controller.tagLabel,
    );
  }
}
