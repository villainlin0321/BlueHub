import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_error_feedback.dart';
import '../../../config/data/config_models.dart';
import '../../../config/data/config_providers.dart';
import '../../../../shared/network/services/config_service.dart';
import '../../../../shared/logging/app_log_event.dart';
import '../../../../shared/logging/app_log_facade.dart';
import '../../../../shared/logging/app_logger.dart';
import '../../../../shared/models/app_currency.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';
import 'post_job_state.dart';

final postJobControllerProvider =
    NotifierProvider.autoDispose<PostJobController, PostJobState>(
      PostJobController.new,
    );

class PostJobFormDraft {
  const PostJobFormDraft({
    required this.title,
    required this.countryOrCity,
    required this.headcount,
    required this.minSalary,
    required this.maxSalary,
    required this.description,
  });

  final String title;
  final String countryOrCity;
  final String headcount;
  final String minSalary;
  final String maxSalary;
  final String description;
}

class PostJobEditInitialData {
  const PostJobEditInitialData({
    required this.title,
    required this.countryOrCity,
    required this.headcount,
    required this.minSalary,
    required this.maxSalary,
    required this.description,
  });

  final String title;
  final String countryOrCity;
  final String headcount;
  final String minSalary;
  final String maxSalary;
  final String description;
}

class PostJobController extends Notifier<PostJobState> {
  static const Set<String> _employmentTypes = <String>{
    'any',
    'full_time',
    'part_time',
  };
  static const Set<String> _salaryPeriods = <String>{
    'month',
    'week',
    'day',
    'hour',
  };
  static const Map<String, String> _countryCodeMap = <String, String>{
    '德国': 'DE',
    '法国': 'FR',
    '意大利': 'IT',
    '西班牙': 'ES',
    '葡萄牙': 'PT',
    '荷兰': 'NL',
    '比利时': 'BE',
    '奥地利': 'AT',
    '瑞士': 'CH',
    '波兰': 'PL',
    '捷克': 'CZ',
    '匈牙利': 'HU',
  };
  static final Map<String, String> _countryLabelKeyMap = _countryCodeMap.map(
    (String key, String value) => MapEntry<String, String>(value, '国家.$key'),
  );

  @override
  PostJobState build() {
    ref.onDispose(() {
      AppLogger.instance.info(
        'POST_JOB',
        'PostJobController 已销毁',
        context: <String, Object?>{'controllerHash': identityHashCode(this)},
      );
    });
    AppLogger.instance.info(
      'POST_JOB',
      'PostJobController 已创建',
      context: <String, Object?>{'controllerHash': identityHashCode(this)},
    );
    return const PostJobState();
  }

