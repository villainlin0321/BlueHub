import 'package:easy_refresh/easy_refresh.dart';
import 'package:easy_localization/easy_localization.dart';
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
          title: Text(
            '我的.应聘管理'.tr(),
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
                  .map((tab) => tab.label.tr())
                  .toList(growable: false),
            ),
            CompanyApplicationJobFilterBar(
              label: '应聘管理.全部岗位'.tr(),
              onTap: () => _showPlaceholderSnackBar(
                context,
                '应聘管理.岗位筛选功能'.tr(),
              ),
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
      ..showSnackBar(
        SnackBar(
          content: Text(
            '我的.占位提示'.tr(namedArgs: <String, String>{'label': label}),
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
    secondaryActionLabel: '招聘.邀约面试',
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
              message: listState.errorMessage ?? widget.tab.emptyText.tr(),
              icon: listState.errorMessage == null
                  ? Icons.assignment_outlined
                  : Icons.error_outline_rounded,
              buttonLabel: listState.errorMessage == null
                  ? null
                  : '我的.重新加载'.tr(),
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

  /// 根据当前 Tab 的动作定义，执行邀约或电话联系等二级操作。
  Future<void> _handleSecondaryAction(ApplicationVO item) async {
    if (widget.tab.secondaryActionLabel == '招聘.邀约面试') {
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

    if (widget.tab.secondaryActionLabel == '应聘管理.电话联系') {
      await _handlePhoneCall(item);
      return;
    }

    _showPlaceholderSnackBar(context, widget.tab.secondaryActionLabel.tr());
  }

  /// 尝试读取求职者手机号并唤起系统拨号页。
  Future<void> _handlePhoneCall(ApplicationVO item) async {
    final String fallbackName = item.applicant.nickname.trim().isEmpty
        ? '应聘管理.候选人'.tr()
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
        _showErrorSnackBar(
          '应聘管理.未获取联系电话'.tr(
            namedArgs: <String, String>{'name': fallbackName},
          ),
        );
        return;
      }

      final Uri telUri = Uri(scheme: 'tel', path: phone);
      final bool launched = await launchUrl(telUri);
      if (!mounted) {
        return;
      }
      if (!launched) {
        _showErrorSnackBar('应聘管理.暂时无法拨打电话'.tr());
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
      return normalized.isEmpty
          ? '应聘管理.获取联系电话失败'.tr(
              namedArgs: <String, String>{'name': fallbackName},
            )
          : normalized;
    }
    return message.isEmpty
        ? '应聘管理.获取联系电话失败'.tr(
            namedArgs: <String, String>{'name': fallbackName},
          )
        : message;
  }

  CompanyApplicationCardData _buildCardData(ApplicationVO item, int index) {
    return CompanyApplicationCardData(
      positionTitle: item.job.title.trim().isEmpty
          ? '招聘.待定岗位'.tr()
          : item.job.title,
      matchText: '${item.matchScore.clamp(0, 100)}%',
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

  void _showPlaceholderSnackBar(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '我的.占位提示'.tr(namedArgs: <String, String>{'label': label}),
          ),
        ),
      );
  }
}
