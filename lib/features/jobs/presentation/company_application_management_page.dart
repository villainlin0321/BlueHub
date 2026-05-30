import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_paths.dart';
import '../../me/data/resume_providers.dart';
import '../application/company_applications/company_application_list_state.dart';
import '../application/company_applications/company_application_lists_controller.dart';
import '../data/application_models.dart';
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
          title: const Text(
            '应聘管理',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 24 / 17,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
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
          .loadInitial(status: widget.tab.status);
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .loadInitial(status: widget.tab.status, force: true);
  }

  Future<void> _onRefresh() async {
    final bool success = await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .refresh(status: widget.tab.status);
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
        .loadMore(status: widget.tab.status);
    if (!mounted) {
      return;
    }

    final CompanyApplicationListState latestState = ref.read(
      companyApplicationListsControllerProvider.select(
        (Map<String, CompanyApplicationListState> states) =>
            states[widget.tab.status] ?? const CompanyApplicationListState(),
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
            states[widget.tab.status] ?? const CompanyApplicationListState(),
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
          ? CompanyApplicationListStateView(
              message: listState.errorMessage ?? widget.tab.emptyText,
              icon: listState.errorMessage == null
                  ? Icons.assignment_outlined
                  : Icons.error_outline_rounded,
              buttonLabel: listState.errorMessage == null ? null : '重新加载',
              onTap: listState.errorMessage == null ? null : _loadInitial,
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
                  onViewResumeTap: () => _openResumePreview(item.applicant.userId),
                  onSecondaryActionTap: () => _handleSecondaryAction(item),
                );
              },
            ),
    );
  }

  Future<void> _openResumePreview(int userId) async {
    await context.push(RoutePaths.myResumePreview, extra: userId);
  }

  Future<void> _handleSecondaryAction(ApplicationVO item) async {
    if (widget.tab.secondaryActionLabel == '邀约面试') {
      final ApplicationStatusUpdateResult result = await ref
          .read(companyApplicationListsControllerProvider.notifier)
          .updateApplicationStatus(
            sourceStatus: widget.tab.status,
            applicationId: item.applicationId,
            nextStatus: EmployerApplicationUpdateStatus.interview,
            remark: '',
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? null : const Color(0xFFD9363E),
          ),
        );
      if (!result.success) {
        return;
      }
      return;
    }

    if (widget.tab.secondaryActionLabel == '电话联系') {
      await _handlePhoneCall(item);
      return;
    }

    _showPlaceholderSnackBar(context, widget.tab.secondaryActionLabel);
  }

  Future<void> _handlePhoneCall(ApplicationVO item) async {
    final String fallbackName = item.applicant.nickname.trim().isEmpty
        ? '候选人'
        : item.applicant.nickname.trim();
    try {
      final String phone = (await ref
              .read(resumeServiceProvider)
              .getResumeByUserId(userId: item.applicant.userId))
          .basicInfo
          .phone
          .trim();
      if (!mounted) {
        return;
      }
      if (phone.isEmpty) {
        _showErrorSnackBar('未获取到$fallbackName的联系电话');
        return;
      }

      final Uri telUri = Uri(scheme: 'tel', path: phone);
      final bool launched = await launchUrl(telUri);
      if (!mounted) {
        return;
      }
      if (!launched) {
        _showErrorSnackBar('暂时无法拨打电话，请稍后重试');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar(_normalizeActionError(error, fallbackName));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFD9363E),
        ),
      );
  }

  String _normalizeActionError(Object error, String fallbackName) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      final String normalized = message.substring('Exception: '.length).trim();
      return normalized.isEmpty ? '获取$fallbackName联系电话失败，请稍后重试' : normalized;
    }
    return message.isEmpty ? '获取$fallbackName联系电话失败，请稍后重试' : message;
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