  Future<void> loadRequirementTags({bool force = false}) async {
    AppLogger.instance.info(
      'POST_JOB',
      '开始加载任职要求标签',
      context: <String, Object?>{
        'controllerHash': identityHashCode(this),
        'force': force,
        'isLoadingRequirementTags': state.isLoadingRequirementTags,
        'hasLoadedRequirementTags': state.hasLoadedRequirementTags,
        'tagCount': state.requirementTags.length,
      },
    );
    if (state.isLoadingRequirementTags) {
      AppLogger.instance.warn(
        'POST_JOB',
        '任职要求标签加载被跳过：已有请求进行中',
        context: <String, Object?>{
          'controllerHash': identityHashCode(this),
          'force': force,
          'isLoadingRequirementTags': state.isLoadingRequirementTags,
          'hasLoadedRequirementTags': state.hasLoadedRequirementTags,
        },
      );
      return;
    }
    if (state.hasLoadedRequirementTags && !force) {
      AppLogger.instance.info(
        'POST_JOB',
        '任职要求标签加载被跳过：已存在缓存',
        context: <String, Object?>{
          'controllerHash': identityHashCode(this),
          'force': force,
          'tagCount': state.requirementTags.length,
        },
      );
      return;
    }

    state = state.copyWith(
      isLoadingRequirementTags: true,
      requirementTagsError: null,
    );
    AppLogger.instance.info(
      'POST_JOB',
      '即将请求任职要求标签接口',
      context: <String, Object?>{
        'controllerHash': identityHashCode(this),
        'targetKey': TagCategory.requirement.value,
      },
    );

    try {
      final List<TagItemVO> tags = await ref
          .read(tagDictionaryCacheControllerProvider)
          .getTagsForCategory(TagCategory.requirement);
      state = state.copyWith(
        requirementTags: tags,
        hasLoadedRequirementTags: true,
        isLoadingRequirementTags: false,
      );
      AppLogger.instance.info(
        'POST_JOB',
        '任职要求标签加载成功',
        context: <String, Object?>{
          'controllerHash': identityHashCode(this),
          'tagCount': tags.length,
        },
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        isLoadingRequirementTags: false,
        requirementTagsError: '岗位发布.任职要求标签加载失败'.tr(),
      );
      AppLogger.instance.error(
        'POST_JOB',
        '任职要求标签加载失败',
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          'controllerHash': identityHashCode(this),
          'force': force,
        },
      );
    }
  }

  void preloadRequirementTags(List<TagItemVO> tags) {
    final List<TagItemVO> sortedTags = List<TagItemVO>.from(tags)
      ..sort((TagItemVO a, TagItemVO b) => a.sortOrder.compareTo(b.sortOrder));
    state = state.copyWith(
      requirementTags: sortedTags,
      hasLoadedRequirementTags: true,
      isLoadingRequirementTags: false,
      requirementTagsError: null,
    );
  }

  void setJobType(String value) {
    state = state.copyWith(selectedJobType: value);
  }

  void setSalaryUnit(String value) {
    state = state.copyWith(selectedSalaryUnit: value);
  }

  void setSalaryCurrency(AppCurrency value) {
    state = state.copyWith(selectedSalaryCurrency: value);
  }

  void toggleRequirementTag(String tagCode) {
    final Set<String> nextCodes = Set<String>.from(
      state.selectedRequirementTagCodes,
    );
    if (nextCodes.contains(tagCode)) {
      nextCodes.remove(tagCode);
    } else {
      nextCodes.add(tagCode);
    }
    state = state.copyWith(selectedRequirementTagCodes: nextCodes);
  }

  void addCustomTag(String input) {
    final String customTag = input.trim();
    if (customTag.isEmpty) {
      return;
    }

    if (state.customTags.contains(customTag)) {
      _emitFeedback('岗位发布.该自定义标签已添加'.tr(), isError: true);
      return;
    }

    state = state.copyWith(
      customTags: <String>[...state.customTags, customTag],
    );
  }

  void removeCustomTag(String tag) {
    state = state.copyWith(
      customTags: state.customTags
          .where((String item) => item != tag)
          .toList(growable: false),
    );
  }

  Future<void> saveDraft(
    PostJobFormDraft draft, {
    int? editingJobId,
  }) async {
    await _submit(draft, isDraft: true, editingJobId: editingJobId);
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  Future<void> publish(PostJobFormDraft draft, {int? editingJobId}) async {
    await _submit(draft, isDraft: false, editingJobId: editingJobId);
  }

  Future<void> _submit(
    PostJobFormDraft draft, {
    required bool isDraft,
    int? editingJobId,
  }) async {
    if (state.isPublishing) {
      return;
    }

    _logPublishValidationStart(
      draft: draft,
      isDraft: isDraft,
      editingJobId: editingJobId,
    );
    final CreateJobBO? request = _buildPublishRequest(
      draft,
      isDraft: isDraft,
      editingJobId: editingJobId,
    );
    if (request == null) {
      return;
    }

    state = state.copyWith(isPublishing: true);
    _logPublishRequestStart(isDraft: isDraft, editingJobId: editingJobId);

    try {
      if (editingJobId == null) {
        await ref.read(jobServiceProvider).createJob(request: request);
      } else {
        await ref
            .read(jobServiceProvider)
            .updateJob(jobId: editingJobId, request: request);
      }
      state = state.copyWith(
        isPublishing: false,
        publishSuccessId: state.publishSuccessId + 1,
      );
      _emitFeedback(
        editingJobId == null
            ? (isDraft ? '岗位发布.草稿已保存'.tr() : '岗位发布.岗位发布成功'.tr())
            : (isDraft ? '岗位发布.草稿已更新'.tr() : '岗位发布.岗位更新成功'.tr()),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(isPublishing: false);
      _logPublishRequestFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        error: error,
        stackTrace: stackTrace,
      );
      _emitFeedback(
        ApiErrorFeedback.resolveMessage(
          error,
          fallback: editingJobId == null
              ? (isDraft ? '岗位发布.草稿保存失败'.tr() : '岗位发布.岗位发布失败'.tr())
              : (isDraft ? '岗位发布.草稿更新失败'.tr() : '岗位发布.岗位更新失败'.tr()),
        ),
        isError: true,
      );
    }
  }

  Future<PostJobEditInitialData?> loadEditInitialData({
    required int jobId,
  }) async {
    try {
      if (!state.hasLoadedRequirementTags) {
        await loadRequirementTags();
      }

      final JobDetailVO detail = await ref
          .read(jobServiceProvider)
          .getJobDetail(jobId: jobId);
      return buildEditInitialData(detail);
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'POST_JOB',
        '岗位详情加载失败',
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{'jobId': jobId},
      );
      _emitFeedback(
        ApiErrorFeedback.resolveMessage(error, fallback: '岗位发布.岗位详情加载失败'.tr()),
        isError: true,
      );
      return null;
    }
  }

  PostJobEditInitialData buildEditInitialData(JobDetailVO detail) {
    final Set<String> selectedCodes = <String>{};
    final List<String> knownLabels = <String>[];
    final Set<String> detailLabels = <String>{
      ...detail.requirements.map((String item) => item.trim()),
      ...detail.tags.map((TagVO item) => item.label.trim()),
    }..removeWhere((String item) => item.isEmpty);

    for (final TagItemVO tag in state.requirementTags) {
      final String label = tagLabel(tag);
      if (detailLabels.contains(label)) {
        selectedCodes.add(tag.tagCode);
        knownLabels.add(label);
      }
    }

    final Set<String> knownLabelSet = knownLabels.toSet();
    final List<String> customTags = detail.requirements
        .map((String item) => item.trim())
        .where(
          (String item) => item.isNotEmpty && !knownLabelSet.contains(item),
        )
        .toList(growable: false);

    state = state.copyWith(
      selectedJobType: _employmentTypes.contains(detail.employmentType)
          ? detail.employmentType
          : state.selectedJobType,
      selectedSalaryUnit: _salaryPeriods.contains(detail.salaryPeriod)
          ? detail.salaryPeriod
          : state.selectedSalaryUnit,
      selectedSalaryCurrency: AppCurrency.fromApiValue(
        detail.salaryCurrency,
        fallback: AppCurrency.eur,
      ),
      selectedRequirementTagCodes: selectedCodes,
      customTags: customTags,
    );

    return PostJobEditInitialData(
      title: detail.title,
      countryOrCity: _composeLocation(detail),
      headcount: detail.headcount > 0 ? detail.headcount.toString() : '',
      minSalary: _formatNumber(detail.salaryMin),
      maxSalary: _formatNumber(detail.salaryMax),
      description: detail.description,
    );
  }

  String tagLabel(TagItemVO tag) {
    if (tag.tagNameZh.trim().isNotEmpty) {
      return tag.tagNameZh.trim();
    }
    return tag.tagNameEn.trim();
  }

  /// 构建发布请求，并在校验失败时直接输出结构化失败日志与可展示提示。
  CreateJobBO? _buildPublishRequest(
    PostJobFormDraft draft, {
    required bool isDraft,
    int? editingJobId,
  }) {
    final String title = draft.title.trim();
    if (title.isEmpty) {
      _logPublishValidationFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: 'title_required',
        field: 'title',
      );
      _emitFeedback('岗位发布.请填写套餐名称'.tr(), isError: true);
      return null;
    }

    final _JobLocationDraft location = _parseLocation(draft.countryOrCity);
    final String countryCode = _normalizeCountryCode(location.countryText);
    if (countryCode.isEmpty) {
      _logPublishValidationFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: 'country_required',
        field: 'countryOrCity',
      );
      _emitFeedback('岗位发布.请填写服务国家'.tr(), isError: true);
      return null;
    }

    final int? headcount = int.tryParse(draft.headcount.trim());
    if (headcount == null || headcount <= 0) {
      _logPublishValidationFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: 'headcount_invalid',
        field: 'headcount',
      );
      _emitFeedback('岗位发布.请填写正确的招聘人数'.tr(), isError: true);
      return null;
    }

    final double? salaryMin = double.tryParse(draft.minSalary.trim());
    final double? salaryMax = double.tryParse(draft.maxSalary.trim());
    if (salaryMin == null || salaryMax == null) {
      _logPublishValidationFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: 'salary_incomplete',
        field: 'salaryRange',
      );
      _emitFeedback('岗位发布.请填写完整的薪资范围'.tr(), isError: true);
      return null;
    }
    if (salaryMin > salaryMax) {
      _logPublishValidationFail(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: 'salary_range_invalid',
        field: 'salaryRange',
      );
      _emitFeedback('岗位发布.最低薪资不能大于最高薪资'.tr(), isError: true);
      return null;
    }

    final List<TagItemVO> selectedRequirementTags = state.requirementTags
        .where(
          (TagItemVO tag) =>
              state.selectedRequirementTagCodes.contains(tag.tagCode),
        )
        .toList(growable: false);
    final List<String> requirements = <String>[
      ...selectedRequirementTags.map(tagLabel),
      ...state.customTags,
    ];

    return CreateJobBO(
      title: title,
      country: countryCode,
      city: location.city,
      address: location.address,
      latitude: 0,
      longitude: 0,
      headcount: headcount,
      employmentType: _employmentTypes.contains(state.selectedJobType)
          ? state.selectedJobType
          : 'any',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      salaryCurrency: state.selectedSalaryCurrency.apiValue,
      salaryPeriod: _salaryPeriods.contains(state.selectedSalaryUnit)
          ? state.selectedSalaryUnit
          : 'month',
      requirementTags: selectedRequirementTags
          .map((TagItemVO tag) => tag.tagCode)
          .toList(growable: false),
      customTags: state.customTags,
      highlightTags: const <String>[],
      hasVisaSupport: false,
      isUrgent: false,
      responsibilities: const <String>[],
      requirements: requirements,
      benefits: const <String>[],
      description: draft.description.trim(),
      isDraft: isDraft,
    );
  }

  String _normalizeCountryCode(String value) {
    final String input = value.trim();
    if (input.isEmpty) {
      return '';
    }

    final String upperInput = input.toUpperCase();
    if (RegExp(r'^[A-Z]{2}$').hasMatch(upperInput)) {
      return upperInput;
    }

    return _countryCodeMap[input] ?? '';
  }

  String _composeLocation(JobDetailVO detail) {
    if (detail.address.trim().isNotEmpty) {
      return detail.address.trim();
    }
    final String countryKey = _countryLabelKeyMap[detail.country] ?? '';
    final String country = countryKey.isEmpty
        ? detail.country
        : countryKey.tr();
    final List<String> parts = <String>[
      country.trim(),
      detail.city.trim(),
    ].where((String item) => item.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }

  String _formatNumber(double value) {
    if (value <= 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  _JobLocationDraft _parseLocation(String value) {
    final String input = value.trim();
    if (input.isEmpty) {
      return const _JobLocationDraft(countryText: '', city: '', address: '');
    }

    final Iterable<String> parts = input
        .split(RegExp(r'[·•,/，\s]+'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty);
    final List<String> tokens = parts.toList(growable: false);
    if (tokens.length >= 2) {
      return _JobLocationDraft(
        countryText: tokens.first,
        city: tokens.sublist(1).join(' '),
        address: input,
      );
    }

    for (final MapEntry<String, String> entry in _countryCodeMap.entries) {
      if (input.startsWith(entry.key) && input.length > entry.key.length) {
        return _JobLocationDraft(
          countryText: entry.key,
          city: input.substring(entry.key.length).trim(),
          address: input,
        );
      }
    }

    return _JobLocationDraft(countryText: input, city: '', address: input);
  }

  void _emitFeedback(String message, {bool isError = false}) {
    state = state.copyWith(
      feedbackMessage: message,
      feedbackIsError: isError,
      feedbackId: state.feedbackId + 1,
    );
  }

  /// 记录岗位发布校验开始事件，便于回放一次发布是从哪个模式进入校验流程。
  void _logPublishValidationStart({
    required PostJobFormDraft draft,
    required bool isDraft,
    required int? editingJobId,
  }) {
    StateLog.transition(
      event: 'POST_JOB_VALIDATE_START',
      message: isDraft ? '开始校验岗位草稿表单' : '开始校验岗位发布表单',
      result: AppLogResult.pending,
      context: _buildPublishLogContext(
        draft: draft,
        isDraft: isDraft,
        editingJobId: editingJobId,
      ),
    );
  }

  /// 记录岗位发布校验失败事件，只保留失败原因和字段名等安全上下文。
  void _logPublishValidationFail({
    required bool isDraft,
    required int? editingJobId,
    required String reason,
    required String field,
  }) {
    StateLog.transition(
      event: 'POST_JOB_VALIDATE_FAIL',
      message: isDraft ? '岗位草稿表单校验失败' : '岗位发布表单校验失败',
      level: AppLogLevel.warn,
      result: AppLogResult.fail,
      context: _buildPublishLogContext(
        isDraft: isDraft,
        editingJobId: editingJobId,
        reason: reason,
        field: field,
      ),
    );
  }

  /// 记录岗位发布请求开始事件，确保后续请求成功或失败都能挂到同一条链路上。
  void _logPublishRequestStart({
    required bool isDraft,
    required int? editingJobId,
  }) {
    StateLog.transition(
      event: 'POST_JOB_SUBMIT_REQUEST_START',
      message: editingJobId == null
          ? (isDraft ? '开始请求岗位草稿保存接口' : '开始请求岗位发布接口')
          : (isDraft ? '开始请求岗位草稿更新接口' : '开始请求岗位更新接口'),
      result: AppLogResult.pending,
      context: _buildPublishLogContext(
        isDraft: isDraft,
        editingJobId: editingJobId,
      ),
    );
  }

  /// 记录岗位发布请求失败事件，保留编辑态与异常信息方便本地排障。
  void _logPublishRequestFail({
    required bool isDraft,
    required int? editingJobId,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'POST_JOB_SUBMIT_REQUEST_FAIL',
      message: editingJobId == null
          ? (isDraft ? '岗位草稿保存请求失败' : '岗位发布请求失败')
          : (isDraft ? '岗位草稿更新请求失败' : '岗位更新请求失败'),
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      context: _buildPublishLogContext(
        isDraft: isDraft,
        editingJobId: editingJobId,
      ),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 统一构建岗位发布日志上下文，只输出排障所需且不含表单原文的安全字段。
  Map<String, Object?> _buildPublishLogContext({
    PostJobFormDraft? draft,
    required bool isDraft,
    required int? editingJobId,
    String? reason,
    String? field,
  }) {
    final bool isEdit = editingJobId != null;
    return <String, Object?>{
      'mode': isEdit ? 'edit' : 'create',
      'isEdit': isEdit,
      'submitType': isDraft ? 'draft' : 'publish',
      if (editingJobId != null) 'editingJobId': editingJobId,
      'selectedJobType': state.selectedJobType,
      'salaryUnit': state.selectedSalaryUnit,
      'salaryCurrency': state.selectedSalaryCurrency.apiValue,
      'selectedRequirementTagCount': state.selectedRequirementTagCodes.length,
      'customTagCount': state.customTags.length,
      if (draft != null) ...<String, Object?>{
        // 这里仅记录“是否填写/数量”类安全信息，避免把表单原文写进日志。
        'titleFilled': draft.title.trim().isNotEmpty,
        'locationFilled': draft.countryOrCity.trim().isNotEmpty,
        'headcountFilled': draft.headcount.trim().isNotEmpty,
        'salaryRangeFilled':
            draft.minSalary.trim().isNotEmpty &&
            draft.maxSalary.trim().isNotEmpty,
        'descriptionLength': draft.description.trim().length,
      },
      if (reason != null) 'reason': reason,
      if (field != null) 'field': field,
    };
  }
}

class _JobLocationDraft {
  const _JobLocationDraft({
    required this.countryText,
    required this.city,
    required this.address,
  });

  final String countryText;
  final String city;
  final String address;
}
