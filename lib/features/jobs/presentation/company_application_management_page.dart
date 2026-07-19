import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../message/application/chat/chat_page_args.dart';
import '../../messages/data/message_models.dart';
import '../../messages/data/message_providers.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/network/api_error_feedback.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../me/data/resume_providers.dart';
import '../application/company_applications/company_application_list_state.dart';
import '../application/company_applications/company_application_lists_controller.dart';
import '../data/application_models.dart';
import '../data/job_models.dart';
import '../data/job_providers.dart';
import '../../../shared/network/page_result.dart';
import 'company_application_management_styles.dart';
import 'widgets/company_application_management_widgets.dart';

import 'package:europepass/shared/ui/test_style.dart';

class CompanyApplicationManagementPage extends ConsumerStatefulWidget {
  const CompanyApplicationManagementPage({super.key});

  @override
  ConsumerState<CompanyApplicationManagementPage> createState() =>
      _CompanyApplicationManagementPageState();
}

class _CompanyApplicationManagementPageState
    extends ConsumerState<CompanyApplicationManagementPage> {
  static final List<String> _initialStatuses = _CompanyApplicationTab.values
      .map((tab) => tab.status)
      .toList(growable: false);

  int? _selectedJobId;
  String? _selectedJobTitle;
  List<JobDetailVO> _jobFilterJobs = const <JobDetailVO>[];
  bool _isJobFilterLoading = false;

  String get _jobFilterLabel {
    final String title = _selectedJobTitle?.trim() ?? '';
    return title.isEmpty ? '应聘管理.全部岗位'.tr() : title;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshAllApplicationTabs());
      _loadJobFilterJobs();
    });
  }

  Future<void> _refreshAllApplicationTabs() async {
    await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .refreshStatuses(statuses: _initialStatuses, jobId: _selectedJobId);
  }

  Future<void> _loadJobFilterJobs() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isJobFilterLoading = true;
    });

    try {
      final PageResult<JobDetailVO> response = await ref
          .read(jobServiceProvider)
          .listMyJobs(page: 1, pageSize: 100, status: 'active');
      if (!mounted) {
        return;
      }

      final List<JobDetailVO> jobs = response.list;
      final JobDetailVO? selectedJob = _findJobById(jobs, _selectedJobId);
      setState(() {
        _jobFilterJobs = jobs;
        _isJobFilterLoading = false;
        if (_selectedJobId != null && selectedJob == null) {
          _selectedJobId = null;
          _selectedJobTitle = null;
        } else if (selectedJob != null) {
          _selectedJobTitle = _resolveJobTitle(selectedJob);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isJobFilterLoading = false;
      });
      AppToast.show(_normalizeJobFilterError(error));
    }
  }

  void _handleJobFilterChanged(JobDetailVO? job) {
    final int? nextJobId = job?.jobId;
    final String? nextJobTitle = job == null ? null : _resolveJobTitle(job);
    if (nextJobId == _selectedJobId &&
        (nextJobTitle ?? '') == (_selectedJobTitle ?? '')) {
      return;
    }

    setState(() {
      _selectedJobId = nextJobId;
      _selectedJobTitle = nextJobTitle;
    });
  }

  JobDetailVO? _findJobById(List<JobDetailVO> jobs, int? jobId) {
    if (jobId == null) {
      return null;
    }

    for (final JobDetailVO job in jobs) {
      if (job.jobId == jobId) {
        return job;
      }
    }
    return null;
  }

  String _resolveJobTitle(JobDetailVO job) {
    final String title = job.title.trim();
    return title.isEmpty ? '招聘.未命名岗位'.tr() : title;
  }

  String _normalizeJobFilterError(Object error) {
    return ApiErrorFeedback.resolveMessage(error, fallback: '企业岗位.加载失败'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _CompanyApplicationTab.values.length,
      child: Scaffold(
        backgroundColor: CompanyApplicationManagementStyles.pageBackground,
        appBar: AppBar(
          backgroundColor: CompanyApplicationManagementStyles.surface,
          surfaceTintColor: CompanyApplicationManagementStyles.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.home);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          title: Text(
            '我的.应聘管理'.tr(),
            style: TestStyle.pingFangSemibold(
              fontSize: 17,
              color: Colors.black,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            CompanyApplicationTabBar(
              tabs: _CompanyApplicationTab.values
                  .map((tab) => tab.label.tr())
                  .toList(growable: false),
            ),
            CompanyApplicationJobFilterBar(
              label: _jobFilterLabel,
              selectedJobId: _selectedJobId,
              jobs: _jobFilterJobs,
              isLoading: _isJobFilterLoading,
              onChanged: _handleJobFilterChanged,
            ),
            Expanded(
              child: TabBarView(
                children: _CompanyApplicationTab.values
                    .map(
                      (
                        _CompanyApplicationTab tab,
                      ) => _CompanyApplicationTabView(
                        key: PageStorageKey<String>(
                          'company-applications-${tab.name}-${_selectedJobId ?? 'all'}',
                        ),
                        tab: tab,
                        selectedJobId: _selectedJobId,
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

enum _CompanyApplicationTab {
  pending(
    label: '应聘管理.待处理',
    status: 'pending',
    emptyText: '应聘管理.暂无待处理应聘',
    secondaryActionLabel: '通用.打招呼',
  ),
  invited(
    label: '应聘管理.已邀约',
    status: 'invited',
    emptyText: '应聘管理.暂无已邀约应聘',
    secondaryActionLabel: '应聘管理.电话联系',
  ),
  rejected(
    label: '招聘.不合适',
    status: 'rejected',
    emptyText: '应聘管理.暂无不合适应聘',
    secondaryActionLabel: '应聘管理.电话联系',
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
  const _CompanyApplicationTabView({
    super.key,
    required this.tab,
    required this.selectedJobId,
  });

  final _CompanyApplicationTab tab;
  final int? selectedJobId;

  @override
  ConsumerState<_CompanyApplicationTabView> createState() =>
      _CompanyApplicationTabViewState();
}

class _CompanyApplicationTabViewState
    extends ConsumerState<_CompanyApplicationTabView>
    with AutomaticKeepAliveClientMixin<_CompanyApplicationTabView> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(companyApplicationListsControllerProvider.notifier)
          .loadInitial(status: widget.tab.status, jobId: widget.selectedJobId);
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bool success = await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .refresh(status: widget.tab.status, jobId: widget.selectedJobId);
    if (!mounted) {
      return;
    }

    if (success) {
      _refreshController.finishRefresh();
      _refreshController.resetFooter();
    } else {
      _refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  Future<void> _onLoadMore() async {
    final bool success = await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .loadMore(status: widget.tab.status, jobId: widget.selectedJobId);
    if (!mounted) {
      return;
    }

    final CompanyApplicationListState latestState = ref.read(
      companyApplicationListsControllerProvider.select(
        (Map<String, CompanyApplicationListState> states) =>
            states[buildCompanyApplicationListStateKey(
              status: widget.tab.status,
              jobId: widget.selectedJobId,
            )] ??
            const CompanyApplicationListState(),
      ),
    );
    if (success) {
      _refreshController.finishLoad(
        latestState.hasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
    } else {
      _refreshController.finishLoad(IndicatorResult.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final CompanyApplicationListState listState = ref.watch(
      companyApplicationListsControllerProvider.select(
        (Map<String, CompanyApplicationListState> states) =>
            states[buildCompanyApplicationListStateKey(
              status: widget.tab.status,
              jobId: widget.selectedJobId,
            )] ??
            const CompanyApplicationListState(),
      ),
    );

    if (listState.isInitialLoading && !listState.hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    return EasyRefresh(
      controller: _refreshController,
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _onRefresh,
      onLoad: listState.hasMore ? _onLoadMore : null,
      child: listState.applications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                96,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: <Widget>[
                Center(
                  child: AppEmptyState(
                    message: listState.errorMessage ?? '通用.暂无数据'.tr(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                CompanyApplicationManagementStyles.pageHorizontalPadding,
                12,
                CompanyApplicationManagementStyles.pageHorizontalPadding,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: listState.applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final ApplicationVO item = listState.applications[index];
                return CompanyApplicationCard(
                  data: _buildCardData(item, index),
                  onViewResumeTap: () =>
                      _openResumePreview(item.applicant.userId),
                  onSecondaryActionTap: () => _handleSecondaryAction(item),
                );
              },
            ),
    );
  }

  Future<void> _openResumePreview(int userId) async {
    await context.push(RoutePaths.resumePreview, extra: userId);
  }

  /// 根据当前 Tab 的动作定义，执行打招呼或电话联系等二级操作。
  Future<void> _handleSecondaryAction(ApplicationVO item) async {
    if (widget.tab.secondaryActionLabel == '通用.打招呼') {
      await _handleSayHello(item);
      return;
    }

    if (widget.tab.secondaryActionLabel == '应聘管理.电话联系') {
      await _handlePhoneCall(item);
      return;
    }
  }

  /// 直接创建与候选人的聊天会话，并跳转到聊天页。
  Future<void> _handleSayHello(ApplicationVO item) async {
    final int targetUserId = item.applicant.userId;
    if (targetUserId <= 0) {
      _showErrorToast('招聘.用户信息缺失'.tr());
      return;
    }

    try {
      final Map<String, dynamic> response = await ref
          .read(messageServiceProvider)
          .createConversation(
            request: CreateConversationBO(
              targetUserId: targetUserId,
              targetUserRole: 'job_seeker',
            ),
          );
      if (!mounted) {
        return;
      }

      final String nickname = item.applicant.nickname.trim().isEmpty
          ? '招聘.匿名候选人'.tr()
          : item.applicant.nickname.trim();
      await context.push(
        RoutePaths.chat,
        extra: ChatPageArgs(
          targetUserId: targetUserId,
          targetUserRole: 'job_seeker',
          nickname: nickname,
          avatarUrl: item.applicant.avatarUrl,
          conversationId: _readConversationId(response),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorToast(
        ApiErrorFeedback.resolveMessage(error, fallback: '招聘.发起聊天失败'.tr()),
      );
    }
  }

  /// 尝试读取求职者手机号并唤起系统拨号页。
  Future<void> _handlePhoneCall(ApplicationVO item) async {
    final String fallbackName = item.applicant.nickname.trim().isEmpty
        ? '应聘管理.候选人'.tr()
        : item.applicant.nickname.trim();
    try {
      final String phone =
          (await ref
                  .read(resumeServiceProvider)
                  .getResumeByUserId(userId: item.applicant.userId))
              .basicInfo
              .phone
              .trim();
      if (!mounted) {
        return;
      }
      if (phone.isEmpty) {
        _showErrorToast(
          '应聘管理.未获取联系电话'.tr(namedArgs: <String, String>{'name': fallbackName}),
        );
        return;
      }

      final Uri telUri = Uri(scheme: 'tel', path: phone);
      final bool launched = await launchUrl(telUri);
      if (!mounted) {
        return;
      }
      if (!launched) {
        _showErrorToast('应聘管理.暂时无法拨打电话'.tr());
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorToast(_normalizeActionError(error, fallbackName));
    }
  }

  void _showErrorToast(String message) {
    AppToast.show(message);
  }

  int _readConversationId(Map<String, dynamic> raw) {
    final Object? direct = raw['conversationId'] ?? raw['conversation_id'];
    if (direct is int) {
      return direct;
    }
    if (direct is num) {
      return direct.toInt();
    }
    if (direct is String) {
      return int.tryParse(direct) ?? 0;
    }

    final Object? nestedConversation = raw['conversation'];
    if (nestedConversation is Map<String, dynamic>) {
      final Object? nestedId =
          nestedConversation['conversationId'] ??
          nestedConversation['conversation_id'];
      if (nestedId is int) {
        return nestedId;
      }
      if (nestedId is num) {
        return nestedId.toInt();
      }
      if (nestedId is String) {
        return int.tryParse(nestedId) ?? 0;
      }
    }
    return 0;
  }

  String _normalizeActionError(Object error, String fallbackName) {
    return ApiErrorFeedback.resolveMessage(
      error,
      fallback: '应聘管理.获取联系电话失败'.tr(
        namedArgs: <String, String>{'name': fallbackName},
      ),
    );
  }

  CompanyApplicationCardData _buildCardData(ApplicationVO item, int index) {
    return CompanyApplicationCardData(
      positionTitle: item.job.title.trim().isEmpty
          ? '招聘.待定岗位'.tr()
          : item.job.title,
      matchText: '${item.matchScore.clamp(0, 100)}%',
      avatarUrl: item.applicant.avatarUrl,
      name: item.applicant.nickname.trim().isEmpty
          ? '招聘.匿名候选人'.tr()
          : item.applicant.nickname,
      ageGender: _formatAgeGender(item.applicant.age, item.applicant.gender),
      tags: _buildTags(item.applicant),
      submittedText: _formatSubmittedText(item.submittedAt),
      secondaryActionLabel: widget.tab.secondaryActionLabel.tr(),
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
      addTag(
        '招聘.年经验'.tr(
          namedArgs: <String, String>{
            'count': applicant.experienceYears.toString(),
          },
        ),
      );
    }

    if (tags.isEmpty) {
      addTag('招聘.信息待完善'.tr());
    }

    return tags.take(3).toList(growable: false);
  }

  String _formatAgeGender(int age, String gender) {
    final List<String> parts = <String>[];
    if (age > 0) {
      parts.add('招聘.岁'.tr(namedArgs: <String, String>{'count': '$age'}));
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
        return '招聘.男'.tr();
      case 'female':
      case 'woman':
      case 'f':
      case '女':
        return '招聘.女'.tr();
      default:
        return value.trim();
    }
  }

  String _formatSubmittedText(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '首页.刚刚投递'.tr();
    }

    final DateTime? submittedAt = DateTime.tryParse(trimmed)?.toLocal();
    if (submittedAt == null) {
      return trimmed;
    }

    final DateTime now = DateTime.now();
    final Duration difference = now.difference(submittedAt);

    if (difference.inMinutes < 1) {
      return '首页.刚刚投递'.tr();
    }
    if (difference.inMinutes < 60) {
      return '首页.分钟前投递'.tr(
        namedArgs: <String, String>{'count': '${difference.inMinutes}'},
      );
    }
    if (_isSameDay(now, submittedAt)) {
      return '首页.小时前投递'.tr(
        namedArgs: <String, String>{'count': '${difference.inHours}'},
      );
    }

    final DateTime yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    if (_isSameDay(yesterday, submittedAt)) {
      return '首页.昨日投递'.tr(
        namedArgs: <String, String>{
          'time':
              '${_twoDigits(submittedAt.hour)}:${_twoDigits(submittedAt.minute)}',
        },
      );
    }

    return '首页.月日投递'.tr(
      namedArgs: <String, String>{
        'month': _twoDigits(submittedAt.month),
        'day': _twoDigits(submittedAt.day),
        'time':
            '${_twoDigits(submittedAt.hour)}:${_twoDigits(submittedAt.minute)}',
      },
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _twoDigits(int value) {
    return value < 10 ? '0$value' : value.toString();
  }
}
