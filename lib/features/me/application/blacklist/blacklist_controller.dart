import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/page_result.dart';
import '../../data/user_models.dart';
import '../../data/user_providers.dart';
import 'blacklist_state.dart';

final blacklistControllerProvider =
    NotifierProvider.autoDispose<BlacklistController, BlacklistState>(
      BlacklistController.new,
    );

class BlacklistController extends Notifier<BlacklistState> {
  static const int _pageSize = 20;

  @override
  BlacklistState build() => const BlacklistState();

  Future<void> loadInitial() async {
    if (state.isLoading || state.items.isNotEmpty) {
      return;
    }
    await _fetchPage(page: 1, mode: _FetchMode.initial);
  }

  Future<void> refresh() async {
    if (state.isRefreshing || state.isLoading) {
      return;
    }
    await _fetchPage(page: 1, mode: _FetchMode.refresh);
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasNext) {
      return;
    }
    await _fetchPage(page: state.currentPage + 1, mode: _FetchMode.loadMore);
  }

  Future<void> removeUser(UserVO user) async {
    if (state.removingUserIds.contains(user.userId)) {
      return;
    }

    final Set<int> removingUserIds = Set<int>.from(state.removingUserIds)
      ..add(user.userId);
    state = state.copyWith(removingUserIds: removingUserIds);

    try {
      await ref
          .read(userServiceProvider)
          .manageBlacklist(
            request: BlacklistBO(targetUserId: user.userId, action: 'remove'),
          );

      final List<UserVO> nextItems = state.items
          .where((UserVO item) => item.userId != user.userId)
          .toList(growable: false);
      final Set<int> nextRemovingIds = Set<int>.from(state.removingUserIds)
        ..remove(user.userId);
      state = state.copyWith(
        items: nextItems,
        totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
        removingUserIds: nextRemovingIds,
        removedUserVersion: state.removedUserVersion + 1,
      );
    } catch (error) {
      final Set<int> nextRemovingIds = Set<int>.from(state.removingUserIds)
        ..remove(user.userId);
      state = state.copyWith(
        removingUserIds: nextRemovingIds,
        feedbackMessage: _resolveRemoveErrorMessage(error),
        feedbackId: state.feedbackId + 1,
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  Future<void> _fetchPage({required int page, required _FetchMode mode}) async {
    if (mode == _FetchMode.initial) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else if (mode == _FetchMode.refresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final PageResult<UserVO> result = await ref
          .read(userServiceProvider)
          .getBlacklist(page: page, pageSize: _pageSize);

      final List<UserVO> nextItems = switch (mode) {
        _FetchMode.loadMore => <UserVO>[...state.items, ...result.list],
        _ => result.list,
      };

      state = state.copyWith(
        items: nextItems,
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: null,
        currentPage: result.pagination.page,
        totalCount: result.pagination.total,
        hasNext: result.pagination.hasNext,
      );
    } catch (error) {
      final String message = _resolveLoadErrorMessage(error);
      if (mode == _FetchMode.initial) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: message,
          items: const <UserVO>[],
          currentPage: 0,
          totalCount: 0,
          hasNext: false,
        );
      } else if (mode == _FetchMode.refresh) {
        state = state.copyWith(isRefreshing: false, errorMessage: message);
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          feedbackMessage: message,
          feedbackId: state.feedbackId + 1,
        );
      }
    }
  }

  String _resolveLoadErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '我的.黑名单加载失败'.tr();
  }

  String _resolveRemoveErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '我的.移除失败'.tr();
  }
}

enum _FetchMode { initial, refresh, loadMore }
