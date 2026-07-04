import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/models/talent_models.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../data/application_models.dart';
import '../../data/job_models.dart';
import '../../data/application_providers.dart';
import '../../data/talent_providers.dart';
import '../widgets/invite_job_picker_sheet.dart';

import 'package:europepass/shared/ui/test_style.dart';
/// 企业招聘页：按 Figma「人才中心」实现。
class CompanyJobsPage extends ConsumerStatefulWidget {
  const CompanyJobsPage({super.key});

  @override
  ConsumerState<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

class _CompanyJobsPageState extends ConsumerState<CompanyJobsPage> {
  int _selectedTabIndex = 0;
  final Set<int> _processingInviteUserIds = <int>{};

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(_handleSearchChanged);

  String? get _keyword {
    final String value = _searchController.text.trim();
    return value.isEmpty ? null : value;
  }

  String _sortForTab(int index) => switch (index) {
    1 => 'active',
    2 => 'match',
    _ => 'latest',
  };

  String get _selectedSort => _sortForTab(_selectedTabIndex);

  TalentListQuery _buildQueryForTab(int index) => TalentListQuery(
    keyword: _keyword,
    position: index == 3 ? tr('招聘.中餐厨师') : null,
    sort: _sortForTab(index),
    page: 1,
    pageSize: 20,
  );

  TalentListQuery get _query => _buildQueryForTab(_selectedTabIndex);

  void _handleSearchChanged() {
    setState(() {});
  }

