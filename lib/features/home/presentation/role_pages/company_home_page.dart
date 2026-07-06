import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../features/employer/data/employer_models.dart';
import '../../../../features/employer/data/employer_providers.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../jobs/application/company_applications/company_application_list_state.dart';
import '../../../jobs/application/company_applications/company_application_lists_controller.dart';
import '../../../jobs/data/application_models.dart';
import '../../../jobs/presentation/widgets/company_application_management_widgets.dart';
import '../../../me/data/resume_providers.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/message_center_icon_button.dart';
import '../../data/home_models.dart';
import '../../data/home_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

final _currentEmployerProfileProvider =
    FutureProvider.autoDispose<EmployerProfileVO>((ref) async {
      final service = ref.watch(employerServiceProvider);
      return service.getEmployerProfile();
    });

/// 企业首页。
class CompanyHomePage extends ConsumerStatefulWidget {
  const CompanyHomePage({super.key});

  static const List<_QuickActionItem> _quickActions = <_QuickActionItem>[
    _QuickActionItem(
      labelKey: '首页.发布招聘',
      assetPath: 'assets/images/mon6azmx-yws4mpq.svg',
      fallback: Icons.add_business_outlined,
      routePath: RoutePaths.postJob,
    ),
    _QuickActionItem(
      labelKey: '招聘.人才中心',
      assetPath: 'assets/images/mon6azmx-gxjq4wk.svg',
      fallback: Icons.school_outlined,
      tabRoutePath: RoutePaths.jobs,
    ),
    _QuickActionItem(
      labelKey: '我的.应聘管理',
      assetPath: 'assets/images/mon6z4ru-nlqxve0.svg',
      fallback: Icons.assignment_ind_outlined,
      routePath: RoutePaths.companyApplications,
    ),
    _QuickActionItem(
      labelKey: '首页.签证服务',
      assetPath: 'assets/images/mon6z4rt-44w61yz.svg',
      fallback: Icons.assignment_outlined,
      routePath: RoutePaths.companyVisaService,
    ),
  ];

