import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
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

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 120) {
      return;
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
      _showMessage('黑名单已更新，个人信息稍后同步');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BlacklistState>(blacklistControllerProvider, (
      BlacklistState? previous,
      BlacklistState next,
    ) {
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
