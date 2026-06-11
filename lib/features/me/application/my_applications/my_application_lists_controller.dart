import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_exception.dart';
import '../../../jobs/data/application_providers.dart';
import '../../data/my_applications_models.dart';
import 'my_application_list_state.dart';

final myApplicationListsControllerProvider = NotifierProvider<
  MyApplicationListsController,
  Map<MyApplicationTabType, MyApplicationListState>
>(MyApplicationListsController.new);

class MyApplicationListsController
    extends Notifier<Map<MyApplicationTabType, MyApplicationListState>> {
  static const int _pageSize = 20;

  @override
  Map<MyApplicationTabType, MyApplicationListState> build() {
    return const <MyApplicationTabType, MyApplicationListState>{};
  }

  MyApplicationListState getState(MyApplicationTabType tab) {
    return state[tab] ?? const MyApplicationListState();
  }

  Future<bool> loadInitial({
    required MyApplicationTabType tab,
    bool force = false,
  }) async {
    final MyApplicationListState current = getState(tab);
    if (current.isInitialLoading) {
      return false;
    }
    if (current.hasLoadedOnce && !force) {
      return true;
    }

    _setState(
      tab,
      current.copyWith(isInitialLoading: true, errorMessage: null),
    );

    try {
      final _MyApplicationPagePayload payload = await _fetchPage(
        tab: tab,
        page: 1,
      );
      _setState(tab, payload.state);
      return true;
    } catch (error) {
      _setState(
        tab,
        current.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasLoadedOnce: true,
          hasMore: false,
          errorMessage: _normalizeError(error),
        ),
      );
      return false;
    }
  }

  Future<bool> refresh({required MyApplicationTabType tab}) async {
    final MyApplicationListState current = getState(tab);
    if (current.isRefreshing || current.isInitialLoading) {
      return false;
    }

    _setState(tab, current.copyWith(isRefreshing: true, errorMessage: null));

    try {
      final _MyApplicationPagePayload payload = await _fetchPage(
        tab: tab,
        page: 1,
      );
      _setState(
        tab,
        payload.state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
        ),
      );
      return true;
    } catch (error) {
      _setState(
        tab,
        getState(
          tab,
        ).copyWith(isRefreshing: false, errorMessage: _normalizeError(error)),
      );
      return false;
    }
  }

  Future<bool> loadMore({required MyApplicationTabType tab}) async {
    final MyApplicationListState current = getState(tab);
    if (current.isInitialLoading ||
        current.isRefreshing ||
        current.isLoadingMore ||
        !current.hasMore) {
      return false;
    }

    _setState(tab, current.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final _MyApplicationPagePayload payload = await _fetchPage(
        tab: tab,
        page: current.nextPage,
      );
      _setState(
        tab,
        current.copyWith(
          items: <MyApplicationItem>[...current.items, ...payload.state.items],
          isLoadingMore: false,
          hasLoadedOnce: true,
          nextPage: payload.state.nextPage,
          hasMore: payload.state.hasMore,
          errorMessage: null,
        ),
      );
      return true;
    } catch (error) {
      _setState(
        tab,
        getState(
          tab,
        ).copyWith(isLoadingMore: false, errorMessage: _normalizeError(error)),
      );
      return false;
    }
  }

  Future<_MyApplicationPagePayload> _fetchPage({
    required MyApplicationTabType tab,
    required int page,
  }) async {
    final response = await ref
        .read(applicationServiceProvider)
        .listMyApplications(
          page: page,
          pageSize: _pageSize,
          status: tab.apiStatus,
        );
    return _MyApplicationPagePayload(
      MyApplicationListState(
        items: response.list
            .map(MyApplicationItem.fromApplication)
            .toList(growable: false),
        hasLoadedOnce: true,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        nextPage: response.pagination.page + 1,
        hasMore: response.pagination.hasNext,
        errorMessage: null,
      ),
    );
  }

  void _setState(MyApplicationTabType tab, MyApplicationListState nextState) {
    state = <MyApplicationTabType, MyApplicationListState>{
      ...state,
      tab: nextState,
    };
  }

  String _normalizeError(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '我的应聘加载失败，请稍后重试' : message;
  }
}

class _MyApplicationPagePayload {
  const _MyApplicationPagePayload(this.state);

  final MyApplicationListState state;
}
