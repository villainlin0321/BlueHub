import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/data/config_models.dart';
import '../../../config/data/config_providers.dart';
import '../../../../shared/network/services/config_service.dart';
import '../../../../shared/logging/app_logger.dart';
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
  static const Map<String, String> _employmentTypeMap = <String, String>{
    '不限': 'any',
    '全职': 'full_time',
    '兼职': 'part_time',
  };
  static const Map<String, String> _salaryPeriodMap = <String, String>{
    '月薪': 'month',
    '周薪': 'week',
    '日薪': 'day',
    '时薪': 'hour',
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
  static final Map<String, String> _employmentTypeReverseMap =
      _employmentTypeMap.map(
        (String key, String value) => MapEntry<String, String>(value, key),
      );
  static final Map<String, String> _salaryPeriodReverseMap = _salaryPeriodMap
      .map((String key, String value) => MapEntry<String, String>(value, key));
  static final Map<String, String> _countryNameMap = _countryCodeMap.map(
    (String key, String value) => MapEntry<String, String>(value, key),
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
      final TagDictVO response = await ref
          .read(configServiceProvider)
          .getTags();
      final List<TagItemVO> tags = List<TagItemVO>.from(
        response.tags[TagCategory.requirement.value] ?? const <TagItemVO>[],
      )..sort((TagItemVO a, TagItemVO b) => a.sortOrder.compareTo(b.sortOrder));
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
        requirementTagsError: '任职要求标签加载失败',
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
      _emitFeedback('该自定义标签已添加', isError: true);
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

  void saveDraft() {
    _emitFeedback('草稿已保存');
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  Future<void> publish(PostJobFormDraft draft, {int? editingJobId}) async {
    if (state.isPublishing) {
      return;
    }

    final CreateJobBO? request = _buildPublishRequest(draft);
    if (request == null) {
      return;
    }

    state = state.copyWith(isPublishing: true);

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
      _emitFeedback(editingJobId == null ? '岗位发布成功' : '岗位更新成功');
    } catch (_) {
      state = state.copyWith(isPublishing: false);
      _emitFeedback(
        editingJobId == null ? '岗位发布失败，请稍后重试' : '岗位更新失败，请稍后重试',
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
      _emitFeedback('岗位详情加载失败，请稍后重试', isError: true);
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
      selectedJobType:
          _employmentTypeReverseMap[detail.employmentType] ??
          state.selectedJobType,
      selectedSalaryUnit:
          _salaryPeriodReverseMap[detail.salaryPeriod] ??
          state.selectedSalaryUnit,
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

  CreateJobBO? _buildPublishRequest(PostJobFormDraft draft) {
    final String title = draft.title.trim();
    if (title.isEmpty) {
      _emitFeedback('请填写套餐名称', isError: true);
      return null;
    }

    final _JobLocationDraft location = _parseLocation(draft.countryOrCity);
    final String countryCode = _normalizeCountryCode(location.countryText);
    if (countryCode.isEmpty) {
      _emitFeedback('请填写服务国家，示例：德国·柏林 或 DE', isError: true);
      return null;
    }

    final int? headcount = int.tryParse(draft.headcount.trim());
    if (headcount == null || headcount <= 0) {
      _emitFeedback('请填写正确的招聘人数', isError: true);
      return null;
    }

    final double? salaryMin = double.tryParse(draft.minSalary.trim());
    final double? salaryMax = double.tryParse(draft.maxSalary.trim());
    if (salaryMin == null || salaryMax == null) {
      _emitFeedback('请填写完整的薪资范围', isError: true);
      return null;
    }
    if (salaryMin > salaryMax) {
      _emitFeedback('最低薪资不能大于最高薪资', isError: true);
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
      employmentType: _employmentTypeMap[state.selectedJobType] ?? 'any',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      salaryCurrency: 'EUR',
      salaryPeriod: _salaryPeriodMap[state.selectedSalaryUnit] ?? 'month',
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
      isDraft: false,
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
    final String country = _countryNameMap[detail.country] ?? detail.country;
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
