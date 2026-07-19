import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../shared/network/api_error_feedback.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../features/home/data/home_providers.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/models/talent_models.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../message/application/chat/chat_page_args.dart';
import '../../../messages/data/message_models.dart';
import '../../../messages/data/message_providers.dart';
import '../../data/application_models.dart';
import '../../data/application_providers.dart';
import '../../data/job_models.dart';
import '../../data/talent_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

import '../widgets/invite_job_picker_sheet.dart';

enum TalentCenterMode {
  employer,
  serviceProvider,
}

/// 企业招聘页：按 Figma「人才中心」实现。
class CompanyJobsPage extends ConsumerStatefulWidget {
  const CompanyJobsPage({
    super.key,
    this.mode = TalentCenterMode.employer,
  });

  final TalentCenterMode mode;

  @override
  ConsumerState<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

/// 人才搜索页参数，当前仅区分企业端与服务商端主按钮行为。
class TalentSearchPageArgs {
  const TalentSearchPageArgs({
    this.mode = TalentCenterMode.employer,
  });

  final TalentCenterMode mode;
}

class _CompanyJobsPageState extends ConsumerState<CompanyJobsPage> {
  int _selectedTabIndex = 0;
  final Set<int> _processingPrimaryActionUserIds = <int>{};

  String _sortForTab(int index) => switch (index) {
    1 => 'active',
    2 => 'match',
    _ => 'latest',
  };

  String get _selectedSort => _sortForTab(_selectedTabIndex);

  TalentListQuery _buildQueryForTab(int index) => TalentListQuery(
    position: index == 3 ? tr('招聘.中餐厨师') : null,
    sort: _sortForTab(index),
    page: 1,
    pageSize: 20,
  );

  TalentListQuery get _query => _buildQueryForTab(_selectedTabIndex);

  bool get _isServiceProviderMode =>
      widget.mode == TalentCenterMode.serviceProvider;

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

  /// 点击顶部搜索框后进入独立搜索页，复用当前角色模式对应的结果动作。
  Future<void> _openTalentSearchPage() async {
    await context.push(
      RoutePaths.talentSearch,
      extra: TalentSearchPageArgs(mode: widget.mode),
    );
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
    if (_processingPrimaryActionUserIds.contains(data.userId)) {
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
      _processingPrimaryActionUserIds.add(data.userId);
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
      ref.invalidate(homeDashboardStatsProvider);
      _showMessage('招聘.邀约面试'.tr());
    } catch (error) {
      _showMessage(
        ApiErrorFeedback.resolveMessage(error, fallback: '招聘.邀约面试失败'.tr()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPrimaryActionUserIds.remove(data.userId);
        });
      }
    }
  }

  /// 人才中心点击“打招呼”后，直接创建会话并跳转聊天页。
  Future<void> _handleSayHello(_CandidateCardData data) async {
    if (_processingPrimaryActionUserIds.contains(data.userId)) {
      return;
    }
    if (data.userId <= 0) {
      _showMessage('招聘.用户信息缺失'.tr(), isError: true);
      return;
    }

    setState(() {
      _processingPrimaryActionUserIds.add(data.userId);
    });

    try {
      final Map<String, dynamic> response = await ref
          .read(messageServiceProvider)
          .createConversation(
            request: CreateConversationBO(
              targetUserId: data.userId,
              targetUserRole: 'job_seeker',
            ),
          );
      if (!mounted) {
        return;
      }
      final int conversationId = _readConversationId(response);
      await context.push(
        RoutePaths.chat,
        extra: ChatPageArgs(
          targetUserId: data.userId,
          targetUserRole: 'job_seeker',
          nickname: data.name,
          avatarUrl: data.avatarUrl,
          conversationId: conversationId,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        ApiErrorFeedback.resolveMessage(error, fallback: '招聘.发起聊天失败'.tr()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPrimaryActionUserIds.remove(data.userId);
        });
      }
    }
  }

  /// 卡片主按钮统一走“打招呼”动作，直接进入聊天会话。
  Future<void> _handlePrimaryAction(_CandidateCardData data) async {
    await _handleSayHello(data);
  }

  /// 兼容不同接口响应格式，提取聊天会话 ID。
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

