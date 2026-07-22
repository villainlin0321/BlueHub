import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/models/dictionary_models.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/app_currency_bottom_sheet.dart';
import '../../../../shared/widgets/field_trailing_selector.dart';
import '../../../me/data/dictionary_providers.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';
import '../job_apply_helper.dart';
import '../job_detail_page.dart';
import '../widgets/filter_bottom_sheet_chip.dart';
import '../widgets/job_list_cards.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 求职者招聘页：严格按 Figma 还原搜索、筛选和职位列表。
class JobSeekerJobsPage extends ConsumerWidget {
  const JobSeekerJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const JobSeekerPageBackground(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: _JobsPageBody(),
    );
  }
}

class _JobsPageBody extends ConsumerStatefulWidget {
  const _JobsPageBody();

  @override
  ConsumerState<_JobsPageBody> createState() => _JobsPageBodyState();
}

class _JobsPageBodyState extends ConsumerState<_JobsPageBody> {
  static const int _pageSize = 20;
  static const List<_SalaryRangeOption> _salaryRangeOptions =
      <_SalaryRangeOption>[
        _SalaryRangeOption(key: '', labelKey: '招聘.薪资要求'),
        _SalaryRangeOption(key: '0-1500', label: '0~1500', min: 0, max: 1500),
        _SalaryRangeOption(
          key: '1500-2500',
          label: '1500~2500',
          min: 1500,
          max: 2500,
        ),
        _SalaryRangeOption(key: '2500+', labelKey: '招聘.薪资2500以上', min: 2500),
      ];
  static const List<_SortOption> _sortOptions = <_SortOption>[
    _SortOption(key: 'latest', labelKey: '招聘.最新'),
    _SortOption(key: 'salary_desc', labelKey: '招聘.薪资降序'),
    _SortOption(key: 'salary_asc', labelKey: '招聘.薪资升序'),
  ];