  @override
  ConsumerState<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends ConsumerState<CompanyHomePage> {
  static final String _pendingStatus =
      EmployerApplicationFilterStatus.pending.value;
  static const int _previewItemCount = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(companyApplicationListsControllerProvider.notifier)
          .loadInitial(status: _pendingStatus);
    });
  }

  Future<void> _reloadPendingApplications() async {
    await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .loadInitial(status: _pendingStatus, force: true);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    AppToast.show(message);
  }

  Future<void> _openResumePreview(int userId) async {
    await context.push(RoutePaths.resumePreview, extra: userId);
  }

  Future<String?> _showRemarkDialog(String actionLabel) async {
    final TextEditingController controller = TextEditingController();
    final String? result = await showAppDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppDialog(
          title: '首页.备注标题'.tr(
            namedArgs: <String, String>{'action': actionLabel},
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ).copyWith(hintText: '招聘.请输入备注选填'.tr()),
          ),
          actions: <AppDialogAction>[
            AppDialogAction.secondary(
              label: '通用.取消'.tr(),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppDialogAction.primary(
              label: '通用.确定'.tr(),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _handleApplicationAction(
    _ResumeCardItem item,
    EmployerApplicationUpdateStatus nextStatus,
  ) async {
    final String? remark = await _showRemarkDialog(nextStatus.labelKey.tr());
    if (remark == null || !mounted) {
      return;
    }

    final ApplicationStatusUpdateResult result = await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .updateApplicationStatus(
          sourceStatus: _pendingStatus,
          applicationId: item.applicationId,
          nextStatus: nextStatus,
          remark: remark,
        );
    _showMessage(result.message, isError: !result.success);
  }

  Future<void> _handleSecondaryAction(_ResumeCardItem item) async {
    if (item.status == EmployerApplicationFilterStatus.pending.value) {
      await _handleApplicationAction(
        item,
        EmployerApplicationUpdateStatus.interview,
      );
      return;
    }
    await _handlePhoneCall(item);
  }

  Future<void> _handlePhoneCall(_ResumeCardItem item) async {
    final String fallbackName = item.name.trim().isEmpty
        ? '应聘管理.候选人'.tr()
        : item.name.trim();
    try {
      final String phone =
          (await ref
                  .read(resumeServiceProvider)
                  .getResumeByUserId(userId: item.userId))
              .basicInfo
              .phone
              .trim();
      if (!mounted) {
        return;
      }
      if (phone.isEmpty) {
        _showMessage(
          '应聘管理.未获取联系电话'.tr(namedArgs: <String, String>{'name': fallbackName}),
          isError: true,
        );
        return;
      }

      final Uri telUri = Uri(scheme: 'tel', path: phone);
      final bool launched = await launchUrl(telUri);
      if (!mounted) {
        return;
      }
      if (!launched) {
        _showMessage('应聘管理.暂时无法拨打电话'.tr(), isError: true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_normalizeActionError(error, fallbackName), isError: true);
    }
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
        ? '应聘管理.获取联系电话失败'.tr(namedArgs: <String, String>{'name': fallbackName})
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final EmployerProfileVO? employerProfile = ref
        .watch(_currentEmployerProfileProvider)
        .asData
        ?.value;
    final CompanyApplicationListState pendingState = ref.watch(
      companyApplicationListsControllerProvider.select(
        (Map<String, CompanyApplicationListState> states) =>
            states[_pendingStatus] ?? const CompanyApplicationListState(),
      ),
    );
    final List<_ResumeCardItem> resumeItems = pendingState.applications
        .take(_previewItemCount)
        .map(_mapResumeCardItem)
        .toList(growable: false);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeroSection(profile: employerProfile),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _QuickActionRow(items: CompanyHomePage._quickActions),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _AiAssistantBanner(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _ResumeSectionHeader(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPendingResumeSection(
              pendingState: pendingState,
              resumeItems: resumeItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingResumeSection({
    required CompanyApplicationListState pendingState,
    required List<_ResumeCardItem> resumeItems,
  }) {
    if (pendingState.isInitialLoading && !pendingState.hasLoadedOnce) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (resumeItems.isEmpty) {
      return _ResumeStateCard(
        message: pendingState.errorMessage ?? '招聘.未找到待处理应聘记录'.tr(),
        buttonLabel: pendingState.errorMessage == null ? null : '通用.重试'.tr(),
        onTap: pendingState.errorMessage == null
            ? null
            : _reloadPendingApplications,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: resumeItems.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final _ResumeCardItem item = resumeItems[index];
        final EmployerApplicationUpdateStatus? processingAction =
            pendingState.processingActions[item.applicationId];
        return _ResumeCard(
          item: item,
          onViewResumeTap: () => _openResumePreview(item.userId),
          onSecondaryActionTap: () => _handleSecondaryAction(item),
          processingAction: processingAction,
        );
      },
    );
  }

  _ResumeCardItem _mapResumeCardItem(ApplicationVO item) {
    final String name = item.applicant.nickname.trim().isEmpty
        ? '招聘.匿名候选人'.tr()
        : item.applicant.nickname;
    final String title = item.job.title.trim().isEmpty
        ? '招聘.待定岗位'.tr()
        : item.job.title;
    return _ResumeCardItem(
      applicationId: item.applicationId,
      userId: item.applicant.userId,
      status: item.status,
      avatarUrl: item.applicant.avatarUrl,
      name: name,
      ageGender: _formatAgeGender(item.applicant.age, item.applicant.gender),
      appliedJob: '首页.应聘职位'.tr(namedArgs: <String, String>{'title': title}),
      matchPercent: '${item.matchScore.clamp(0, 100)}%',
      tags: _buildTags(item.applicant),
      deliveryTime: _formatSubmittedText(item.submittedAt),
      secondaryActionLabel: _resolveSecondaryActionLabel(item.status),
    );
  }

  String _resolveSecondaryActionLabel(String status) {
    if (status == EmployerApplicationFilterStatus.pending.value) {
      return '招聘.邀约面试'.tr();
    }
    return '应聘管理.电话联系'.tr();
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
      parts.add(
        '招聘.岁'.tr(namedArgs: <String, String>{'count': age.toString()}),
      );
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
        return '我的.男'.tr();
      case 'female':
      case 'woman':
      case 'f':
      case '女':
        return '我的.女'.tr();
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
        namedArgs: <String, String>{'count': difference.inMinutes.toString()},
      );
    }
    if (_isSameDay(now, submittedAt)) {
      return '首页.小时前投递'.tr(
        namedArgs: <String, String>{'count': difference.inHours.toString()},
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({this.profile});

  final EmployerProfileVO? profile;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3F9BF7), Color(0xFF2F73E5)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -36,
            top: -36,
            child: Container(
              width: 156,
              height: 156,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFF1FDAFF), Color(0x003584EC)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, topPadding + 10, 14, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _CompanyHeroTopRow(profile: profile),
                const SizedBox(height: 18),
                const _CompanyHeroStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeroTopRow extends StatelessWidget {
  const _CompanyHeroTopRow({this.profile});

  final EmployerProfileVO? profile;

  @override
  Widget build(BuildContext context) {
    final String companyName = _buildCompanyName(profile);
    final String industry = _buildIndustry(profile);
    final String location = _buildLocation(profile);
    final bool isVerified = profile?.isVerified ?? true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: () => context.push(RoutePaths.companyMyInfo),
          behavior: HitTestBehavior.opaque,
          child: AppUserAvatar(
            imageUrl: profile?.logoUrl ?? '',
            size: 40,
            backgroundColor: Colors.transparent,
            placeholder: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '通用.企业简称'.tr(),
                    style: TestStyle.numberBold(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TestStyle.semibold(
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isVerified) ...<Widget>[
                    const SizedBox(width: 6),
                    const _EnterpriseBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    industry,
                    style: TestStyle.regular(fontSize: 11, color: Colors.white),
                  ),
                  if (location.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: TestStyle.regular(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const MessageCenterIconButton(),
      ],
    );
  }

  String _buildCompanyName(EmployerProfileVO? profile) {
    final String name = profile?.companyName.trim() ?? '';
    return name.isEmpty ? '我的.企业名称待完善'.tr() : name;
  }

  String _buildIndustry(EmployerProfileVO? profile) {
    final String industry = profile?.industry.trim() ?? '';
    return industry.isEmpty ? '我的.行业待完善'.tr() : industry;
  }

  String _buildLocation(EmployerProfileVO? profile) {
    final List<String> parts = <String>[
      profile?.country.trim() ?? '',
      profile?.city.trim() ?? '',
    ].where((String item) => item.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }
}

class _EnterpriseBadge extends StatelessWidget {
  const _EnterpriseBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFED86B),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '企',
        style: TestStyle.numberBold(fontSize: 9, color: Color(0xFF6F4200)),
      ),
    );
  }
}

class _CompanyHeroStatsRow extends ConsumerWidget {
  const _CompanyHeroStatsRow();

  static const List<_HeroStatItem> _items = <_HeroStatItem>[
    _HeroStatItem(value: '8', labelKey: '我的.在招岗位'),
    _HeroStatItem(value: '108', labelKey: '我的.收到简历'),
    _HeroStatItem(value: '13', labelKey: '我的.待面试'),
    _HeroStatItem(value: '4', labelKey: '我的.已录用'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeDashboardStatsVO? stats = ref
        .watch(homeDashboardStatsProvider)
        .asData
        ?.value;
    final List<_HeroStatItem> items = stats == null
        ? _items
        : <_HeroStatItem>[
            _HeroStatItem(
              value: _formatCount(stats.activeJobs),
              labelKey: '我的.在招岗位',
            ),
            _HeroStatItem(
              value: _formatCount(stats.receivedResumes),
              labelKey: '我的.收到简历',
            ),
            _HeroStatItem(
              value: _formatCount(stats.pendingInterviews),
              labelKey: '我的.待面试',
            ),
            _HeroStatItem(value: _formatCount(stats.hired), labelKey: '我的.已录用'),
          ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    item.value,
                    style: TestStyle.semibold(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.labelKey.tr(),
                    textAlign: TextAlign.center,
                    style: TestStyle.regular(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeroStatItem {
  const _HeroStatItem({required this.value, required this.labelKey});

  final String value;
  final String labelKey;
}

String _formatCount(int? value) => (value ?? 0).toString();

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.items});

  final List<_QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => _QuickActionButton(item: item))
          .toList(growable: false),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = switch ((item.tabRoutePath, item.routePath)) {
      (final String tabRoutePath?, _) => () => context.go(tabRoutePath),
      (_, final String routePath?) => () => context.push(routePath),
      _ => null,
    };

    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: item.assetPath,
                  fallback: item.fallback,
                  size: 24,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.labelKey.tr(),
              textAlign: TextAlign.center,
              style: TestStyle.regular(fontSize: 12, color: Color(0xFF171A1D)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantBanner extends ConsumerWidget {
  const _AiAssistantBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeDashboardStatsVO? stats = ref
        .watch(homeDashboardStatsProvider)
        .asData
        ?.value;
    final String aiContent = stats?.aiContent?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(RoutePaths.ai),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/mon6z4rt-nbxozyy.svg',
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'assets/images/mon6z4rt-kh50fma.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '招聘.AI业务助手'.tr(),
                          style: TestStyle.pingFangRegular(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          aiContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TestStyle.pingFangRegular(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '招聘.查看'.tr(),
                          style: TestStyle.pingFangMedium(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 2),
                        SvgPicture.asset(
                          'assets/images/chat_page_order_arrow.svg',
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeSectionHeader extends StatelessWidget {
  const _ResumeSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '首页.最新收到简历'.tr(),
            style: TestStyle.pingFangMedium(
              fontSize: 16,
              color: Color(0xFF262626),
            ),
          ),
        ),
        InkWell(
          onTap: () => context.push(RoutePaths.companyApplications),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '订单.全部'.tr(),
                  style: TestStyle.pingFangRegular(
                    fontSize: 14,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_right, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumeStateCard extends StatelessWidget {
  const _ResumeStateCard({required this.message, this.buttonLabel, this.onTap});

  final String message;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            message,
            style: TestStyle.regular(fontSize: 13, color: Color(0xFF8C8C8C)),
          ),
          if (buttonLabel != null && onTap != null) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(onPressed: onTap, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.item,
    required this.onViewResumeTap,
    required this.onSecondaryActionTap,
    this.processingAction,
  });

  final _ResumeCardItem item;
  final VoidCallback onViewResumeTap;
  final VoidCallback onSecondaryActionTap;
  final EmployerApplicationUpdateStatus? processingAction;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppUserAvatar(
                  imageUrl: item.avatarUrl,
                  size: 40,
                  placeholderAssetPath: 'assets/images/mon6z4rt-xyu3wvu.png',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            item.name,
                            style: TestStyle.medium(
                              fontSize: 16,
                              color: Color(0xFF262626),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.ageGender,
                            style: TestStyle.regular(
                              fontSize: 12,
                              color: Color(0xFF8C8C8C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.appliedJob,
                        style: TestStyle.regular(
                          fontSize: 12,
                          color: Color(0xFF595959),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: item.matchPercent,
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Color(0xFF096DD9),
                        ),
                      ),
                      TextSpan(
                        text: ' ${'招聘.匹配度'.tr()}',
                        style: TestStyle.pingFangRegular(
                          fontSize: 10,
                          color: Color(0xFF096DD9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags
                  .map((tag) => _SkillTag(label: tag))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  item.deliveryTime,
                  style: TestStyle.pingFangRegular(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
                const Spacer(),
                CompanyApplicationActionButton(
                  label: '招聘.查看简历'.tr(),
                  onTap: onViewResumeTap,
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  ignoring: processingAction != null,
                  child: Opacity(
                    opacity: processingAction == null ? 1 : 0.6,
                    child: CompanyApplicationActionButton(
                      label: item.secondaryActionLabel,
                      primary: true,
                      onTap: onSecondaryActionTap,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 11, color: Color(0xFF546D96)),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.labelKey,
    required this.assetPath,
    required this.fallback,
    this.tabRoutePath,
    this.routePath,
  });

  final String labelKey;
  final String assetPath;
  final IconData fallback;
  final String? tabRoutePath;
  final String? routePath;
}

class _ResumeCardItem {
  const _ResumeCardItem({
    required this.applicationId,
    required this.userId,
    required this.status,
    required this.avatarUrl,
    required this.name,
    required this.ageGender,
    required this.appliedJob,
    required this.matchPercent,
    required this.tags,
    required this.deliveryTime,
    required this.secondaryActionLabel,
  });

  final int applicationId;
  final int userId;
  final String status;
  final String avatarUrl;
  final String name;
  final String ageGender;
  final String appliedJob;
  final String matchPercent;
  final List<String> tags;
  final String deliveryTime;
  final String secondaryActionLabel;
}
