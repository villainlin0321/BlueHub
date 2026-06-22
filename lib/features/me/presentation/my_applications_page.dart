import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../message/application/chat/chat_page_args.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../application/my_applications/my_application_list_state.dart';
import '../application/my_applications/my_application_lists_controller.dart';
import '../data/my_applications_models.dart';
import 'widgets/my_application_card.dart';

class MyApplicationsPage extends ConsumerStatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  ConsumerState<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends ConsumerState<MyApplicationsPage>
    with SingleTickerProviderStateMixin {
  static const List<MyApplicationTabType> _tabs = MyApplicationTabType.values;
  static const MyApplicationTabType _defaultTab = MyApplicationTabType.all;

  late final TabController _tabController;
  int _handledTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadInitialAllTab());
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    if (_handledTabIndex == _tabController.index) {
      return;
    }
    _handledTabIndex = _tabController.index;
    unawaited(_reloadTabOnSwitch(_tabs[_tabController.index]));
  }

  Future<void> _loadInitialAllTab() async {
    await ref
        .read(myApplicationListsControllerProvider.notifier)
        .loadInitial(tab: _defaultTab, force: true);
  }

  Future<void> _reloadTabOnSwitch(MyApplicationTabType tab) async {
    final MyApplicationListState currentState = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[tab] ?? const MyApplicationListState(),
      ),
    );
    final MyApplicationListsController controller = ref.read(
      myApplicationListsControllerProvider.notifier,
    );

    if (currentState.hasLoadedOnce) {
      await controller.refresh(tab: tab);
      return;
    }

    await controller.loadInitial(tab: tab, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(RoutePaths.me);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          '我的.我的应聘'.tr(),
          style: TextStyle(
            color: Color(0xE6262626),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0x297E868E), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs
                  .map((tab) => Tab(height: 44, text: tab.localizedLabel))
                  .toList(growable: false),
              labelColor: const Color(0xFF096DD9),
              unselectedLabelColor: const Color(0xFF262626),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 22 / 14,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              indicatorColor: const Color(0xFF096DD9),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map(
                    (MyApplicationTabType tab) => _MyApplicationTabView(
                      key: PageStorageKey<String>(
                        'my-applications-${tab.name}',
                      ),
                      tab: tab,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyApplicationTabView extends ConsumerStatefulWidget {
  const _MyApplicationTabView({super.key, required this.tab});

  final MyApplicationTabType tab;

  @override
  ConsumerState<_MyApplicationTabView> createState() =>
      _MyApplicationTabViewState();
}

class _MyApplicationTabViewState extends ConsumerState<_MyApplicationTabView>
    with AutomaticKeepAliveClientMixin<_MyApplicationTabView> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final bool success = await ref
        .read(myApplicationListsControllerProvider.notifier)
        .refresh(tab: widget.tab);
    if (!mounted) {
      return;
    }

    if (success) {
      _refreshController.finishRefresh();
      _refreshController.resetFooter();
      return;
    }

    final String? message = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab]?.errorMessage,
      ),
    );
    _refreshController.finishRefresh(IndicatorResult.fail);
    if (message != null && message.trim().isNotEmpty) {
      AppToast.show(message);
    }
  }

  Future<void> _retryInitialLoad() async {
    final bool success = await ref
        .read(myApplicationListsControllerProvider.notifier)
        .loadInitial(tab: widget.tab, force: true);
    if (!mounted || success) {
      return;
    }
    final String? message = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab]?.errorMessage,
      ),
    );
    if (message != null && message.trim().isNotEmpty) {
      AppToast.show(message);
    }
  }

  Future<void> _loadMore() async {
    final MyApplicationListState current = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab] ?? const MyApplicationListState(),
      ),
    );
    if (current.isInitialLoading ||
        current.isRefreshing ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    final bool success = await ref
        .read(myApplicationListsControllerProvider.notifier)
        .loadMore(tab: widget.tab);
    if (!mounted) {
      return;
    }

    final MyApplicationListState latestState = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab] ?? const MyApplicationListState(),
      ),
    );
    if (success) {
      _refreshController.finishLoad(
        latestState.hasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
      return;
    }

    final String? message = ref.read(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab]?.errorMessage,
      ),
    );
    _refreshController.finishLoad(IndicatorResult.fail);
    if (message != null && message.trim().isNotEmpty) {
      AppToast.show(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final MyApplicationListState listState = ref.watch(
      myApplicationListsControllerProvider.select(
        (Map<MyApplicationTabType, MyApplicationListState> states) =>
            states[widget.tab] ?? const MyApplicationListState(),
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
      onLoad: listState.hasMore && listState.items.isNotEmpty
          ? _loadMore
          : null,
      child: listState.items.isEmpty
          ? _MyApplicationEmptyView(
              errorMessage: listState.errorMessage,
              onRetry: listState.errorMessage == null
                  ? null
                  : _retryInitialLoad,
            )
          : _MyApplicationListView(tab: widget.tab, listState: listState),
    );
  }
}

class _MyApplicationListView extends StatelessWidget {
  const _MyApplicationListView({required this.tab, required this.listState});

  final MyApplicationTabType tab;
  final MyApplicationListState listState;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: PageStorageKey<String>('my-applications-list-${tab.name}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: listState.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final MyApplicationItem item = listState.items[index];
        return MyApplicationCard(
          key: ValueKey<int>(item.applicationId),
          item: item,
          onActionTap: () {
            final int? profileId = item.profileId;
            if (profileId == null || profileId <= 0) {
              AppToast.show('招聘.雇主信息缺失'.tr());
              return;
            }
            context.push(
              RoutePaths.chat,
              extra: ChatPageArgs(
                targetUserId: profileId,
                targetUserRole: 'employer',
                nickname: item.companyName.trim().isEmpty
                    ? item.title
                    : item.companyName,
                avatarUrl: '',
              ),
            );
          },
        );
      },
    );
  }
}

class _MyApplicationEmptyView extends StatelessWidget {
  const _MyApplicationEmptyView({this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String message = errorMessage?.trim().isNotEmpty == true
        ? errorMessage!.trim()
        : '我的应聘.暂无应聘记录'.tr();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        24,
        96,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: <Widget>[
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppEmptyState(
                message: message,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