  /// 构建顶部固定区域，保证标题、搜索框和标签栏不跟随列表滚动。
  Widget _buildFixedHeader(double topPadding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Header(topPadding: topPadding),
        _SearchBar(onTap: _openTalentSearchPage),
        _TabBarSection(
          selectedIndex: _selectedTabIndex,
          onTap: _handleTalentTabChanged,
        ),
      ],
    );
  }

  /// 构建下方可滚动内容区域，仅让 Banner 和人才列表参与滚动。
  Widget _buildScrollableContent({
    required AsyncValue<PageResult<TalentVO>> talentsAsync,
    required double bottomPadding,
  }) {
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      children: <Widget>[
        const _AiBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 12, 14, 0),
          child: talentsAsync.when(
            data: (pageResult) {
              if (pageResult.list.isEmpty) {
                return const _TalentsEmptyState();
              }
              return _TalentListView(
                pageResult: pageResult,
                selectedSort: _selectedSort,
                isServiceProviderMode: _isServiceProviderMode,
                processingPrimaryActionUserIds:
                    _processingPrimaryActionUserIds,
                onViewResumeTap: _openResumePreview,
                onPrimaryActionTap: _handlePrimaryAction,
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

  /// 构建页面主体，将顶部筛选区域固定在上方，下方结果列表独立滚动。
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<PageResult<TalentVO>> talentsAsync = ref.watch(
      talentListProvider(_query),
    );

    return Column(
      children: <Widget>[
        _buildFixedHeader(topPadding),
        Expanded(
          // 仅让下方内容区滚动，保证顶部三个区域始终固定可见。
          child: _buildScrollableContent(
            talentsAsync: talentsAsync,
            bottomPadding: bottomPadding,
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
              style: TestStyle.pingFangSemibold(
                fontSize: 17,
                color: Color(0xE6000000),
              ),
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.only(top: 2),
          //   child: Text(
          //     '招聘.筛选'.tr(),
          //     style: TestStyle.pingFangRegular(fontSize: 15, color: Color(0xFF262626)),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                  child: Text(
                    '招聘.搜索岗位技能经验'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.pingFangRegular(
                      fontSize: 14,
                      color: Color(0xFFBFBFBF),
                    ),
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

/// 人才独立搜索页：点击搜索框进入后输入关键词并展示人才结果列表。
class TalentSearchPage extends ConsumerStatefulWidget {
  const TalentSearchPage({
    super.key,
    this.args = const TalentSearchPageArgs(),
  });

  final TalentSearchPageArgs args;

  @override
  ConsumerState<TalentSearchPage> createState() => _TalentSearchPageState();
}

class _TalentSearchPageState extends ConsumerState<TalentSearchPage> {
  static const String _searchAsset = 'assets/images/mou52cw6-pzdc72z.svg';

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(_handleInputChanged);
  late final FocusNode _focusNode = FocusNode();
  final Set<int> _processingPrimaryActionUserIds = <int>{};

  bool get _isServiceProviderMode =>
      widget.args.mode == TalentCenterMode.serviceProvider;

  String? _submittedKeyword;

  bool get _hasSubmittedKeyword => (_submittedKeyword ?? '').trim().isNotEmpty;

  TalentListQuery get _query => TalentListQuery(
    keyword: _submittedKeyword,
    sort: 'latest',
    page: 1,
    pageSize: 20,
  );

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 输入被清空后立即回到初始空态，避免继续展示旧搜索结果。
  void _handleInputChanged() {
    if (_searchController.text.trim().isNotEmpty || !_hasSubmittedKeyword) {
      return;
    }
    setState(() {
      _submittedKeyword = null;
    });
  }

  /// 统一提交关键字搜索，只在用户明确点击搜索或键盘搜索时刷新结果。
  void _handleSubmit([String? value]) {
    final String normalized = (value ?? _searchController.text).trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _submittedKeyword = normalized.isEmpty ? null : normalized;
    });
  }

  /// 搜索页返回时优先回上一页，兜底回到招聘页。
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.jobs);
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

  /// 搜索结果点击主按钮时，直接创建会话并跳转聊天页。
  Future<void> _handleSayHello(_CandidateCardData data) async {
    if (_processingPrimaryActionUserIds.contains(data.userId)) {
      return;
    }
    if (data.userId <= 0) {
      _showMessage('招聘.用户信息缺失'.tr(), isError: true);
      return;
    }
    setState(() {
      _processingPrimaryActionUserIds.add(data.userId);
    });
    try {
      final Map<String, dynamic> response = await ref
          .read(messageServiceProvider)
          .createConversation(
            request: CreateConversationBO(
              targetUserId: data.userId,
              targetUserRole: 'job_seeker',
            ),
          );
      if (!mounted) {
        return;
      }
      final int conversationId = _readConversationId(response);
      await context.push(
        RoutePaths.chat,
        extra: ChatPageArgs(
          targetUserId: data.userId,
          targetUserRole: 'job_seeker',
          nickname: data.name,
          avatarUrl: data.avatarUrl,
          conversationId: conversationId,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        ApiErrorFeedback.resolveMessage(error, fallback: '招聘.发起聊天失败'.tr()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPrimaryActionUserIds.remove(data.userId);
        });
      }
    }
  }

  /// 搜索结果卡片主按钮统一走“打招呼”动作。
  Future<void> _handlePrimaryAction(_CandidateCardData data) async {
    await _handleSayHello(data);
  }

  /// 兼容不同接口响应格式，提取聊天会话 ID。
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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PageResult<TalentVO>>? talentsAsync = _hasSubmittedKeyword
        ? ref.watch(talentListProvider(_query))
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: _TalentSearchAppBarField(
          controller: _searchController,
          focusNode: _focusNode,
          searchAssetPath: _searchAsset,
          onSubmitted: _handleSubmit,
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _handleSubmit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF096DD9),
                minimumSize: const Size(52, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '通用.搜索'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 15,
                  color: Color(0xFF096DD9),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _hasSubmittedKeyword
            ? _TalentSearchResultBody(
                talentsAsync: talentsAsync!,
                isServiceProviderMode: _isServiceProviderMode,
                processingPrimaryActionUserIds:
                    _processingPrimaryActionUserIds,
                onViewResumeTap: _openResumePreview,
                onPrimaryActionTap: _handlePrimaryAction,
                onRetry: _handleSubmit,
              )
            : Center(
                child: AppEmptyState(
                  message: '招聘.请输入关键词开始搜索'.tr(),
                ),
              ),
      ),
    );
  }
}

class _TalentSearchAppBarField extends StatelessWidget {
  const _TalentSearchAppBarField({
    required this.controller,
    required this.focusNode,
    required this.searchAssetPath,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchAssetPath;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          SvgPicture.asset(
            searchAssetPath,
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: const Color(0xFF096DD9),
              style: TestStyle.pingFangRegular(
                fontSize: 14,
                color: Color(0xFF262626),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '招聘.搜索岗位技能经验'.tr(),
                hintStyle: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFFBFBFBF),
                ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 9),
        ],
      ),
    );
  }
}

class _TalentSearchResultBody extends StatelessWidget {
  const _TalentSearchResultBody({
    required this.talentsAsync,
    required this.isServiceProviderMode,
    required this.processingPrimaryActionUserIds,
    required this.onViewResumeTap,
    required this.onPrimaryActionTap,
    required this.onRetry,
  });

  final AsyncValue<PageResult<TalentVO>> talentsAsync;
  final bool isServiceProviderMode;
  final Set<int> processingPrimaryActionUserIds;
  final ValueChanged<int> onViewResumeTap;
  final Future<void> Function(_CandidateCardData data) onPrimaryActionTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: talentsAsync.when(
        data: (pageResult) {
          if (pageResult.list.isEmpty) {
            return const _TalentsEmptyState();
          }
          return _TalentListView(
            pageResult: pageResult,
            selectedSort: 'latest',
            isServiceProviderMode: isServiceProviderMode,
            processingPrimaryActionUserIds: processingPrimaryActionUserIds,
            onViewResumeTap: onViewResumeTap,
            onPrimaryActionTap: onPrimaryActionTap,
            padding: const EdgeInsets.fromLTRB(11, 12, 14, 24),
            shrinkWrap: false,
            physics: const AlwaysScrollableScrollPhysics(),
          );
        },
        loading: () => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => _TalentLoadError(onRetry: onRetry),
      ),
    );
  }
}

