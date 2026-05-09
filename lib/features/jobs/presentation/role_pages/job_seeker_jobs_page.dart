import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_refresh/easy_refresh.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../data/job_models.dart';
import '../../data/job_providers.dart';

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

  static void _showPlaceholderMessage(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('功能开发中')));
  }
}

class _JobsPageBody extends ConsumerStatefulWidget {
  const _JobsPageBody();

  @override
  ConsumerState<_JobsPageBody> createState() => _JobsPageBodyState();
}

class _JobsPageBodyState extends ConsumerState<_JobsPageBody> {
  static const int _pageSize = 20;

  final List<JobListVO> _jobs = <JobListVO>[];
  int _currentPage = 0;
  bool _hasNext = true;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _initialErrorMessage;

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

    return SafeArea(
      bottom: false,
      child: EasyRefresh(
        onRefresh: _handleRefresh,
        onLoad: _hasNext && _jobs.isNotEmpty ? _handleLoadMore : null,
        child: CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  '欧洲招聘',
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 24 / 17,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _JobsSearchBar(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 13)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _FilterRow(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 19)),
            _JobsListSection(
              jobs: _jobs,
              isInitialLoading: _isInitialLoading,
              initialErrorMessage: _initialErrorMessage,
              onRetry: _loadInitialJobs,
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: bottomPadding + 24),
            ),
          ],
        ),
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
      final result = await ref.read(jobServiceProvider).listJobs(
        page: reset ? 1 : _currentPage + 1,
        pageSize: _pageSize,
        sort: 'latest',
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
        _jobs
          ..clear()
          ..addAll(reset ? result.list : <JobListVO>[..._jobs, ...result.list]);
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
    return '岗位列表加载失败，请稍后重试';
  }
}

class _JobsSearchBar extends StatelessWidget {
  const _JobsSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          AppSvgIcon(
            assetPath: 'assets/images/mou2x9mw-2jfef5b.svg',
            fallback: Icons.search_rounded,
            size: 16,
            color: Color(0xFFBFBFBF),
          ),
          SizedBox(width: 8),
          Text(
            '搜索签证服务/欧洲岗位',
            style: TextStyle(
              color: Color(0xFFBFBFBF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _DropdownChip(
          label: '全部国家',
          iconAssetPath: 'assets/images/mou2x9mw-y3xkvto.png',
          width: 88,
        ),
        _DropdownChip(
          label: '全部分类',
          iconAssetPath: 'assets/images/mou2x9mw-y3xkvto.png',
          width: 88,
        ),
        _DropdownChip(
          label: '薪资要求',
          iconAssetPath: 'assets/images/mou2x9mw-flxj53h.png',
          width: 88,
          highlighted: true,
        ),
        _FilterActionChip(),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.iconAssetPath,
    required this.width,
    this.highlighted = false,
  });

  final String label;
  final String iconAssetPath;
  final double width;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            iconAssetPath,
            width: 12,
            height: 12,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: textColor,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterActionChip extends StatelessWidget {
  const _FilterActionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '筛选',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
          SizedBox(width: 4),
          AppSvgIcon(
            assetPath: 'assets/images/mou2x9mw-6xvx4hp.svg',
            fallback: Icons.tune_rounded,
            size: 12,
            color: Color(0xFF171A1D),
          ),
        ],
      ),
    );
  }
}

class _JobsListSection extends StatelessWidget {
  const _JobsListSection({
    required this.jobs,
    required this.isInitialLoading,
    required this.initialErrorMessage,
    required this.onRetry,
  });

  final List<JobListVO> jobs;
  final bool isInitialLoading;
  final String? initialErrorMessage;
  final Future<void> Function() onRetry;

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
          child: _JobsErrorState(message: initialErrorMessage!, onRetry: onRetry),
        ),
      );
    }

    if (jobs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
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
              data: item.toCardData(),
              onTap: () => context.push(RoutePaths.jobDetail),
              onApply: () => JobSeekerJobsPage._showPlaceholderMessage(context),
            ),
          );
        }, childCount: jobs.length),
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
      child: const Center(
        child: Text(
          '暂无岗位数据',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
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
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

extension on JobListVO {
  /// 将接口返回的岗位列表项映射为职位卡片数据。
  JobPositionCardData toCardData() {
    final List<String> tagLabels = tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != '急招'),
      if (hasVisaSupport && !tagLabels.contains('提供签证')) '提供签证',
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[
      if (isUrgent) '急招',
    ];

    return JobPositionCardData(
      title: title,
      salary: _formatSalary(),
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: employer.name,
      location: _formatLocation(),
      showApplyButton: true,
    );
  }

  /// 组装职位卡片展示的薪资文案。
  String _formatSalary() {
    final String currency = salaryCurrency.isEmpty ? '¥' : salaryCurrency;
    final String minText = _formatNumber(salaryMin);
    final String maxText = _formatNumber(salaryMax);
    final String rangeText = salaryMax > 0 ? '$currency$minText~$maxText' : '$currency$minText';
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