  void _handleTalentTabChanged(int index) {
    final TalentListQuery nextQuery = _buildQueryForTab(index);
    setState(() {
      _selectedTabIndex = index;
    });
    ref.invalidate(talentListProvider(nextQuery));
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
    return showAppDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _RemarkDialog(actionLabel: actionLabel);
      },
    );
  }

  Future<void> _handleInviteInterview(_CandidateCardData data) async {
    if (_processingInviteUserIds.contains(data.userId)) {
      return;
    }

    final String? remark = await _showRemarkDialog(
      EmployerApplicationUpdateStatus.interview.labelKey.tr(),
    );
    if (remark == null || !mounted) {
      return;
    }
    final JobDetailVO? selectedJob = await showInviteJobPickerSheet(context);
    if (selectedJob == null || !mounted) {
      return;
    }

    setState(() {
      _processingInviteUserIds.add(data.userId);
    });

    try {
      if (data.resumeId <= 0 || selectedJob.jobId <= 0) {
        _showMessage('招聘.邀约失败'.tr(), isError: true);
        return;
      }
      await ref
          .read(applicationServiceProvider)
          .inviteInterview(
            request: InviteInterviewBO(
              jobId: selectedJob.jobId,
              resumeId: data.resumeId,
              remark: remark.trim().isEmpty ? null : remark.trim(),
            ),
          );
      _showMessage('招聘.邀约面试'.tr());
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _processingInviteUserIds.remove(data.userId);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final talentsAsync = ref.watch(talentListProvider(_query));

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      children: <Widget>[
        _Header(topPadding: topPadding),
        _SearchBar(controller: _searchController),
        _TabBarSection(
          selectedIndex: _selectedTabIndex,
          onTap: _handleTalentTabChanged,
        ),
        const _AiBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 12, 14, 0),
          child: talentsAsync.when(
            data: (pageResult) {
              if (pageResult.list.isEmpty) {
                return const _TalentsEmptyState();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageResult.list.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return _CandidateCard(
                    data: _CandidateCardData.fromTalent(
                      pageResult.list[index],
                      sort: _selectedSort,
                    ),
                    onViewResumeTap: () =>
                        _openResumePreview(pageResult.list[index].userId),
                    onInviteTap: () => _handleInviteInterview(
                      _CandidateCardData.fromTalent(
                        pageResult.list[index],
                        sort: _selectedSort,
                      ),
                    ),
                    isInviteLoading: _processingInviteUserIds.contains(
                      pageResult.list[index].userId,
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => _TalentLoadError(
              onRetry: () {
                ref.invalidate(talentListProvider(_query));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RemarkDialog extends StatefulWidget {
  const _RemarkDialog({required this.actionLabel});

  final String actionLabel;

  @override
  State<_RemarkDialog> createState() => _RemarkDialogState();
}

class _RemarkDialogState extends State<_RemarkDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '${widget.actionLabel}${'招聘.备注'.tr()}',
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '招聘.请输入备注选填'.tr(),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <AppDialogAction>[
        AppDialogAction.secondary(
          label: '通用.取消'.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction.primary(
          label: '通用.确定'.tr(),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '招聘.人才中心'.tr(),
              style: TestStyle.pingFangMedium(fontSize: 17, color: Color(0xE6000000)),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '招聘.筛选'.tr(),
              style: TestStyle.pingFangRegular(fontSize: 15, color: Color(0xFF262626)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/mou52cw6-pzdc72z.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF262626)),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '招聘.搜索岗位技能经验'.tr(),
                  hintStyle: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFFBFBFBF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarSection extends StatelessWidget {
  const _TabBarSection({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;
  List<String> get _tabs => <String>[
    tr('招聘.全部人才'),
    tr('招聘.近期活跃'),
    tr('招聘.高匹配度'),
    tr('招聘.厨师岗位'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(_tabs.length, (int index) {
          final bool selected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Padding(
                padding: EdgeInsets.only(top: 11, bottom: selected ? 0 : 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _tabs[index],
                      textAlign: TextAlign.center,
                      style: TestStyle.medium(fontSize: 14, color: selected
                            ? const Color(0xFF096DD9)
                            : const Color(0xFF262626)),
                    ),
                    if (selected) ...<Widget>[
                      const SizedBox(height: 9),
                      Container(
                        width: 20,
                        height: 2,
                        color: const Color(0xFF096DD9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  const _AiBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(RoutePaths.ai),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/mou52cw6-a9gamk4.svg',
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/images/mou52cw6-nklu474.png',
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '招聘.AI业务助手'.tr(),
                              style: TestStyle.pingFangRegular(fontSize: 15, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '招聘.AI推荐文案'.tr(),
                              style: TestStyle.pingFangRegular(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      _BannerAction(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 28,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '招聘.查看'.tr(),
                  style: TestStyle.pingFangMedium(fontSize: 12, color: Colors.white, letterSpacing: 0.2),
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
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.data,
    required this.onViewResumeTap,
    required this.onInviteTap,
    this.isInviteLoading = false,
  });

  final _CandidateCardData data;
  final VoidCallback onViewResumeTap;
  final VoidCallback onInviteTap;
  final bool isInviteLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CandidateAvatar(avatarUrl: data.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            data.name,
                            style: TestStyle.medium(fontSize: 16, color: Color(0xFF262626)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data.ageGender,
                            style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.intention,
                        style: TestStyle.regular(fontSize: 12, color: Color(0xFF595959)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: <Widget>[
                    Text(
                      data.scoreText,
                      style: TestStyle.regular(fontSize: 16, color: Color(0xFF096DD9)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.scoreLabel,
                      style: TestStyle.regular(fontSize: 10, color: Color(0xFF096DD9)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.tags
                  .map((String tag) => _CandidateTag(label: tag))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  data.updatedText,
                  style: TestStyle.pingFangRegular(fontSize: 12, color: Color(0xFF8C8C8C)),
                ),
                const Spacer(),
                _ResumeActionButton(
                  label: '招聘.查看简历'.tr(),
                  primary: false,
                  onTap: onViewResumeTap,
                ),
                const SizedBox(width: 8),
                _ResumeActionButton(
                  label: '招聘.邀约面试'.tr(),
                  primary: true,
                  onTap: isInviteLoading ? null : onInviteTap,
                  isLoading: isInviteLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTag extends StatelessWidget {
  const _CandidateTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4), width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 11, color: Color(0xFF546D96)),
      ),
    );
  }
}

class _ResumeActionButton extends StatelessWidget {
  const _ResumeActionButton({
    required this.label,
    required this.primary,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final bool primary;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? const Color(0xFF096DD9) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: primary
                ? null
                : Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
          ),
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primary ? Colors.white : const Color(0xFF262626),
                    ),
                  ),
                )
              : Text(
                  label,
                  style: TestStyle.regular(fontSize: 12, color: primary ? Colors.white : const Color(0xFF262626), letterSpacing: 0.2),
                ),
        ),
      ),
    );
  }
}

class _CandidateCardData {
  const _CandidateCardData({
    required this.resumeId,
    required this.userId,
    required this.avatarUrl,
    required this.name,
    required this.ageGender,
    required this.intention,
    required this.scoreText,
    required this.scoreLabel,
    required this.tags,
    required this.updatedText,
  });

  final int resumeId;
  final int userId;
  final String avatarUrl;
  final String name;
  final String ageGender;
  final String intention;
  final String scoreText;
  final String scoreLabel;
  final List<String> tags;
  final String updatedText;

  factory _CandidateCardData.fromTalent(
    TalentVO talent, {
    required String sort,
  }) {
    final bool isMatchSort = sort == 'match';
    final bool isActiveSort = sort == 'active';
    return _CandidateCardData(
      resumeId: talent.resumeId,
      userId: talent.userId,
      avatarUrl: talent.avatarUrl,
      name: talent.nickname.isEmpty ? '招聘.未命名用户'.tr() : talent.nickname,
      ageGender: _buildAgeGender(talent),
      intention: _buildIntention(talent),
      scoreText: isMatchSort && talent.matchScore != null
          ? '${talent.matchScore!.clamp(0, 100)}%'
          : '${talent.completeness}%',
      scoreLabel: isMatchSort && talent.matchScore != null
          ? '招聘.匹配度'.tr()
          : '招聘.完整度'.tr(),
      tags: _buildTags(talent),
      updatedText: isActiveSort
          ? _buildActiveText(talent.lastLoginAt)
          : _buildUpdatedText(talent.updatedAt),
    );
  }

  static String _buildAgeGender(TalentVO talent) {
    final List<String> parts = <String>[];
    if (talent.age != null) {
      parts.add(
        '招聘.岁'.tr(namedArgs: <String, String>{'count': talent.age.toString()}),
      );
    }
    final String genderText = switch (talent.gender.trim().toLowerCase()) {
      'male' => '招聘.男'.tr(),
      'female' => '招聘.女'.tr(),
      _ => '',
    };
    if (genderText.isNotEmpty) {
      parts.add(genderText);
    }
    return parts.isEmpty ? '招聘.信息待完善'.tr() : parts.join('·');
  }

  static String _buildIntention(TalentVO talent) {
    final String countries = talent.targetCountries.join(' / ');
    final String positions = talent.targetPositions.join(' / ');
    if (countries.isEmpty && positions.isEmpty) {
      return '招聘.意向待完善'.tr();
    }
    if (countries.isEmpty) {
      return '招聘.意向内容'.tr(namedArgs: <String, String>{'content': positions});
    }
    if (positions.isEmpty) {
      return '招聘.意向内容'.tr(namedArgs: <String, String>{'content': countries});
    }
    return '招聘.意向内容'.tr(
      namedArgs: <String, String>{'content': '$countries / $positions'},
    );
  }

  static List<String> _buildTags(TalentVO talent) {
    final List<String> tags = <String>[];
    if (talent.yearsOfExperience > 0) {
      tags.add(
        '招聘.年经验'.tr(
          namedArgs: <String, String>{
            'count': talent.yearsOfExperience.toString(),
          },
        ),
      );
    }
    if (talent.targetPositions.isNotEmpty) {
      tags.add(talent.targetPositions.first);
    }
    if (talent.targetCountries.isNotEmpty) {
      tags.add(talent.targetCountries.first);
    }
    if (tags.isEmpty && talent.selfEvaluation.trim().isNotEmpty) {
      tags.add('招聘.有自我评价'.tr());
    }
    return tags;
  }

  static String _buildUpdatedText(String updatedAt) {
    final DateTime? parsed = DateTime.tryParse(updatedAt)?.toLocal();
    if (parsed == null) {
      return updatedAt.isEmpty ? '招聘.更新时间未知'.tr() : updatedAt;
    }
    final Duration difference = DateTime.now().difference(parsed);
    if (difference.inMinutes < 1) {
      return '招聘.刚刚更新'.tr();
    }
    if (difference.inMinutes < 60) {
      return '招聘.分钟前更新'.tr(
        namedArgs: <String, String>{'count': difference.inMinutes.toString()},
      );
    }
    if (difference.inHours < 24) {
      return '招聘.小时前更新'.tr(
        namedArgs: <String, String>{'count': difference.inHours.toString()},
      );
    }
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '招聘.月日更新'.tr(
      namedArgs: <String, String>{'month': month, 'day': day},
    );
  }

  static String _buildActiveText(String lastLoginAt) {
    final DateTime? parsed = DateTime.tryParse(lastLoginAt)?.toLocal();
    if (parsed == null) {
      return lastLoginAt.isEmpty ? '招聘.活跃时间未知'.tr() : lastLoginAt;
    }
    final Duration difference = DateTime.now().difference(parsed);
    if (difference.inMinutes < 1) {
      return '招聘.刚刚活跃'.tr();
    }
    if (difference.inMinutes < 60) {
      return '招聘.分钟前活跃'.tr(
        namedArgs: <String, String>{'count': difference.inMinutes.toString()},
      );
    }
    if (difference.inHours < 24) {
      return '招聘.小时前活跃'.tr(
        namedArgs: <String, String>{'count': difference.inHours.toString()},
      );
    }
    if (difference.inDays < 30) {
      return '招聘.天前活跃'.tr(
        namedArgs: <String, String>{'count': difference.inDays.toString()},
      );
    }
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '招聘.月日活跃'.tr(
      namedArgs: <String, String>{'month': month, 'day': day},
    );
  }
}

class _CandidateAvatar extends StatelessWidget {
  const _CandidateAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppUserAvatar(
      imageUrl: avatarUrl,
      size: 40,
      placeholderAssetPath: 'assets/images/mou52cw6-js17mxu.png',
    );
  }
}

class _TalentsEmptyState extends StatelessWidget {
  const _TalentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: AppEmptyState(
          message: '招聘.暂无人才数据'.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}

class _TalentLoadError extends StatelessWidget {
  const _TalentLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '招聘.人才列表加载失败'.tr(),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}