  final List<JobListVO> _jobs = <JobListVO>[];
  final Set<int> _submittingJobIds = <int>{};
  final Set<int> _appliedJobIds = <int>{};
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _initialErrorMessage;
  String? _selectedCountryCode;
  String? _selectedPositionKeyword;
  String? _selectedSalaryRangeKey;
  double? _selectedCustomSalaryMin;
  double? _selectedCustomSalaryMax;
  AppCurrency _selectedSalaryCurrency = AppCurrency.eur;
  final String _selectedSortKey = _sortOptions.first.key;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<PageResult<CountryVO>> countriesAsync = ref.watch(
      countrySearchProvider(const CountrySearchQuery(page: 1, pageSize: 200)),
    );
    final AsyncValue<List<PositionCategoryVO>> positionTreeAsync = ref.watch(
      positionTreeProvider(null),
    );
    final List<CountryVO> countries =
        countriesAsync.asData?.value.list ?? const <CountryVO>[];
    final List<PositionVO> positions = _flattenPositions(
      positionTreeAsync.asData?.value ?? const <PositionCategoryVO>[],
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 16, 0),
            child: Text(
              '招聘.欧洲招聘'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 17,
                color: Color(0xFF000000),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const _JobsSearchBar(),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _FilterRow(
              countries: countries,
              positions: positions,
              salaryRanges: _salaryRangeOptions,
              selectedCountryCode: _selectedCountryCode,
              selectedPositionKeyword: _selectedPositionKeyword,
              selectedSalaryRangeKey: _selectedSalaryRangeKey,
              selectedCustomSalaryMin: _selectedCustomSalaryMin,
              selectedCustomSalaryMax: _selectedCustomSalaryMax,
              selectedSalaryCurrency: _selectedSalaryCurrency,
              isCountryEnabled: countriesAsync.hasValue,
              isPositionEnabled: positionTreeAsync.hasValue,
              onCountryChanged: _handleCountryChanged,
              onPositionChanged: _handlePositionChanged,
              onSalaryFilterChanged: _handleSalaryFilterChanged,
              onCombinedFilterChanged: _handleCombinedFilterChanged,
            ),
          ),
          const SizedBox(height: 19),
          Expanded(
            child: EasyRefresh(
              onRefresh: _handleRefresh,
              onLoad: _hasNext && _jobs.isNotEmpty ? _handleLoadMore : null,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  _JobsListSection(
                    jobs: _jobs,
                    isInitialLoading: _isInitialLoading,
                    initialErrorMessage: _initialErrorMessage,
                    onRetry: _loadInitialJobs,
                    applyingJobIds: _submittingJobIds,
                    appliedJobIds: _appliedJobIds,
                    onApply: _handleApply,
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomPadding + 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 首次进入页面时拉取首屏岗位数据。
  Future<void> _loadInitialJobs() async {
    await _fetchJobs(reset: true, showFullscreenLoading: true);
  }

  /// 处理下拉刷新，重新从第一页拉取岗位列表。
  Future<void> _handleRefresh() async {
    await _fetchJobs(reset: true, showFullscreenLoading: false);
  }

  /// 处理上拉加载，按页码继续追加岗位数据。
  Future<void> _handleLoadMore() async {
    if (_isLoadingMore || _isRefreshing || !_hasNext) {
      return;
    }
    await _fetchJobs(reset: false, showFullscreenLoading: false);
  }

  /// 切换国家筛选后重新请求岗位列表。
  void _handleCountryChanged(String? value) {
    final String? countryCode = _normalizeFilterValue(value);
    if (_selectedCountryCode == countryCode) {
      return;
    }
    setState(() {
      _selectedCountryCode = countryCode;
    });
    FocusScope.of(context).unfocus();
    _fetchJobs(reset: true, showFullscreenLoading: _jobs.isEmpty);
  }

  /// 当前岗位列表接口没有显式职位参数，先将职位名称拼到关键字中过滤。
  void _handlePositionChanged(String? value) {
    final String? positionKeyword = _normalizeFilterValue(value);
    if (_selectedPositionKeyword == positionKeyword) {
      return;
    }
    setState(() {
      _selectedPositionKeyword = positionKeyword;
    });
    FocusScope.of(context).unfocus();
    _fetchJobs(reset: true, showFullscreenLoading: _jobs.isEmpty);
  }

  /// 应用薪资筛选后重新请求岗位列表。
  void _handleSalaryFilterChanged(_SalaryFilterSelection selection) {
    final String? rangeKey = _normalizeFilterValue(selection.presetKey);
    if (_selectedSalaryRangeKey == rangeKey &&
        _selectedCustomSalaryMin == selection.customMin &&
        _selectedCustomSalaryMax == selection.customMax &&
        _selectedSalaryCurrency == selection.salaryCurrency) {
      return;
    }
    final bool shouldRefresh =
        _selectedSalaryRangeKey != rangeKey ||
        _selectedCustomSalaryMin != selection.customMin ||
        _selectedCustomSalaryMax != selection.customMax ||
        _selectedSalaryCurrency != selection.salaryCurrency;
    setState(() {
      _selectedSalaryRangeKey = rangeKey;
      _selectedCustomSalaryMin = selection.customMin;
      _selectedCustomSalaryMax = selection.customMax;
      _selectedSalaryCurrency = selection.salaryCurrency;
    });
    if (!shouldRefresh) {
      return;
    }
    FocusScope.of(context).unfocus();
    _fetchJobs(reset: true, showFullscreenLoading: _jobs.isEmpty);
  }

  /// 一次性应用国家、职位、薪资综合筛选后刷新岗位列表。
  void _handleCombinedFilterChanged(_CombinedJobFilterSelection selection) {
    final String? nextCountryCode = _normalizeFilterValue(
      selection.countryCode,
    );
    final String? nextPositionKeyword = _normalizeFilterValue(
      selection.positionKeyword,
    );
    final String? nextSalaryRangeKey = _normalizeFilterValue(
      selection.salarySelection.presetKey,
    );
    if (_selectedCountryCode == nextCountryCode &&
        _selectedPositionKeyword == nextPositionKeyword &&
        _selectedSalaryRangeKey == nextSalaryRangeKey &&
        _selectedCustomSalaryMin == selection.salarySelection.customMin &&
        _selectedCustomSalaryMax == selection.salarySelection.customMax &&
        _selectedSalaryCurrency == selection.salaryCurrency) {
      return;
    }
    final bool shouldRefresh =
        _selectedCountryCode != nextCountryCode ||
        _selectedPositionKeyword != nextPositionKeyword ||
        _selectedSalaryRangeKey != nextSalaryRangeKey ||
        _selectedCustomSalaryMin != selection.salarySelection.customMin ||
        _selectedCustomSalaryMax != selection.salarySelection.customMax ||
        _selectedSalaryCurrency != selection.salaryCurrency;
    setState(() {
      _selectedCountryCode = nextCountryCode;
      _selectedPositionKeyword = nextPositionKeyword;
      _selectedSalaryRangeKey = nextSalaryRangeKey;
      _selectedCustomSalaryMin = selection.salarySelection.customMin;
      _selectedCustomSalaryMax = selection.salarySelection.customMax;
      _selectedSalaryCurrency = selection.salaryCurrency;
    });
    if (!shouldRefresh) {
      return;
    }
    FocusScope.of(context).unfocus();
    _fetchJobs(reset: true, showFullscreenLoading: _jobs.isEmpty);
  }

  /// 请求岗位列表，并根据刷新/加载更多场景合并页面状态。
  Future<void> _fetchJobs({
    required bool reset,
    required bool showFullscreenLoading,
  }) async {
    if (_isRefreshing || _isLoadingMore) {
      return;
    }

    if (mounted) {
      setState(() {
        if (reset) {
          _isRefreshing = !showFullscreenLoading;
          _initialErrorMessage = null;
          if (showFullscreenLoading) {
            _isInitialLoading = true;
          }
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final result = await ref
          .read(jobServiceProvider)
          .listJobs(
            page: reset ? 1 : _currentPage + 1,
            pageSize: _pageSize,
            country: _selectedCountryCode,
            keyword: _buildKeywordQuery(),
            salaryMin: _effectiveSalaryMin,
            salaryMax: _effectiveSalaryMax,
            currency: _selectedSalaryCurrency.apiValue,
            sort: _selectedSortKey,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPage = result.pagination.page;
        _hasNext = result.pagination.hasNext;
        _isInitialLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _initialErrorMessage = null;
        if (reset) {
          _jobs
            ..clear()
            ..addAll(result.list);
        } else {
          _jobs.addAll(result.list);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final String message = _resolveErrorMessage(error);
      setState(() {
        _isInitialLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        if (_jobs.isEmpty) {
          _initialErrorMessage = message;
        }
      });
      if (_jobs.isNotEmpty) {
        AppToast.show(message);
      }
    }
  }

  /// 提取接口异常文案，统一页面侧错误提示口径。
  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '招聘.岗位列表加载失败'.tr();
  }

  String? _normalizeFilterValue(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// 组合搜索框关键字与职位筛选，统一复用岗位列表接口的 keyword 参数。
  String? _buildKeywordQuery() {
    return _selectedPositionKeyword;
  }

  _SalaryRangeOption? get _selectedSalaryRange {
    final String? key = _selectedSalaryRangeKey;
    if (key == null) {
      return null;
    }
    for (final _SalaryRangeOption option in _salaryRangeOptions) {
      if (option.key == key) {
        return option;
      }
    }
    return null;
  }

  double? get _effectiveSalaryMin =>
      _selectedSalaryRange?.min ?? _selectedCustomSalaryMin;

  double? get _effectiveSalaryMax =>
      _selectedSalaryRange?.max ?? _selectedCustomSalaryMax;

  List<PositionVO> _flattenPositions(List<PositionCategoryVO> categories) {
    final Set<String> seenLabels = <String>{};
    final List<PositionVO> positions = <PositionVO>[];
    for (final PositionCategoryVO category in categories) {
      for (final PositionVO position in category.positions) {
        final String label = position.nameZh.trim();
        if (label.isEmpty || !seenLabels.add(label)) {
          continue;
        }
        positions.add(position);
      }
    }
    return positions;
  }

  /// 提交岗位投递请求，并根据结果更新按钮状态与页面提示。
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
}

class _JobsSearchBar extends StatelessWidget {
  const _JobsSearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.jobSearch),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              const AppSvgIcon(
                assetPath: 'assets/images/mou2x9mw-2jfef5b.svg',
                fallback: Icons.search_rounded,
                size: 16,
                color: Color(0xFFBFBFBF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '招聘.搜索岗位占位'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TestStyle.pingFangRegular(
                    fontSize: 14,
                    color: Color(0xFFBFBFBF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.countries,
    required this.positions,
    required this.salaryRanges,
    required this.selectedCountryCode,
    required this.selectedPositionKeyword,
    required this.selectedSalaryRangeKey,
    required this.selectedCustomSalaryMin,
    required this.selectedCustomSalaryMax,
    required this.selectedSalaryCurrency,
    required this.isCountryEnabled,
    required this.isPositionEnabled,
    required this.onCountryChanged,
    required this.onPositionChanged,
    required this.onSalaryFilterChanged,
    required this.onCombinedFilterChanged,
  });

  final List<CountryVO> countries;
  final List<PositionVO> positions;
  final List<_SalaryRangeOption> salaryRanges;
  final String? selectedCountryCode;
  final String? selectedPositionKeyword;
  final String? selectedSalaryRangeKey;
  final double? selectedCustomSalaryMin;
  final double? selectedCustomSalaryMax;
  final AppCurrency selectedSalaryCurrency;
  final bool isCountryEnabled;
  final bool isPositionEnabled;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onPositionChanged;
  final ValueChanged<_SalaryFilterSelection> onSalaryFilterChanged;
  final ValueChanged<_CombinedJobFilterSelection> onCombinedFilterChanged;

  @override
  Widget build(BuildContext context) {
    final List<_DropdownOption> countryOptions = <_DropdownOption>[
      _DropdownOption(value: '', label: '招聘.全部国家'.tr()),
      ...countries.map(
        (CountryVO item) => _DropdownOption(
          value: item.countryCode.trim(),
          label: item.nameZh.trim().isNotEmpty
              ? item.nameZh.trim()
              : item.nameEn.trim(),
        ),
      ),
    ];
    final List<_DropdownOption> positionOptions = <_DropdownOption>[
      _DropdownOption(value: '', label: '招聘.全部分类'.tr()),
      ...positions.map(
        (PositionVO item) => _DropdownOption(
          value: item.nameZh.trim(),
          label: item.nameZh.trim(),
        ),
      ),
    ];
    final List<_DropdownOption> salaryOptions = salaryRanges
        .map(
          (_SalaryRangeOption item) =>
              _DropdownOption(value: item.key, label: item.resolveLabel()),
        )
        .toList(growable: false);
    final List<_DropdownOption> salaryPresetOptions = salaryOptions
        .where((_DropdownOption option) => option.value.isNotEmpty)
        .toList(growable: false);
    final List<FilterBottomSheetOption> countrySheetOptions = countryOptions
        .map(
          (_DropdownOption option) =>
              FilterBottomSheetOption(value: option.value, label: option.label),
        )
        .toList(growable: false);
    final List<FilterBottomSheetOption> positionSheetOptions = positionOptions
        .map(
          (_DropdownOption option) =>
              FilterBottomSheetOption(value: option.value, label: option.label),
        )
        .toList(growable: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilterBottomSheetChip(
                  title: '订单.选择国家'.tr(),
                  value: selectedCountryCode ?? '',
                  options: countrySheetOptions,
                  enabled: isCountryEnabled,
                  onChanged: onCountryChanged,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FilterBottomSheetChip(
                  title: '招聘.选择分类'.tr(),
                  value: selectedPositionKeyword ?? '',
                  options: positionSheetOptions,
                  enabled: isPositionEnabled,
                  onChanged: onPositionChanged,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SalaryBottomSheetChip(
                  title: '岗位发布.选择薪资'.tr(),
                  placeholderLabel: salaryOptions.first.label,
                  selectedPresetKey: selectedSalaryRangeKey,
                  selectedCustomMin: selectedCustomSalaryMin,
                  selectedCustomMax: selectedCustomSalaryMax,
                  selectedSalaryCurrency: selectedSalaryCurrency,
                  presetOptions: salaryPresetOptions,
                  onChanged: onSalaryFilterChanged,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        _CombinedFilterBottomSheetChip(
          width: 64,
          title: '招聘.筛选'.tr(),
          enabled: isCountryEnabled && isPositionEnabled,
          selectedCountryCode: selectedCountryCode,
          selectedPositionKeyword: selectedPositionKeyword,
          selectedSalaryRangeKey: selectedSalaryRangeKey,
          selectedCustomSalaryMin: selectedCustomSalaryMin,
          selectedCustomSalaryMax: selectedCustomSalaryMax,
          selectedSalaryCurrency: selectedSalaryCurrency,
          countryOptions: countryOptions
              .where((_DropdownOption option) => option.value.isNotEmpty)
              .toList(growable: false),
          positionOptions: positionOptions
              .where((_DropdownOption option) => option.value.isNotEmpty)
              .toList(growable: false),
          salaryPresetOptions: salaryPresetOptions,
          onChanged: onCombinedFilterChanged,
        ),
      ],
    );
  }
}

class _SalaryFilterSelection {
  const _SalaryFilterSelection({
    this.presetKey,
    this.customMin,
    this.customMax,
    this.salaryCurrency = AppCurrency.eur,
  });

  final String? presetKey;
  final double? customMin;
  final double? customMax;
  final AppCurrency salaryCurrency;
}

class _CombinedJobFilterSelection {
  const _CombinedJobFilterSelection({
    this.countryCode,
    this.positionKeyword,
    required this.salarySelection,
    required this.salaryCurrency,
  });

  final String? countryCode;
  final String? positionKeyword;
  final _SalaryFilterSelection salarySelection;
  final AppCurrency salaryCurrency;
}

class _SalaryBottomSheetChip extends StatelessWidget {
  const _SalaryBottomSheetChip({
    required this.title,
    required this.placeholderLabel,
    required this.selectedPresetKey,
    required this.selectedCustomMin,
    required this.selectedCustomMax,
    required this.selectedSalaryCurrency,
    required this.presetOptions,
    required this.onChanged,
  });

  final String title;
  final String placeholderLabel;
  final String? selectedPresetKey;
  final double? selectedCustomMin;
  final double? selectedCustomMax;
  final AppCurrency selectedSalaryCurrency;
  final List<_DropdownOption> presetOptions;
  final ValueChanged<_SalaryFilterSelection> onChanged;

  String _resolveLabel() {
    if (selectedPresetKey?.isNotEmpty == true) {
      for (final _DropdownOption option in presetOptions) {
        if (option.value == selectedPresetKey) {
          return option.label;
        }
      }
    }
    if (selectedCustomMin != null && selectedCustomMax != null) {
      return '${_formatSalaryValue(selectedCustomMin!)}~${_formatSalaryValue(selectedCustomMax!)}';
    }
    return placeholderLabel;
  }

  bool get _highlighted =>
      selectedPresetKey?.isNotEmpty == true ||
      (selectedCustomMin != null && selectedCustomMax != null);

  Future<void> _handleTap(BuildContext context) async {
    String? draftSalaryPresetKey = selectedPresetKey?.isNotEmpty == true
        ? selectedPresetKey
        : null;
    AppCurrency draftSalaryCurrency = selectedSalaryCurrency;
    final TextEditingController minController = TextEditingController(
      text: selectedCustomMin == null
          ? ''
          : _formatSalaryValue(selectedCustomMin!),
    );
    final TextEditingController maxController = TextEditingController(
      text: selectedCustomMax == null
          ? ''
          : _formatSalaryValue(selectedCustomMax!),
    );
    StateSetter? updateSheetState;

    void clearDraft() {
      draftSalaryPresetKey = null;
      draftSalaryCurrency = AppCurrency.eur;
      minController.clear();
      maxController.clear();
      updateSheetState?.call(() {});
    }

    final _SalaryFilterSelection? result =
        await showFilterActionBottomSheet<_SalaryFilterSelection>(
          context: context,
          title: title,
          onReset: clearDraft,
          onConfirm: () {
            final String? selectedPreset = draftSalaryPresetKey;
            if (selectedPreset?.isNotEmpty == true) {
              Navigator.of(context, rootNavigator: true).pop(
                _SalaryFilterSelection(
                  presetKey: selectedPreset,
                  salaryCurrency: draftSalaryCurrency,
                ),
              );
              return;
            }

            final String minText = minController.text.trim();
            final String maxText = maxController.text.trim();
            if (minText.isEmpty && maxText.isEmpty) {
              Navigator.of(context, rootNavigator: true).pop(
                _SalaryFilterSelection(salaryCurrency: draftSalaryCurrency),
              );
              return;
            }
            if (minText.isEmpty || maxText.isEmpty) {
              AppToast.show('岗位发布.请填写完整的薪资范围'.tr());
              return;
            }

            final double min = double.parse(minText);
            final double max = double.parse(maxText);
            if (min > max) {
              AppToast.show('岗位发布.最低薪资不能大于最高薪资'.tr());
              return;
            }

            Navigator.of(context, rootNavigator: true).pop(
              _SalaryFilterSelection(
                customMin: min,
                customMax: max,
                salaryCurrency: draftSalaryCurrency,
              ),
            );
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              updateSheetState = setState;
              return _SalaryFilterSheetContent(
                presetOptions: presetOptions,
                selectedPresetKey: draftSalaryPresetKey,
                minController: minController,
                maxController: maxController,
                selectedSalaryCurrency: draftSalaryCurrency,
                onSalaryCurrencyTap: () {
                  showAppCurrencyOptionsBottomSheet(
                    context: context,
                    initialValue: draftSalaryCurrency,
                  ).then((AppCurrency? result) {
                    if (result == null) {
                      return;
                    }
                    setState(() {
                      draftSalaryCurrency = result;
                    });
                  });
                },
                onPresetSelected: (String value) {
                  setState(() {
                    draftSalaryPresetKey = value;
                    minController.clear();
                    maxController.clear();
                  });
                },
                onCustomValueChanged: () {
                  if (draftSalaryPresetKey != null) {
                    setState(() {
                      draftSalaryPresetKey = null;
                    });
                  }
                },
              );
            },
          ),
        );

    if (result == null) {
      return;
    }
    onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = _highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return SizedBox(
      width: 88,
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _resolveLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.medium(fontSize: 12, color: textColor),
                  ),
                ),
                const SizedBox(width: 4),
                AppSvgIcon(
                  assetPath: 'assets/images/icon_arrow_down.svg',
                  fallback: Icons.arrow_drop_down,
                  size: 12,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CombinedFilterBottomSheetChip extends StatelessWidget {
  const _CombinedFilterBottomSheetChip({
    required this.title,
    required this.width,
    required this.enabled,
    required this.selectedCountryCode,
    required this.selectedPositionKeyword,
    required this.selectedSalaryRangeKey,
    required this.selectedCustomSalaryMin,
    required this.selectedCustomSalaryMax,
    required this.selectedSalaryCurrency,
    required this.countryOptions,
    required this.positionOptions,
    required this.salaryPresetOptions,
    required this.onChanged,
  });

  final String title;
  final double width;
  final bool enabled;
  final String? selectedCountryCode;
  final String? selectedPositionKeyword;
  final String? selectedSalaryRangeKey;
  final double? selectedCustomSalaryMin;
  final double? selectedCustomSalaryMax;
  final AppCurrency selectedSalaryCurrency;
  final List<_DropdownOption> countryOptions;
  final List<_DropdownOption> positionOptions;
  final List<_DropdownOption> salaryPresetOptions;
  final ValueChanged<_CombinedJobFilterSelection> onChanged;

  bool get _highlighted =>
      (selectedCountryCode ?? '').isNotEmpty ||
      (selectedPositionKeyword ?? '').isNotEmpty ||
      (selectedSalaryRangeKey ?? '').isNotEmpty ||
      (selectedCustomSalaryMin != null && selectedCustomSalaryMax != null);

  Future<void> _handleTap(BuildContext context) async {
    String? draftCountryCode = selectedCountryCode;
    String? draftPositionKeyword = selectedPositionKeyword;
    String? draftSalaryPresetKey = selectedSalaryRangeKey;
    AppCurrency draftSalaryCurrency = selectedSalaryCurrency;
    final TextEditingController minController = TextEditingController(
      text: selectedCustomSalaryMin == null
          ? ''
          : _formatSalaryValue(selectedCustomSalaryMin!),
    );
    final TextEditingController maxController = TextEditingController(
      text: selectedCustomSalaryMax == null
          ? ''
          : _formatSalaryValue(selectedCustomSalaryMax!),
    );
    StateSetter? updateSheetState;

    void resetDraft() {
      draftCountryCode = null;
      draftPositionKeyword = null;
      draftSalaryPresetKey = null;
      draftSalaryCurrency = AppCurrency.eur;
      minController.clear();
      maxController.clear();
      updateSheetState?.call(() {});
    }

    final _CombinedJobFilterSelection? result =
        await showFilterActionBottomSheet<_CombinedJobFilterSelection>(
          context: context,
          title: title,
          onReset: resetDraft,
          onConfirm: () {
            final _SalaryFilterSelection? salarySelection =
                _resolveSalarySelection(
                  context,
                  selectedPresetKey: draftSalaryPresetKey,
                  minController: minController,
                  maxController: maxController,
                );
            if (salarySelection == null) {
              return;
            }
            Navigator.of(context, rootNavigator: true).pop(
              _CombinedJobFilterSelection(
                countryCode: draftCountryCode,
                positionKeyword: draftPositionKeyword,
                salarySelection: salarySelection,
                salaryCurrency: draftSalaryCurrency,
              ),
            );
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              updateSheetState = setState;
              return _CombinedFilterSheetContent(
                countryOptions: countryOptions,
                selectedCountryCode: draftCountryCode,
                onCountrySelected: (String value) {
                  setState(() {
                    draftCountryCode = value;
                  });
                },
                positionOptions: positionOptions,
                selectedPositionKeyword: draftPositionKeyword,
                onPositionSelected: (String value) {
                  setState(() {
                    draftPositionKeyword = value;
                  });
                },
                salaryPresetOptions: salaryPresetOptions,
                selectedSalaryPresetKey: draftSalaryPresetKey,
                minController: minController,
                maxController: maxController,
                selectedSalaryCurrency: draftSalaryCurrency,
                onSalaryCurrencyTap: () {
                  showAppCurrencyOptionsBottomSheet(
                    context: context,
                    initialValue: draftSalaryCurrency,
                  ).then((AppCurrency? result) {
                    if (result == null) {
                      return;
                    }
                    setState(() {
                      draftSalaryCurrency = result;
                    });
                  });
                },
                onSalaryPresetSelected: (String value) {
                  setState(() {
                    draftSalaryPresetKey = value;
                    minController.clear();
                    maxController.clear();
                  });
                },
                onCustomSalaryChanged: () {
                  if (draftSalaryPresetKey != null) {
                    setState(() {
                      draftSalaryPresetKey = null;
                    });
                  }
                },
              );
            },
          ),
        );

    if (result == null) {
      return;
    }
    onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = _highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return SizedBox(
      width: width,
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _handleTap(context) : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.medium(fontSize: 12, color: textColor),
                  ),
                ),
                const SizedBox(width: 4),
                AppSvgIcon(
                  assetPath: 'assets/images/icon_arrow_down.svg',
                  fallback: Icons.arrow_drop_down,
                  size: 12,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatSalaryValue(double value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

const int _kFilterGridColumnCount = 3;
const int _kFilterGridCollapsedMaxRows = 3;
const double _kFilterGridCrossSpacing = 12;
const double _kFilterGridMainSpacing = 18;
const double _kFilterGridItemHeight = 34;

_SalaryFilterSelection? _resolveSalarySelection(
  BuildContext context, {
  required String? selectedPresetKey,
  required TextEditingController minController,
  required TextEditingController maxController,
}) {
  if (selectedPresetKey?.isNotEmpty == true) {
    return _SalaryFilterSelection(presetKey: selectedPresetKey);
  }

  final String minText = minController.text.trim();
  final String maxText = maxController.text.trim();
  if (minText.isEmpty && maxText.isEmpty) {
    return const _SalaryFilterSelection();
  }
  if (minText.isEmpty || maxText.isEmpty) {
    AppToast.show('岗位发布.请填写完整的薪资范围'.tr());
    return null;
  }

  final double min = double.parse(minText);
  final double max = double.parse(maxText);
  if (min > max) {
    AppToast.show('岗位发布.最低薪资不能大于最高薪资'.tr());
    return null;
  }
  return _SalaryFilterSelection(customMin: min, customMax: max);
}

class _CombinedFilterSheetContent extends StatelessWidget {
  const _CombinedFilterSheetContent({
    required this.countryOptions,
    required this.selectedCountryCode,
    required this.onCountrySelected,
    required this.positionOptions,
    required this.selectedPositionKeyword,
    required this.onPositionSelected,
    required this.salaryPresetOptions,
    required this.selectedSalaryPresetKey,
    required this.minController,
    required this.maxController,
    required this.selectedSalaryCurrency,
    required this.onSalaryCurrencyTap,
    required this.onSalaryPresetSelected,
    required this.onCustomSalaryChanged,
  });

  final List<_DropdownOption> countryOptions;
  final String? selectedCountryCode;
  final ValueChanged<String> onCountrySelected;
  final List<_DropdownOption> positionOptions;
  final String? selectedPositionKeyword;
  final ValueChanged<String> onPositionSelected;
  final List<_DropdownOption> salaryPresetOptions;
  final String? selectedSalaryPresetKey;
  final TextEditingController minController;
  final TextEditingController maxController;
  final AppCurrency selectedSalaryCurrency;
  final VoidCallback onSalaryCurrencyTap;
  final ValueChanged<String> onSalaryPresetSelected;
  final VoidCallback onCustomSalaryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CollapsibleCombinedFilterSection(
          title: '招聘.国家'.tr(),
          options: countryOptions,
          selectedValue: selectedCountryCode,
          onSelected: onCountrySelected,
        ),
        const SizedBox(height: 24),
        _CollapsibleCombinedFilterSection(
          title: '招聘.签证类型'.tr(),
          options: positionOptions,
          selectedValue: selectedPositionKeyword,
          onSelected: onPositionSelected,
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Text(
              '招聘.薪资范围'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 16,
                color: Color(0xFF262626),
              ),
            ),
            const Spacer(),
            FieldTrailingSelector(
              label: selectedSalaryCurrency.labelKey.tr(),
              onTap: onSalaryCurrencyTap,
              textStyle: TestStyle.regular(
                fontSize: 14,
                color: Color(0xFF595959),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FilterOptionGrid(
          options: salaryPresetOptions,
          selectedValue: selectedSalaryPresetKey,
          onSelected: onSalaryPresetSelected,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '岗位发布.自定义薪资'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 14,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SalaryInputField(
                          controller: minController,
                          hintText: '岗位发布.最低薪资'.tr(),
                          onChanged: (_) => onCustomSalaryChanged(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '岗位发布.至'.tr(),
                          style: TestStyle.pingFangRegular(
                            fontSize: 14,
                            color: Color(0xFF262626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: _SalaryInputField(
                  controller: maxController,
                  hintText: '岗位发布.最高薪资'.tr(),
                  onChanged: (_) => onCustomSalaryChanged(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CollapsibleCombinedFilterSection extends StatefulWidget {
  const _CollapsibleCombinedFilterSection({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<_DropdownOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  @override
  State<_CollapsibleCombinedFilterSection> createState() =>
      _CollapsibleCombinedFilterSectionState();
}

class _CollapsibleCombinedFilterSectionState
    extends State<_CollapsibleCombinedFilterSection> {
  bool _expanded = false;

  static int get _collapsedMaxItemCount =>
      _kFilterGridColumnCount * _kFilterGridCollapsedMaxRows;

  @override
  void initState() {
    super.initState();
    _expanded = _shouldExpandForSelection(widget.selectedValue);
  }

  @override
  void didUpdateWidget(covariant _CollapsibleCombinedFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue &&
        _shouldExpandForSelection(widget.selectedValue)) {
      _expanded = true;
    }
  }

  bool _shouldExpandForSelection(String? selectedValue) {
    if (selectedValue?.isNotEmpty != true) {
      return false;
    }
    final int selectedIndex = widget.options.indexWhere(
      (_DropdownOption option) => option.value == selectedValue,
    );
    return selectedIndex >= _collapsedMaxItemCount;
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowToggle =
        widget.options.length > _collapsedMaxItemCount;
    final int visibleCount = _expanded
        ? widget.options.length
        : math.min(widget.options.length, _collapsedMaxItemCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: TestStyle.medium(fontSize: 16, color: Color(0xFF262626)),
        ),
        const SizedBox(height: 16),
        _FilterOptionGrid(
          options: widget.options,
          selectedValue: widget.selectedValue,
          onSelected: widget.onSelected,
          visibleItemCount: visibleCount,
        ),
        if (shouldShowToggle) ...<Widget>[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: _FilterGridExpandButton(
              expanded: _expanded,
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SalaryFilterSheetContent extends StatelessWidget {
  const _SalaryFilterSheetContent({
    required this.presetOptions,
    required this.selectedPresetKey,
    required this.minController,
    required this.maxController,
    required this.selectedSalaryCurrency,
    required this.onSalaryCurrencyTap,
    required this.onPresetSelected,
    required this.onCustomValueChanged,
  });

  final List<_DropdownOption> presetOptions;
  final String? selectedPresetKey;
  final TextEditingController minController;
  final TextEditingController maxController;
  final AppCurrency selectedSalaryCurrency;
  final VoidCallback onSalaryCurrencyTap;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onCustomValueChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '招聘.薪资范围'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 16,
                color: Color(0xFF262626),
              ),
            ),
            const Spacer(),
            FieldTrailingSelector(
              label: selectedSalaryCurrency.labelKey.tr(),
              onTap: onSalaryCurrencyTap,
              textStyle: TestStyle.regular(
                fontSize: 14,
                color: Color(0xFF595959),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FilterOptionGrid(
          options: presetOptions,
          selectedValue: selectedPresetKey,
          onSelected: onPresetSelected,
        ),
        const SizedBox(height: 30),
        Text(
          '岗位发布.自定义薪资'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 14,
            color: Color(0xFF262626),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SalaryInputField(
                controller: minController,
                hintText: '岗位发布.最低薪资'.tr(),
                onChanged: (_) => onCustomValueChanged(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '岗位发布.至'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF262626),
                ),
              ),
            ),
            Expanded(
              child: _SalaryInputField(
                controller: maxController,
                hintText: '岗位发布.最高薪资'.tr(),
                onChanged: (_) => onCustomValueChanged(),
              ),
            ),
            SizedBox(height: 24, width: 10),
          ],
        ),
      ],
    );
  }
}

class _FilterOptionGrid extends StatelessWidget {
  const _FilterOptionGrid({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.visibleItemCount,
  });

  final List<_DropdownOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final int? visibleItemCount;

  @override
  Widget build(BuildContext context) {
    final int itemCount = math.min(
      visibleItemCount ?? options.length,
      options.length,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _kFilterGridColumnCount,
        crossAxisSpacing: _kFilterGridCrossSpacing,
        mainAxisSpacing: _kFilterGridMainSpacing,
        mainAxisExtent: _kFilterGridItemHeight,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _DropdownOption option = options[index];
        return _SalaryPresetOptionTile(
          label: option.label,
          selected: option.value == selectedValue,
          onTap: () => onSelected(option.value),
        );
      },
    );
  }
}

class _FilterGridExpandButton extends StatelessWidget {
  const _FilterGridExpandButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFF096DD9);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              expanded ? '收起' : '显示全部',
              style: TestStyle.medium(fontSize: 12, color: color),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const AppSvgIcon(
                assetPath: 'assets/images/icon_arrow_down.svg',
                fallback: Icons.arrow_drop_down,
                size: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalaryPresetOptionTile extends StatelessWidget {
  const _SalaryPresetOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? const Color(0xFF096DD9)
        : const Color(0xFFBFBFBF);
    final Color backgroundColor = selected
        ? const Color(0xFFEDF4FF)
        : Colors.white;
    final Color textColor = selected
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TestStyle.medium(fontSize: 14, color: textColor),
        ),
      ),
    );
  }
}

class _SalaryInputField extends StatelessWidget {
  const _SalaryInputField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          hintText: hintText,
          hintStyle: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF91C3FF)),
            borderRadius: BorderRadius.circular(6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        style: TestStyle.regular(fontSize: 14, color: Color(0xFF262626)),
      ),
    );
  }
}

class _DropdownOption {
  const _DropdownOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _SalaryRangeOption {
  const _SalaryRangeOption({
    required this.key,
    this.label,
    this.labelKey,
    this.min,
    this.max,
  });

  final String key;
  final String? label;
  final String? labelKey;
  final double? min;
  final double? max;

  String resolveLabel() {
    if (labelKey != null) {
      return tr(labelKey!);
    }
    return label ?? '';
  }
}

class _SortOption {
  const _SortOption({required this.key, required this.labelKey});

  final String key;
  final String labelKey;
}

class _JobsListSection extends StatelessWidget {
  const _JobsListSection({
    required this.jobs,
    required this.isInitialLoading,
    required this.initialErrorMessage,
    required this.onRetry,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApply,
  });

  final List<JobListVO> jobs;
  final bool isInitialLoading;
  final String? initialErrorMessage;
  final Future<void> Function() onRetry;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Future<void> Function(JobListVO job) onApply;

  /// 根据列表状态切换首屏加载、错误、空态和正常卡片列表。
  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _JobsLoadingState(),
        ),
      );
    }

    if (initialErrorMessage != null && jobs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _JobsErrorState(
            message: initialErrorMessage!,
            onRetry: onRetry,
          ),
        ),
      );
    }

    if (jobs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _JobsEmptyState(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverToBoxAdapter(
        child: JobListCards(
          jobs: jobs,
          applyingJobIds: applyingJobIds,
          appliedJobIds: appliedJobIds,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onTap: (JobListVO item) {
            context.push(
              RoutePaths.jobDetail,
              extra: JobDetailPageArgs(jobId: item.jobId),
            );
          },
          onApply: onApply,
        ),
      ),
    );
  }
}

class _JobsLoadingState extends StatelessWidget {
  const _JobsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _JobsEmptyState extends StatelessWidget {
  const _JobsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: AppEmptyState(
          message: '招聘.暂无岗位数据'.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}

class _JobsErrorState extends StatelessWidget {
  const _JobsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFBFBFBF),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              onRetry();
            },
            child: Text('通用.重试'.tr()),
          ),
        ],
      ),
    );
  }
}