class _TalentListView extends StatelessWidget {
  const _TalentListView({
    required this.pageResult,
    required this.selectedSort,
    required this.isServiceProviderMode,
    required this.processingPrimaryActionUserIds,
    required this.onViewResumeTap,
    required this.onPrimaryActionTap,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  final PageResult<TalentVO> pageResult;
  final String selectedSort;
  final bool isServiceProviderMode;
  final Set<int> processingPrimaryActionUserIds;
  final ValueChanged<int> onViewResumeTap;
  final Future<void> Function(_CandidateCardData data) onPrimaryActionTap;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: pageResult.list.length,
      padding: padding,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final TalentVO talent = pageResult.list[index];
        final _CandidateCardData cardData = _CandidateCardData.fromTalent(
          talent,
          sort: selectedSort,
        );
        return _CandidateCard(
          data: cardData,
          onViewResumeTap: () => onViewResumeTap(talent.userId),
          primaryActionLabel: '通用.打招呼'.tr(),
          onPrimaryActionTap: () => onPrimaryActionTap(cardData),
          isPrimaryActionLoading: processingPrimaryActionUserIds.contains(
            talent.userId,
          ),
        );
      },
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
    required this.primaryActionLabel,
    required this.onPrimaryActionTap,
    required this.isPrimaryActionLoading,
  });

  final _CandidateCardData data;
  final VoidCallback onViewResumeTap;
  final String primaryActionLabel;
  final VoidCallback onPrimaryActionTap;
  final bool isPrimaryActionLoading;

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
                  label: primaryActionLabel,
                  primary: true,
                  onTap: isPrimaryActionLoading ? null : onPrimaryActionTap,
                  isLoading: isPrimaryActionLoading,
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
    final bool isActiveSort = sort == 'active';
    return _CandidateCardData(
      resumeId: talent.resumeId,
      userId: talent.userId,
      avatarUrl: talent.avatarUrl,
      name: talent.nickname.isEmpty ? '招聘.未命名用户'.tr() : talent.nickname,
      ageGender: _buildAgeGender(talent),
      intention: _buildIntention(talent),
      scoreText: '${(talent.matchScore ?? 0).clamp(0, 100)}%',
      scoreLabel: '招聘.匹配度'.tr(),
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
