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
import '../../../../shared/widgets/app_empty_state.dart';
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

  /// 重新拉取待处理应聘列表，用于空态重试。
  Future<void> _reloadPendingApplications() async {
    await ref
        .read(companyApplicationListsControllerProvider.notifier)
        .loadInitial(status: _pendingStatus, force: true);
  }

  /// 统一显示页面提示消息。
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    AppToast.show(message);
  }

  /// 打开简历预览页。
  Future<void> _openResumePreview(int userId) async {
    await context.push(RoutePaths.resumePreview, extra: userId);
  }

  /// 弹出备注输入框，供状态流转时填写备注。
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

  /// 处理应聘状态变更，并在完成后刷新对应列表状态。
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

  /// 根据候选人当前状态分发次要操作。
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

  /// 获取候选人手机号并发起拨号。
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

  /// 规整动作失败提示，优先透传接口返回文案。
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

  /// 根据当前加载状态构建简历预览区域。
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
        message: pendingState.errorMessage ?? '暂无数据'.tr(),
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

  /// 将接口返回的应聘记录映射为首页卡片所需数据。
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

  /// 解析简历卡片右下角的次操作文案。
  String _resolveSecondaryActionLabel(String status) {
    if (status == EmployerApplicationFilterStatus.pending.value) {
      return '招聘.邀约面试'.tr();
    }
    return '应聘管理.电话联系'.tr();
  }

  /// 组装候选人标签，优先展示接口关键标签。
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

  /// 组合年龄与性别文案。
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

  /// 将接口性别值规整为页面展示文案。
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

  /// 格式化投递时间，优先展示相对时间。
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

  /// 判断两个时间是否处于同一天。
  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  /// 将数字补足为两位字符串。
  String _twoDigits(int value) {
    return value < 10 ? '0$value' : value.toString();
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({this.profile});

  static const double _figmaSafeAreaHeight = 44;
  static const double _figmaContentHeight = 176 - _figmaSafeAreaHeight;
  static const BorderRadius _heroBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  final EmployerProfileVO? profile;

  /// 构建企业首页顶部卡片，补足蓝色主渐变与白色柔光层。
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    // 设计稿总高 176，其中顶部 44 为安全区，因此非安全区内容高固定为 132。
    final double heroHeight = topPadding + _figmaContentHeight;

    return SizedBox(
      height: heroHeight,
      child: ClipRRect(
        borderRadius: _heroBorderRadius,
        child: Container(
          decoration: _buildHeroDecoration(),
          child: Stack(
            children: <Widget>[
              // 按设计稿叠加两层蓝色径向高光，避免出现偏白的蒙层。
              Positioned(
                left: -124,
                top: -42,
                child: _HeroGlow(
                  width: 290,
                  height: 230,
                  decoration: _buildTopGlowDecoration(),
                ),
              ),
              Positioned(
                right: -112,
                bottom: -80,
                child: _HeroGlow(
                  width: 304,
                  height: 232,
                  decoration: _buildBottomGlowDecoration(),
                ),
              ),
              Padding(
                // 头部总高已按 44 安全区 + 132 内容区固定，这里同步收紧内容区上下留白。
                padding: EdgeInsets.fromLTRB(14, topPadding + 8, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _CompanyHeroTopRow(profile: profile),
                    const SizedBox(height: 12),
                    const _CompanyHeroStatsRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 蓝色主渐变底图，匹配设计稿从亮到深的层次过渡。
  BoxDecoration _buildHeroDecoration() {
    return const BoxDecoration(
      borderRadius: _heroBorderRadius,
      gradient: LinearGradient(
        begin: Alignment(-0.91, -0.03),
        end: Alignment(-0.25, 1.6),
        colors: <Color>[Color(0xFF3F9BF7), Color(0xFF2F73E5)],
      ),
    );
  }

  /// 左上角青蓝色高光，对应 Figma 导出的第二层径向渐变。
  BoxDecoration _buildTopGlowDecoration() {
    return const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(-0.86, -0.92),
        radius: 1.02,
        colors: <Color>[Color(0xFF1FDAFF), Color(0x033584EC)],
      ),
    );
  }

  /// 右下角深蓝色高光，对应 Figma 导出的第一层径向渐变。
  BoxDecoration _buildBottomGlowDecoration() {
    return const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: Alignment(0.94, 0.86),
        radius: 1.08,
        colors: <Color>[Color(0xFF456DFF), Color(0x033584EC)],
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(15),
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
                      style: TestStyle.pingFangSemibold(
                        fontSize: 18,
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
                    style: TestStyle.pingFangRegular(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  if (location.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: TestStyle.pingFangRegular(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.92),
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

  /// 企业认证角标，尽量贴近设计稿中的金色小标识。
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
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
                    style: TestStyle.pingFangSemibold(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.labelKey.tr(),
                    textAlign: TextAlign.center,
                    style: TestStyle.pingFangRegular(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.96),
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

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 74,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(14),
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
              const SizedBox(height: 10),
              Text(
                item.labelKey.tr(),
                textAlign: TextAlign.center,
                style: TestStyle.pingFangMedium(
                  fontSize: 12,
                  color: Color(0xFF171A1D),
                ),
              ),
            ],
          ),
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
                          style: TestStyle.pingFangSemibold(
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
            style: TestStyle.pingFangSemibold(
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFFB8B8B8),
                ),
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

  /// 构建“最新收到简历”空态或异常态卡片。
  @override
  Widget build(BuildContext context) {
    return Container(
      height: buttonLabel == null ? 236 : 268,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          const Spacer(),
          AppEmptyState(
            message: buttonLabel == null ? message : '暂无数据'.tr(),
            imageWidth: 112,
            imageHeight: 112,
            textTopSpacing: 12,
            textStyle: TestStyle.pingFangRegular(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const Spacer(),
          if (buttonLabel != null && onTap != null) ...<Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.pingFangRegular(
                fontSize: 12,
                color: Color(0xFF8C8C8C),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onTap, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow({
    required this.width,
    required this.height,
    required this.decoration,
  });

  final double width;
  final double height;
  final Decoration decoration;

  /// 渲染顶部卡片的柔光圆斑，用于增强设计稿的渐变层次。
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: decoration,
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
