import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/page_result.dart';
import '../data/application_models.dart';
import '../data/application_providers.dart';
import 'company_application_management_styles.dart';
import 'widgets/company_application_management_widgets.dart';

class CompanyApplicationManagementPage extends ConsumerWidget {
  const CompanyApplicationManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _CompanyApplicationTab.values.length,
      child: Scaffold(
        backgroundColor: CompanyApplicationManagementStyles.pageBackground,
        body: Column(
          children: <Widget>[
            CompanyApplicationTopBar(
              title: '应聘管理',
              onBackTap: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(RoutePaths.home);
              },
              onSearchTap: () => _showPlaceholderSnackBar(context, '搜索功能'),
            ),
            CompanyApplicationTabBar(
              tabs: _CompanyApplicationTab.values
                  .map((tab) => tab.label)
                  .toList(growable: false),
            ),
            CompanyApplicationJobFilterBar(
              label: '全部岗位',
              onTap: () => _showPlaceholderSnackBar(context, '岗位筛选功能'),
            ),
            Expanded(
              child: TabBarView(
                children: _CompanyApplicationTab.values
                    .map(
                      (_CompanyApplicationTab tab) =>
                          _CompanyApplicationTabView(
                            key: PageStorageKey<String>(
                              'company-applications-${tab.name}',
                            ),
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

  static void _showPlaceholderSnackBar(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label（占位）')));
  }
}

enum _CompanyApplicationTab {
  pending(
    label: '待处理',
    status: 'pending',
    emptyText: '暂无待处理应聘',
    secondaryActionLabel: '邀约面试',
  ),
  invited(
    label: '已邀约',
    status: 'invited',
    emptyText: '暂无已邀约应聘',
    secondaryActionLabel: '电话联系',
  ),
  rejected(
    label: '不合适',
    status: 'rejected',
    emptyText: '暂无不合适应聘',
    secondaryActionLabel: '电话联系',
  );

  const _CompanyApplicationTab({
    required this.label,
    required this.status,
    required this.emptyText,
    required this.secondaryActionLabel,
  });

  final String label;
  final String status;
  final String emptyText;
  final String secondaryActionLabel;
}

class _CompanyApplicationTabView extends ConsumerStatefulWidget {
  const _CompanyApplicationTabView({super.key, required this.tab});

  final _CompanyApplicationTab tab;

  @override
  ConsumerState<_CompanyApplicationTabView> createState() =>
      _CompanyApplicationTabViewState();
}

class _CompanyApplicationTabViewState
    extends ConsumerState<_CompanyApplicationTabView>
    with AutomaticKeepAliveClientMixin<_CompanyApplicationTabView> {
  static const int _pageSize = 10;

  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<ApplicationVO> _applications = const <ApplicationVO>[];
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
      final PageResult<ApplicationVO> response = await ref
          .read(applicationServiceProvider)
          .listJobApplications(
            page: 1,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _applications = response.list;
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
      final PageResult<ApplicationVO> response = await ref
          .read(applicationServiceProvider)
          .listJobApplications(
            page: 1,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _applications = response.list;
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
      final PageResult<ApplicationVO> response = await ref
          .read(applicationServiceProvider)
          .listJobApplications(
            page: _nextPage,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _applications = <ApplicationVO>[..._applications, ...response.list];
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
      child: _applications.isEmpty
          ? CompanyApplicationListStateView(
              message: _errorMessage ?? widget.tab.emptyText,
              icon: _errorMessage == null
                  ? Icons.assignment_outlined
                  : Icons.error_outline_rounded,
              buttonLabel: _errorMessage == null ? null : '重新加载',
              onTap: _errorMessage == null ? null : _loadInitial,
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                CompanyApplicationManagementStyles.pageHorizontalPadding,
                12,
                CompanyApplicationManagementStyles.pageHorizontalPadding,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: _applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final ApplicationVO item = _applications[index];
                return CompanyApplicationCard(
                  data: _buildCardData(item, index),
                  onViewResumeTap: () =>
                      _showPlaceholderSnackBar(context, '查看简历'),
                  onSecondaryActionTap: () => _showPlaceholderSnackBar(
                    context,
                    widget.tab.secondaryActionLabel,
                  ),
                );
              },
            ),
    );
  }

  CompanyApplicationCardData _buildCardData(ApplicationVO item, int index) {
    return CompanyApplicationCardData(
      positionTitle: item.job.title.trim().isEmpty ? '待定岗位' : item.job.title,
      matchText: '${item.matchScore.clamp(0, 100)}%',
      name: item.applicant.nickname.trim().isEmpty
          ? '匿名候选人'
          : item.applicant.nickname,
      ageGender: _formatAgeGender(item.applicant.age, item.applicant.gender),
      tags: _buildTags(item.applicant),
      submittedText: _formatSubmittedText(item.submittedAt),
      secondaryActionLabel: widget.tab.secondaryActionLabel,
      backgroundAssetPath: index.isEven
          ? CompanyApplicationManagementStyles.primaryCardBackgroundAssetPath
          : CompanyApplicationManagementStyles.secondaryCardBackgroundAssetPath,
    );
  }

  List<String> _buildTags(ApplicantVO applicant) {
    final List<String> tags = <String>[];

    void addTag(String value) {
      final String tag = value.trim();
      if (tag.isEmpty || tags.contains(tag)) {
        return;
      }
      tags.add(tag);
    }

    for (final String tag in applicant.keyTags) {
      addTag(tag);
      if (tags.length >= 3) {
        return tags;
      }
    }

    if (applicant.experienceYears > 0) {
      addTag('${applicant.experienceYears}年经验');
    }

    if (tags.isEmpty) {
      addTag('信息待完善');
    }

    return tags.take(3).toList(growable: false);
  }

  String _formatAgeGender(int age, String gender) {
    final List<String> parts = <String>[];
    if (age > 0) {
      parts.add('$age岁');
    }

    final String normalizedGender = _normalizeGender(gender);
    if (normalizedGender.isNotEmpty) {
      parts.add(normalizedGender);
    }

    return parts.join('·');
  }

  String _normalizeGender(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'm':
      case '男':
        return '男';
      case 'female':
      case 'woman':
      case 'f':
      case '女':
        return '女';
      default:
        return value.trim();
    }
  }

  String _formatSubmittedText(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '刚刚投递';
    }

    final DateTime? submittedAt = DateTime.tryParse(trimmed)?.toLocal();
    if (submittedAt == null) {
      return trimmed;
    }

    final DateTime now = DateTime.now();
    final Duration difference = now.difference(submittedAt);

    if (difference.inMinutes < 1) {
      return '刚刚投递';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前投递';
    }
    if (_isSameDay(now, submittedAt)) {
      return '${difference.inHours}小时前投递';
    }

    final DateTime yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    if (_isSameDay(yesterday, submittedAt)) {
      return '昨日${_twoDigits(submittedAt.hour)}:${_twoDigits(submittedAt.minute)}投递';
    }

    return '${_twoDigits(submittedAt.month)}-${_twoDigits(submittedAt.day)} ${_twoDigits(submittedAt.hour)}:${_twoDigits(submittedAt.minute)}投递';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _twoDigits(int value) {
    return value < 10 ? '0$value' : value.toString();
  }

  void _showPlaceholderSnackBar(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label（占位）')));
  }
}
