import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../features/employer/data/employer_models.dart';
import '../../../../features/employer/data/employer_providers.dart';
import '../../../jobs/application/company_applications/company_application_list_state.dart';
import '../../../jobs/application/company_applications/company_application_lists_controller.dart';
import '../../../jobs/data/application_models.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/message_center_icon_button.dart';
import '../../data/home_models.dart';
import '../../data/home_providers.dart';

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
      label: '发布招聘',
      assetPath: 'assets/images/mon6z4rt-qet9p7k.svg',
      fallback: Icons.add_business_outlined,
    ),
    _QuickActionItem(
      label: '人才中心',
      assetPath: 'assets/images/mon6z4rt-vvh6pmo.svg',
      fallback: Icons.school_outlined,
    ),
    _QuickActionItem(
      label: '应聘管理',
      assetPath: 'assets/images/mon6z4ru-nlqxve0.svg',
      fallback: Icons.assignment_ind_outlined,
      routePath: RoutePaths.companyApplications,
    ),
    _QuickActionItem(
      label: '签证服务',
      assetPath: 'assets/images/mon6z4rt-44w61yz.svg',
      fallback: Icons.assignment_outlined,
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? const Color(0xFFD9363E) : null,
          content: Text(message),
        ),
      );
  }

  Future<void> _openResumePreview(int userId) async {
    await context.push(RoutePaths.myResumePreview, extra: userId);
  }

  Future<String?> _showRemarkDialog(String actionLabel) async {
    final TextEditingController controller = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('$actionLabel备注'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请输入备注（选填）',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('确认'),
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
    final String? remark = await _showRemarkDialog(nextStatus.label);
    if (remark == null) {
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
        message: pendingState.errorMessage ?? '暂无待处理应聘',
        buttonLabel: pendingState.errorMessage == null ? null : '重试',
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
          onRejectTap:
              item.status == EmployerApplicationFilterStatus.pending.value
              ? () => _handleApplicationAction(
                  item,
                  EmployerApplicationUpdateStatus.rejected,
                )
              : null,
          onInviteTap:
              item.status == EmployerApplicationFilterStatus.pending.value
              ? () => _handleApplicationAction(
                  item,
                  EmployerApplicationUpdateStatus.interview,
                )
              : null,
          processingAction: processingAction,
        );
      },
    );
  }

  _ResumeCardItem _mapResumeCardItem(ApplicationVO item) {
    final String name = item.applicant.nickname.trim().isEmpty
        ? '匿名候选人'
        : item.applicant.nickname;
    final String title = item.job.title.trim().isEmpty
        ? '待定岗位'
        : item.job.title;
    return _ResumeCardItem(
      applicationId: item.applicationId,
      userId: item.applicant.userId,
      status: item.status,
      name: name,
      ageGender: _formatAgeGender(item.applicant.age, item.applicant.gender),
      appliedJob: '应聘：$title',
      matchPercent: '${item.matchScore.clamp(0, 100)}%',
      tags: _buildTags(item.applicant),
      deliveryTime: _formatSubmittedText(item.submittedAt),
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
          Positioned(
            right: -52,
            bottom: -56,
            child: Container(
              width: 168,
              height: 168,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFF456DFF), Color(0x003584EC)],
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
        Container(
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
              child: const Text(
                '企',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 20 / 17,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 14 / 11,
                    ),
                  ),
                  if (location.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 14 / 11,
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
    return name.isEmpty ? '企业名称待完善' : name;
  }

  String _buildIndustry(EmployerProfileVO? profile) {
    final String industry = profile?.industry.trim() ?? '';
    return industry.isEmpty ? '行业待完善' : industry;
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
      child: const Text(
        '企',
        style: TextStyle(
          color: Color(0xFF6F4200),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _CompanyHeroStatsRow extends ConsumerWidget {
  const _CompanyHeroStatsRow();

  static const List<_HeroStatItem> _items = <_HeroStatItem>[
    _HeroStatItem(value: '8', label: '在招岗位'),
    _HeroStatItem(value: '108', label: '收到简历'),
    _HeroStatItem(value: '13', label: '待面试'),
    _HeroStatItem(value: '4', label: '已录用'),
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
            _HeroStatItem(value: _formatCount(stats.activeJobs), label: '在招岗位'),
            _HeroStatItem(
              value: _formatCount(stats.receivedResumes),
              label: '收到简历',
            ),
            _HeroStatItem(
              value: _formatCount(stats.pendingInterviews),
              label: '待面试',
            ),
            _HeroStatItem(value: _formatCount(stats.hired), label: '已录用'),
          ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 24 / 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
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
  const _HeroStatItem({required this.value, required this.label});

  final String value;
  final String label;
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
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: item.routePath == null
            ? null
            : () => context.push(item.routePath!),
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
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantBanner extends StatelessWidget {
  const _AiAssistantBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'AI业务助手',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '为您精准推荐 5 名资深中餐厨师',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 16 / 12,
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
                    const Text(
                      '查看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 12 / 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/images/mon6z4rt-3ivopc0.png',
                      width: 12,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumeSectionHeader extends StatelessWidget {
  const _ResumeSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            '最新收到简历',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
        ),
        InkWell(
          onTap: () => context.push(RoutePaths.companyApplications),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '全部',
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 20 / 14,
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
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 13,
              height: 20 / 13,
            ),
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
    this.onRejectTap,
    this.onInviteTap,
    this.processingAction,
  });

  final _ResumeCardItem item;
  final VoidCallback onViewResumeTap;
  final VoidCallback? onRejectTap;
  final VoidCallback? onInviteTap;
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
                Image.asset(
                  'assets/images/mon6z4rt-xyu3wvu.png',
                  width: 40,
                  height: 40,
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
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.ageGender,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              height: 18 / 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.appliedJob,
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 12,
                          height: 16 / 12,
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
                        style: const TextStyle(
                          color: Color(0xFF096DD9),
                          fontSize: 16,
                          height: 21 / 16,
                        ),
                      ),
                      const TextSpan(
                        text: ' 匹配',
                        style: TextStyle(
                          color: Color(0xFF096DD9),
                          fontSize: 10,
                          height: 14 / 10,
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
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
                const Spacer(),
                _GhostActionButton(label: '查看简历', onTap: onViewResumeTap),
              ],
            ),
            if (item.status ==
                EmployerApplicationFilterStatus.pending.value) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 109,
                    child: _ApplicationStatusActionButton(
                      label: '不合适',
                      backgroundColor: const Color(0xFFFFEBEB),
                      borderColor: const Color(0x99FF4D4F),
                      textColor: const Color(0xFFD9363E),
                      onTap: processingAction == null ? onRejectTap : null,
                      isLoading:
                          processingAction ==
                          EmployerApplicationUpdateStatus.rejected,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ApplicationStatusActionButton(
                      label: '邀约面试',
                      backgroundColor: const Color(0xFF096DD9),
                      textColor: Colors.white,
                      onTap: processingAction == null ? onInviteTap : null,
                      isLoading:
                          processingAction ==
                          EmployerApplicationUpdateStatus.interview,
                    ),
                  ),
                ],
              ),
            ],
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
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 11,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
        ),
      ),
    );
  }
}

class _ApplicationStatusActionButton extends StatelessWidget {
  const _ApplicationStatusActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    height: 22 / 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.assetPath,
    required this.fallback,
    this.routePath,
  });

  final String label;
  final String assetPath;
  final IconData fallback;
  final String? routePath;
}

class _ResumeCardItem {
  const _ResumeCardItem({
    required this.applicationId,
    required this.userId,
    required this.status,
    required this.name,
    required this.ageGender,
    required this.appliedJob,
    required this.matchPercent,
    required this.tags,
    required this.deliveryTime,
  });

  final int applicationId;
  final int userId;
  final String status;
  final String name;
  final String ageGender;
  final String appliedJob;
  final String matchPercent;
  final List<String> tags;
  final String deliveryTime;
}
