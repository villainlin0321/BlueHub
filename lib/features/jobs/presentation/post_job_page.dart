import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/logging/app_logger.dart';
import '../application/post_job/post_job_controller.dart';
import '../application/post_job/post_job_state.dart';
import 'widgets/post_job_page_view.dart';

class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key});

  @override
  ConsumerState<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends ConsumerState<PostJobPage> {
  static const List<String> _jobTypes = <String>['不限', '全职', '兼职'];
  static const List<String> _salaryUnits = <String>['月薪', '周薪', '日薪', '时薪'];

  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _headcountController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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
      ref.read(postJobControllerProvider.notifier).loadRequirementTags();
    });
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submitCustomTag() {
    ref.read(postJobControllerProvider.notifier).addCustomTag(
      _customTagController.text,
    );
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
    await ref.read(postJobControllerProvider.notifier).publish(_buildFormDraft());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PostJobState>(postJobControllerProvider, (
      PostJobState? previous,
      PostJobState next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showSnackBar(next.feedbackMessage!);
        ref.read(postJobControllerProvider.notifier).clearFeedback();
      }

      if (previous?.publishSuccessId != next.publishSuccessId &&
          next.publishSuccessId > 0) {
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

    return PostJobPageView(
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
