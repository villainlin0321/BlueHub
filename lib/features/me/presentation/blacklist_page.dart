import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/logging/app_log_facade.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../auth/application/auth_session_provider.dart';
import '../application/blacklist/blacklist_controller.dart';
import '../application/blacklist/blacklist_state.dart';
import 'widgets/blacklist_page_view.dart';

class BlacklistPage extends ConsumerStatefulWidget {
  const BlacklistPage({super.key});

  @override
  ConsumerState<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends ConsumerState<BlacklistPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasLoggedScrollReachEnd = false;

  @override
  void initState() {
    super.initState();
    _logPageEnter();
    _scrollController.addListener(_handleScroll);
    Future<void>.microtask(
      () => ref.read(blacklistControllerProvider.notifier).loadInitial(),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  /// 构建黑名单页的统一日志上下文，保证进入页和滚动日志字段一致。
  Map<String, Object?> _buildPageLogContext({
    BlacklistState? state,
    Map<String, Object?> extra = const <String, Object?>{},
  }) {
    final BlacklistState currentState = state ?? ref.read(blacklistControllerProvider);
    return <String, Object?>{
      'route': RoutePaths.blacklist,
      'module': 'me',
      'feature': 'blacklist',
      'currentPage': currentState.currentPage,
      'itemCount': currentState.items.length,
      'hasNext': currentState.hasNext,
      if (currentState.totalCount > 0) 'totalCount': currentState.totalCount,
      ...extra,
    };
  }

  /// 记录黑名单页进入事件，便于排查列表加载前后的链路顺序。
  void _logPageEnter() {
    StateLog.step(
      event: 'BLACKLIST_PAGE_ENTER',
      message: '进入黑名单页面',
      context: _buildPageLogContext(),
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final BlacklistState state = ref.read(blacklistControllerProvider);
    final double triggerOffset = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels < triggerOffset) {
      // 只要用户回滚到阈值之外，就允许下一次真正触底时再次记一条日志。
      _hasLoggedScrollReachEnd = false;
      return;
    }
    if (state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasNext) {
      return;
    }
    if (!_hasLoggedScrollReachEnd) {
      _hasLoggedScrollReachEnd = true;
      ActionLog.scrollReachEnd(
        event: 'BLACKLIST_SCROLL_REACH_END',
        message: '黑名单列表滚动到底部',
        context: _buildPageLogContext(
          state: state,
          extra: <String, Object?>{
            'scrollPixels': _scrollController.position.pixels.round(),
            'scrollMaxExtent': _scrollController.position.maxScrollExtent.round(),
          },
        ),
      );
    }
    ref.read(blacklistControllerProvider.notifier).loadMore();
  }

  Future<void> _refreshCurrentUser() async {
    final authSession = ref.read(authSessionProvider);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUser(
            fallbackUser: authSession.user,
            preferredNeedSelectRole: authSession.needSelectRole,
          );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('我的.黑名单同步提示'.tr());
    }
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BlacklistState>(blacklistControllerProvider, (
      BlacklistState? previous,
      BlacklistState next,
    ) {
      if (previous?.currentPage != next.currentPage ||
          previous?.isLoadingMore != next.isLoadingMore) {
        _hasLoggedScrollReachEnd = false;
      }
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        _showMessage(next.feedbackMessage!);
        ref.read(blacklistControllerProvider.notifier).clearFeedback();
      }

      if (previous?.removedUserVersion != next.removedUserVersion &&
          next.removedUserVersion > 0) {
        _refreshCurrentUser();
      }
    });

    final BlacklistState state = ref.watch(blacklistControllerProvider);
    final BlacklistController controller = ref.read(
      blacklistControllerProvider.notifier,
    );

    return BlacklistPageView(
      state: state,
      scrollController: _scrollController,
      onBack: context.pop,
      onRefresh: controller.refresh,
      onRetry: controller.loadInitial,
      onRemoveTap: controller.removeUser,
    );
  }
}
