import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/models/dictionary_models.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../../me/data/dictionary_providers.dart';
import '../../../me/data/collection_models.dart' show CollectionBO;
import '../../../me/data/collection_providers.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';
import '../job_apply_helper.dart';
import '../job_detail_page.dart';

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
        _SalaryRangeOption(key: '1000-2000', label: '1000-2000', min: 1000, max: 2000),
        _SalaryRangeOption(key: '2000-3000', label: '2000-3000', min: 2000, max: 3000),
        _SalaryRangeOption(key: '3000-4000', label: '3000-4000', min: 3000, max: 4000),
        _SalaryRangeOption(key: '4000-5000', label: '4000-5000', min: 4000, max: 5000),
        _SalaryRangeOption(key: '5000-6000', label: '5000-6000', min: 5000, max: 6000),
        _SalaryRangeOption(key: '6000-7000', label: '6000-7000', min: 6000, max: 7000),
        _SalaryRangeOption(key: '7000-8000', label: '7000-8000', min: 7000, max: 8000),
        _SalaryRangeOption(key: '8000-9000', label: '8000-9000', min: 8000, max: 9000),
        _SalaryRangeOption(key: '9000-10000', label: '9000-10000', min: 9000, max: 10000),
        _SalaryRangeOption(key: '10000+', labelKey: '招聘.以上', min: 10000, prefix: '10000'),
      ];
  static const List<_SortOption> _sortOptions = <_SortOption>[
    _SortOption(key: 'latest', labelKey: '招聘.最新'),
    _SortOption(key: 'salary_desc', labelKey: '招聘.薪资降序'),
    _SortOption(key: 'salary_asc', labelKey: '招聘.薪资升序'),
  ];

  final List<JobListVO> _jobs = <JobListVO>[];
  final Set<int> _submittingJobIds = <int>{};
  final Set<int> _appliedJobIds = <int>{};
  final Set<int> _collectingJobIds = <int>{};
  final Map<int, bool> _collectedOverrides = <int, bool>{};
  late final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _initialErrorMessage;
  String? _submittedKeyword;
  String? _selectedCountryCode;
  String? _selectedPositionKeyword;
  String? _selectedSalaryRangeKey;
  String _selectedSortKey = _sortOptions.first.key;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<Set<int>> collectedJobIdsAsync = ref.watch(
      collectedJobIdsProvider,
    );
    final AsyncValue<PageResult<CountryVO>> countriesAsync = ref.watch(
      countrySearchProvider(const CountrySearchQuery(page: 1, pageSize: 200)),
    );
    final AsyncValue<List<PositionCategoryVO>> positionTreeAsync = ref.watch(
      positionTreeProvider(null),
    );
    final List<CountryVO> countries = countriesAsync.asData?.value.list ?? const <CountryVO>[];
    final List<PositionVO> positions = _flattenPositions(
      positionTreeAsync.asData?.value ?? const <PositionCategoryVO>[],
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              '招聘.欧洲招聘'.tr(),
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _JobsSearchBar(
              controller: _searchController,
              onSubmitted: _handleSearchSubmitted,
            ),
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
              selectedSortKey: _selectedSortKey,
              isCountryEnabled: countriesAsync.hasValue,
              isPositionEnabled: positionTreeAsync.hasValue,
              onCountryChanged: _handleCountryChanged,
              onPositionChanged: _handlePositionChanged,
              onSalaryRangeChanged: _handleSalaryRangeChanged,
              onSortChanged: _handleSortChanged,
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
                    collectingJobIds: _collectingJobIds,
                    collectedJobIdsAsync: collectedJobIdsAsync,
                    onApply: _handleApply,
                    onToggleCollection: _handleToggleCollection,
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

  /// 提交搜索关键字后刷新岗位列表。
  void _handleSearchSubmitted(String value) {
    final String? keyword = value.trim().isEmpty ? null : value.trim();
    if (_submittedKeyword == keyword) {
      FocusScope.of(context).unfocus();
      return;
    }
    setState(() {
      _submittedKeyword = keyword;
    });
    FocusScope.of(context).unfocus();
    _fetchJobs(
      reset: true,
      showFullscreenLoading: _jobs.isEmpty,
    );
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

  /// 切换薪资区间后重新请求岗位列表。
  void _handleSalaryRangeChanged(String? value) {
    final String? rangeKey = _normalizeFilterValue(value);
    if (_selectedSalaryRangeKey == rangeKey) {
      return;
    }
    setState(() {
      _selectedSalaryRangeKey = rangeKey;
    });
    FocusScope.of(context).unfocus();
    _fetchJobs(reset: true, showFullscreenLoading: _jobs.isEmpty);
  }

  /// 切换排序方式后重新请求岗位列表。
  void _handleSortChanged(String? value) {
    final String nextSortKey = value?.trim().isNotEmpty == true
        ? value!.trim()
        : _sortOptions.first.key;
    if (_selectedSortKey == nextSortKey) {
      return;
    }
    setState(() {
      _selectedSortKey = nextSortKey;
    });
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
            salaryMin: _selectedSalaryRange?.min,
            salaryMax: _selectedSalaryRange?.max,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
    final Set<String> parts = <String>{
      if ((_submittedKeyword ?? '').isNotEmpty) _submittedKeyword!,
      if ((_selectedPositionKeyword ?? '').isNotEmpty) _selectedPositionKeyword!,
    };
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
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

    final String? errorMessage = await submitJobApplication(
      context,
      jobId: job.jobId,
    );
    if (!mounted) {
      return;
    }
    if (errorMessage == null) {
      setState(() {
        _submittingJobIds.remove(job.jobId);
        _appliedJobIds.add(job.jobId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('招聘.投递成功'.tr())));
    } else {
      setState(() {
        _submittingJobIds.remove(job.jobId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  /// 切换列表页岗位收藏状态，并与收藏页、详情页保持同步。
  Future<void> _handleToggleCollection(JobListVO job) async {
    if (_collectingJobIds.contains(job.jobId)) {
      return;
    }

    final Set<int>? collectedJobIds = ref
        .read(collectedJobIdsProvider)
        .asData
        ?.value;
    final bool isCollected =
        _collectedOverrides[job.jobId] ??
        collectedJobIds?.contains(job.jobId) ??
        job.isCollected;

    setState(() {
      _collectingJobIds.add(job.jobId);
    });

    try {
      final request = CollectionBO(targetType: 'job', targetId: job.jobId);
      final service = ref.read(collectionServiceProvider);
      if (isCollected) {
        await service.removeCollection(request: request);
      } else {
        await service.addCollection(request: request);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _collectingJobIds.remove(job.jobId);
        _collectedOverrides[job.jobId] = !isCollected;
      });
      ref.read(collectionRefreshTickProvider.notifier).bump();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            isCollected ? '招聘.已取消收藏'.tr() : '招聘.收藏成功'.tr(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _collectingJobIds.remove(job.jobId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resolveCollectionErrorMessage(error))),
      );
    }
  }

  /// 提取列表收藏操作的错误文案。
  String _resolveCollectionErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '招聘.收藏操作失败'.tr();
  }
}

class _JobsSearchBar extends StatelessWidget {
  const _JobsSearchBar({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '招聘.搜索岗位占位'.tr(),
                hintStyle: const TextStyle(
                  color: Color(0xFFBFBFBF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
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
    required this.selectedSortKey,
    required this.isCountryEnabled,
    required this.isPositionEnabled,
    required this.onCountryChanged,
    required this.onPositionChanged,
    required this.onSalaryRangeChanged,
    required this.onSortChanged,
  });

  final List<CountryVO> countries;
  final List<PositionVO> positions;
  final List<_SalaryRangeOption> salaryRanges;
  final String? selectedCountryCode;
  final String? selectedPositionKeyword;
  final String? selectedSalaryRangeKey;
  final String selectedSortKey;
  final bool isCountryEnabled;
  final bool isPositionEnabled;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onPositionChanged;
  final ValueChanged<String?> onSalaryRangeChanged;
  final ValueChanged<String?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final List<_DropdownOption> countryOptions = <_DropdownOption>[
      _DropdownOption(value: '', label: '招聘.全部国家'.tr()),
      ...countries.map(
        (CountryVO item) => _DropdownOption(
          value: item.countryCode.trim(),
          label: item.nameZh.trim().isNotEmpty ? item.nameZh.trim() : item.nameEn.trim(),
        ),
      ),
    ];
    final List<_DropdownOption> positionOptions = <_DropdownOption>[
      _DropdownOption(value: '', label: '招聘.全部分类'.tr()),
      ...positions.map(
        (PositionVO item) => _DropdownOption(value: item.nameZh.trim(), label: item.nameZh.trim()),
      ),
    ];
    final List<_DropdownOption> salaryOptions = salaryRanges
        .map(
          (_SalaryRangeOption item) =>
              _DropdownOption(value: item.key, label: item.resolveLabel()),
        )
        .toList(growable: false);
    final List<_DropdownOption> sortOptions = _JobsPageBodyState._sortOptions
        .map(
          (_SortOption item) =>
              _DropdownOption(value: item.key, label: item.labelKey.tr()),
        )
        .toList(growable: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _DropdownChip(
          value: selectedCountryCode ?? '',
          options: countryOptions,
          enabled: isCountryEnabled,
          onChanged: onCountryChanged,
        ),
        _DropdownChip(
          value: selectedPositionKeyword ?? '',
          options: positionOptions,
          enabled: isPositionEnabled,
          onChanged: onPositionChanged,
        ),
        _DropdownChip(
          value: selectedSalaryRangeKey ?? '',
          options: salaryOptions,
          enabled: true,
          onChanged: onSalaryRangeChanged,
        ),
        _DropdownChip(
          width: 76,
          value: selectedSortKey,
          options: sortOptions,
          enabled: true,
          onChanged: onSortChanged,
        ),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    this.width = 88,
    required this.value,
    required this.options,
    required this.enabled,
    this.onChanged,
  });

  final double width;
  final String value;
  final List<_DropdownOption> options;
  final bool enabled;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final String effectiveValue = options.any(
          (_DropdownOption option) => option.value == value,
        )
        ? value
        : options.first.value;
    final bool highlighted = effectiveValue != options.first.value;
    final Color borderColor = highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return SizedBox(
      width: width,
      height: 30,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          valueListenable: ValueNotifier<String?>(effectiveValue),
          items: options
              .map(
                (_DropdownOption option) => DropdownItem<String>(
                  value: option.value,
                  height: 40,
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: option.value == effectiveValue
                          ? textColor
                          : const Color(0xFF171A1D),
                      fontSize: 12,
                      fontWeight: option.value == effectiveValue
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 18 / 12,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: enabled ? onChanged : null,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
          ),
          buttonStyleData: ButtonStyleData(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
          ),
          iconStyleData: IconStyleData(
            icon: AppSvgIcon(
              assetPath: 'assets/images/icon_arrow_down.svg',
              fallback: Icons.arrow_drop_down,
              size: 12,
              color: textColor,
            ),
            iconSize: 12,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            offset: const Offset(0, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
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
    this.prefix,
    this.min,
    this.max,
  });

  final String key;
  final String? label;
  final String? labelKey;
  final String? prefix;
  final double? min;
  final double? max;

  String resolveLabel() {
    if (labelKey != null) {
      if (prefix != null) {
        return '$prefix${tr(labelKey!)}';
      }
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
    required this.collectingJobIds,
    required this.collectedJobIdsAsync,
    required this.onApply,
    required this.onToggleCollection,
  });

  final List<JobListVO> jobs;
  final bool isInitialLoading;
  final String? initialErrorMessage;
  final Future<void> Function() onRetry;
  final Set<int> applyingJobIds;
  final Set<int> appliedJobIds;
  final Set<int> collectingJobIds;
  final AsyncValue<Set<int>> collectedJobIdsAsync;
  final Future<void> Function(JobListVO job) onApply;
  final Future<void> Function(JobListVO job) onToggleCollection;

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
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final JobListVO item = jobs[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == jobs.length - 1 ? 0 : 12),
            child: JobPositionCard(
              data: item.toCardData(isCollected: _resolveCollectedState(item)),
              onTap: () => context.push(
                RoutePaths.jobDetail,
                extra: JobDetailPageArgs(jobId: item.jobId),
              ),
              onFavoriteTap: () {
                onToggleCollection(item);
              },
              onApply: appliedJobIds.contains(item.jobId)
                  ? null
                  : () {
                      onApply(item);
                    },
              isApplying: applyingJobIds.contains(item.jobId),
              isCollecting: collectingJobIds.contains(item.jobId),
              applyButtonText: appliedJobIds.contains(item.jobId)
                  ? '招聘.已投递'.tr()
                  : '招聘卡片.一键投递'.tr(),
            ),
          );
        }, childCount: jobs.length),
      ),
    );
  }

  /// 解析职位卡片当前的收藏态，优先使用收藏接口同步结果。
  bool _resolveCollectedState(JobListVO item) {
    final Set<int>? collectedJobIds = collectedJobIdsAsync.asData?.value;
    if (collectedJobIds != null) {
      return collectedJobIds.contains(item.jobId);
    }
    return item.isCollected;
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
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
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

extension on JobListVO {
  /// 将接口返回的岗位列表项映射为职位卡片数据。
  JobPositionCardData toCardData({required bool isCollected}) {
    final List<String> tagLabels = tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != '招聘卡片.急招'.tr() && label != '急招'),
      if (hasVisaSupport &&
          !tagLabels.contains('招聘卡片.提供签证'.tr()) &&
          !tagLabels.contains('提供签证'))
        '招聘卡片.提供签证'.tr(),
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[
      if (isUrgent) '招聘卡片.急招'.tr(),
    ];

    return JobPositionCardData(
      title: title,
      salary: _formatSalary(),
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: employer.name,
      location: _formatLocation(),
      showApplyButton: true,
      isCollected: isCollected,
    );
  }

  /// 组装职位卡片展示的薪资文案。
  String _formatSalary() {
    final String currency = salaryCurrency.isEmpty ? '¥' : salaryCurrency;
    final String minText = _formatNumber(salaryMin);
    final String maxText = _formatNumber(salaryMax);
    final String rangeText = salaryMax > 0
        ? '$currency$minText~$maxText'
        : '$currency$minText';
    if (salaryPeriod.isEmpty) {
      return rangeText;
    }
    return '$rangeText/$salaryPeriod';
  }

  /// 组装职位卡片展示的地点文案。
  String _formatLocation() {
    final List<String> parts = <String>[
      country.trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }

  /// 格式化数字，尽量保持薪资文案简洁。
  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
