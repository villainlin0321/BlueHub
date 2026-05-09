import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jobs/data/job_models.dart';
import '../../../jobs/data/job_providers.dart';
import '../../../../shared/network/page_result.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

/// 企业岗位页。
class CompanyVisaPage extends ConsumerStatefulWidget {
  const CompanyVisaPage({super.key});

  @override
  ConsumerState<CompanyVisaPage> createState() => _CompanyVisaPageState();
}

class _CompanyVisaPageState extends ConsumerState<CompanyVisaPage> {
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return DefaultTabController(
      length: _CompanyJobTab.values.length,
      child: ColoredBox(
        color: const Color(0xFFF5F7FA),
        child: Column(
          children: <Widget>[
            _CompanyVisaHeader(
            topPadding: topPadding,
            onPublishTap: () => context.push(RoutePaths.postJob),
          ),
            const _CompanyVisaTabBar(),
            Expanded(
              child: TabBarView(
                children: _CompanyJobTab.values
                    .map(
                      (tab) => _CompanyJobTabView(
                        key: PageStorageKey<String>('company-visa-${tab.name}'),
                        tab: tab,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CompanyJobTab {
  recruiting(label: '招聘中', status: 'active'),
  offline(label: '已下线', status: 'inactive');

  const _CompanyJobTab({required this.label, required this.status});

  final String label;
  final String status;

  bool get isOffline => this == _CompanyJobTab.offline;

  String get emptyText => isOffline ? '暂无已下线岗位' : '暂无招聘中的岗位';
}

class _CompanyVisaHeader extends StatelessWidget {
  const _CompanyVisaHeader({
    required this.topPadding,
    required this.onPublishTap,
  });

  final double topPadding;
  final VoidCallback onPublishTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      child: Row(
        children: <Widget>[
          const Spacer(),
          const Text(
            '岗位',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onPublishTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '发布',
                style: TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 15,
                  height: 21 / 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyVisaTabBar extends StatelessWidget {
  const _CompanyVisaTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        tabs: _CompanyJobTab.values
            .map((tab) => Tab(height: 44, text: tab.label))
            .toList(growable: false),
        labelColor: const Color(0xFF096DD9),
        unselectedLabelColor: const Color(0xFF262626),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 22 / 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 22 / 14,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: const Color(0xFF096DD9),
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

class _CompanyJobTabView extends ConsumerStatefulWidget {
  const _CompanyJobTabView({super.key, required this.tab});

  final _CompanyJobTab tab;

  @override
  ConsumerState<_CompanyJobTabView> createState() => _CompanyJobTabViewState();
}

class _CompanyJobTabViewState extends ConsumerState<_CompanyJobTabView>
    with AutomaticKeepAliveClientMixin<_CompanyJobTabView> {
  static const int _pageSize = 10;

  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<JobDetailVO> _jobs = const <JobDetailVO>[];
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasLoadedOnce = false;
  int _nextPage = 1;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (_isInitialLoading) {
      return;
    }

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final PageResult<JobDetailVO> response = await ref
          .read(jobServiceProvider)
          .listMyJobs(page: 1, pageSize: _pageSize, status: widget.tab.status);
      if (!mounted) {
        return;
      }
      setState(() {
        _jobs = response.list;
        _nextPage = response.pagination.page + 1;
        _hasMore = response.pagination.hasNext;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasLoadedOnce = true;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialLoading = false;
        _hasLoadedOnce = true;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final PageResult<JobDetailVO> response = await ref
          .read(jobServiceProvider)
          .listMyJobs(page: 1, pageSize: _pageSize, status: widget.tab.status);
      if (!mounted) {
        return;
      }
      setState(() {
        _jobs = response.list;
        _nextPage = response.pagination.page + 1;
        _hasMore = response.pagination.hasNext;
        _hasLoadedOnce = true;
        _errorMessage = null;
      });
      _refreshController.finishRefresh();
      _refreshController.resetFooter();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _normalizeError(error);
      });
      _refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  Future<void> _onLoadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      final PageResult<JobDetailVO> response = await ref
          .read(jobServiceProvider)
          .listMyJobs(
            page: _nextPage,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _jobs = <JobDetailVO>[..._jobs, ...response.list];
        _nextPage = response.pagination.page + 1;
        _hasMore = response.pagination.hasNext;
        _isLoadingMore = false;
      });
      _refreshController.finishLoad(
        _hasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
        _errorMessage = _normalizeError(error);
      });
      _refreshController.finishLoad(IndicatorResult.fail);
    }
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '加载失败，请稍后重试' : message;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isInitialLoading && !_hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    return EasyRefresh(
      controller: _refreshController,
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _onRefresh,
      onLoad: _hasMore ? _onLoadMore : null,
      child: _jobs.isEmpty
          ? _CompanyJobEmptyState(
              message: _errorMessage ?? widget.tab.emptyText,
              buttonLabel: _errorMessage == null ? null : '重新加载',
              onTap: _errorMessage == null ? null : _loadInitial,
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return _JobManageCard(
                  job: _jobs[index],
                  isOffline: widget.tab.isOffline,
                );
              },
            ),
    );
  }
}

class _CompanyJobEmptyState extends StatelessWidget {
  const _CompanyJobEmptyState({
    required this.message,
    this.buttonLabel,
    this.onTap,
  });

  final String message;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        96,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: <Widget>[
              const Icon(
                Icons.work_outline_rounded,
                size: 36,
                color: Color(0xFF8C8C8C),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              if (buttonLabel != null && onTap != null) ...<Widget>[
                const SizedBox(height: 12),
                TextButton(onPressed: onTap, child: Text(buttonLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JobManageCard extends StatelessWidget {
  const _JobManageCard({required this.job, required this.isOffline});

  final JobDetailVO job;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                    ),
                  ),
                ),
                const _MoreActionIcon(),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildTags(job)
                    .map(
                      (String tag) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _JobTag(label: tag),
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
                  style: const TextStyle(
                    color: Color(0xFFFE5815),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 24 / 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '浏览 ${job.viewCount}',
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '收到简历 ${job.applyCount}',
                  style: const TextStyle(
                    color: Color(0xFF096DD9),
                    fontSize: 12,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
            if (job.publishedAt.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                '发布时间 ${job.publishedAt}',
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 12,
                  height: 18 / 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const _DeleteActionButton(),
                const Spacer(),
                _BorderActionButton(label: isOffline ? '发布' : '下线'),
                const SizedBox(width: 8),
                const _PrimaryActionButton(label: '编辑'),
              ],
            ),
          ],
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
      addTag('提供签证');
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
    final String currency = job.salaryCurrency;
    final String period = job.salaryPeriod.isEmpty
        ? ''
        : '/${job.salaryPeriod}';

    if (job.salaryMin <= 0 && job.salaryMax <= 0) {
      return '薪资面议';
    }

    if (job.salaryMin > 0 && job.salaryMax > 0) {
      return '$currency${_formatAmount(job.salaryMin)}~${_formatAmount(job.salaryMax)}$period';
    }

    final double salary = job.salaryMax > 0 ? job.salaryMax : job.salaryMin;
    return '$currency${_formatAmount(salary)}$period';
  }

  String _formatAmount(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.label});

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
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 10,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _MoreActionIcon extends StatelessWidget {
  const _MoreActionIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: Color(0xFF171A1D),
        ),
      ),
    );
  }
}

class _DeleteActionButton extends StatelessWidget {
  const _DeleteActionButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF4D4F)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        '删除',
        style: TextStyle(
          color: Color(0xFFD9363E),
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BorderActionButton extends StatelessWidget {
  const _BorderActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: const Color(0xFF096DD9),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
