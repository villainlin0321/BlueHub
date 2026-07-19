import 'package:easy_localization/easy_localization.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/job_position_card.dart';
import '../../../shared/widgets/visa_service_card.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../jobs/presentation/job_apply_helper.dart';
import '../../jobs/presentation/job_detail_page.dart';
import '../../service_detail/presentation/service_detail_page.dart';
import '../data/collection_models.dart' as collection_models;
import '../data/collection_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

class MyFavoritesPage extends ConsumerStatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  ConsumerState<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends ConsumerState<MyFavoritesPage>
    with SingleTickerProviderStateMixin {
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const int _pageSize = 50;
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_handleTabChanged);
  final EasyRefreshController _serviceRefreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  final EasyRefreshController _jobRefreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  List<collection_models.VisaPackageVO> _serviceItems =
      <collection_models.VisaPackageVO>[];
  List<collection_models.JobListVO> _jobItems = <collection_models.JobListVO>[];

  bool _isManaging = false;
  FavoriteTabType _currentTab = FavoriteTabType.services;
  bool _isServiceLoading = false;
  bool _isJobLoading = false;
  int _serviceNextPage = 1;
  int _jobNextPage = 1;
  bool _serviceHasMore = true;
  bool _jobHasMore = true;
  String? _serviceErrorMessage;
  String? _jobErrorMessage;
  final Set<String> _selectedServiceIds = <String>{};
  final Set<String> _selectedJobIds = <String>{};
  final Set<String> _submittingJobIds = <String>{};
  final Set<String> _appliedJobIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollectedPackages();
      _loadCollectedJobs();
    });
  }

  @override
  void dispose() {
    _serviceRefreshController.dispose();
    _jobRefreshController.dispose();
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final nextTab = _tabController.index == 0
        ? FavoriteTabType.services
        : FavoriteTabType.jobs;
    if (nextTab == _currentTab) {
      return;
    }
    setState(() => _currentTab = nextTab);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.me);
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  void _enterManageMode() {
    setState(() => _isManaging = true);
  }

  void _exitManageMode() {
    setState(() {
      _isManaging = false;
      _selectedServiceIds.clear();
      _selectedJobIds.clear();
    });
  }

  void _toggleServiceSelection(String id) {
    setState(() {
      if (_selectedServiceIds.contains(id)) {
        _selectedServiceIds.remove(id);
      } else {
        _selectedServiceIds.add(id);
      }
    });
  }

  /// 加载收藏签证套餐列表，成功后用于详情跳转与取消收藏。
  Future<bool> _loadCollectedPackages({bool refresh = false}) async {
    final int page = refresh ? 1 : _serviceNextPage;
    if (_isServiceLoading || (!refresh && !_serviceHasMore)) {
      return false;
    }
    setState(() {
      _isServiceLoading = true;
      if (refresh) {
        _serviceErrorMessage = null;
      }
    });

    try {
      final response = await ref
          .read(collectionServiceProvider)
          .listCollectedPackages(page: page, pageSize: _pageSize);
      if (!mounted) {
        return false;
      }
      setState(() {
        _isServiceLoading = false;
        _serviceItems = refresh
            ? response.list
            : <collection_models.VisaPackageVO>[
                ..._serviceItems,
                ...response.list,
              ];
        _serviceNextPage = response.pagination.page + 1;
        _serviceHasMore = response.pagination.hasNext;
        _serviceErrorMessage = null;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isServiceLoading = false;
        _serviceErrorMessage = _resolveServiceErrorMessage(error);
      });
      return false;
    }
  }

  /// 加载收藏岗位列表，成功后用于详情跳转与投递。
  Future<bool> _loadCollectedJobs({bool refresh = false}) async {
    final int page = refresh ? 1 : _jobNextPage;
    if (_isJobLoading || (!refresh && !_jobHasMore)) {
      return false;
    }
    setState(() {
      _isJobLoading = true;
      if (refresh) {
        _jobErrorMessage = null;
      }
    });

    try {
      final response = await ref
          .read(collectionServiceProvider)
          .listCollectedJobs(page: page, pageSize: _pageSize);
      if (!mounted) {
        return false;
      }
      setState(() {
        _isJobLoading = false;
        _jobItems = refresh
            ? response.list
            : <collection_models.JobListVO>[..._jobItems, ...response.list];
        _jobNextPage = response.pagination.page + 1;
        _jobHasMore = response.pagination.hasNext;
        _jobErrorMessage = null;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isJobLoading = false;
        _jobErrorMessage = _resolveJobErrorMessage(error);
      });
      return false;
    }
  }

  Future<void> _onServiceRefresh() async {
    final bool success = await _loadCollectedPackages(refresh: true);
    if (!mounted) {
      return;
    }
    if (success) {
      _serviceRefreshController.finishRefresh();
      _serviceRefreshController.resetFooter();
      return;
    }
    _serviceRefreshController.finishRefresh(IndicatorResult.fail);
    if (_serviceErrorMessage != null &&
        _serviceErrorMessage!.trim().isNotEmpty) {
      _showMessage(_serviceErrorMessage!);
    }
  }

  Future<void> _onServiceLoadMore() async {
    final bool success = await _loadCollectedPackages();
    if (!mounted) {
      return;
    }
    if (success) {
      _serviceRefreshController.finishLoad(
        _serviceHasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
      return;
    }
    _serviceRefreshController.finishLoad(IndicatorResult.fail);
    if (_serviceErrorMessage != null &&
        _serviceErrorMessage!.trim().isNotEmpty) {
      _showMessage(_serviceErrorMessage!);
    }
  }

  Future<void> _onJobRefresh() async {
    final bool success = await _loadCollectedJobs(refresh: true);
    if (!mounted) {
      return;
    }
    if (success) {
      _jobRefreshController.finishRefresh();
      _jobRefreshController.resetFooter();
      return;
    }
    _jobRefreshController.finishRefresh(IndicatorResult.fail);
    if (_jobErrorMessage != null && _jobErrorMessage!.trim().isNotEmpty) {
      _showMessage(_jobErrorMessage!);
    }
  }

  Future<void> _onJobLoadMore() async {
    final bool success = await _loadCollectedJobs();
    if (!mounted) {
      return;
    }
    if (success) {
      _jobRefreshController.finishLoad(
        _jobHasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
      return;
    }
    _jobRefreshController.finishLoad(IndicatorResult.fail);
    if (_jobErrorMessage != null && _jobErrorMessage!.trim().isNotEmpty) {
      _showMessage(_jobErrorMessage!);
    }
  }

  Widget _buildScrollableState({
    required BuildContext context,
    required Widget child,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        24,
        96,
        24,
        MediaQuery.paddingOf(context).bottom + (_isManaging ? 104 : 24),
      ),
      children: <Widget>[Center(child: child)],
    );
  }

  /// 统一提取收藏岗位列表的错误文案。
  String _resolveJobErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.收藏岗位加载失败'.tr();
  }

  /// 统一提取收藏签证列表的错误文案。
  String _resolveServiceErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.收藏签证加载失败'.tr();
  }

  /// 处理收藏页岗位投递，真实岗位有 `jobId` 时直接调用接口。
  Future<void> _handleApplyJob(collection_models.JobListVO item) async {
    final String itemId = item.jobId.toString();
    if (_submittingJobIds.contains(itemId) || _appliedJobIds.contains(itemId)) {
      return;
    }

    setState(() {
      _submittingJobIds.add(itemId);
    });

    final JobApplySubmissionResult result = await submitJobApplication(
      context,
      jobId: item.jobId,
    );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _submittingJobIds.remove(itemId);
        _appliedJobIds.add(itemId);
      });
      _showMessage('首页.投递成功'.tr());
      return;
    }

    setState(() {
      _submittingJobIds.remove(itemId);
    });
    if (result.shouldShowError) {
      _showMessage(result.errorMessage!);
    }
  }

  void _toggleJobSelection(String id) {
    setState(() {
      if (_selectedJobIds.contains(id)) {
        _selectedJobIds.remove(id);
      } else {
        _selectedJobIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_currentTab == FavoriteTabType.services) {
        final ids = _serviceItems
            .map((item) => item.packageId.toString())
            .toSet();
        if (_selectedServiceIds.length == ids.length) {
          _selectedServiceIds.clear();
        } else {
          _selectedServiceIds
            ..clear()
            ..addAll(ids);
        }
        return;
      }
      final ids = _jobItems.map((item) => item.jobId.toString()).toSet();
      if (_selectedJobIds.length == ids.length) {
        _selectedJobIds.clear();
      } else {
        _selectedJobIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_currentTab == FavoriteTabType.services) {
      final List<int> targetIds = _selectedServiceIds
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false);
      await _removeCollectedPackages(targetIds);
      return;
    }

    final List<int> targetIds = _selectedJobIds
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    await _removeCollectedJobs(targetIds);
  }

  Future<void> _deleteServiceItem(int packageId) async {
    await _removeCollectedPackages(<int>[packageId]);
  }

  Future<void> _deleteJobItem(int jobId) async {
    await _removeCollectedJobs(<int>[jobId]);
  }

  /// 调用真实取消收藏接口，并同步刷新本地列表。
  Future<void> _removeCollectedJobs(List<int> jobIds) async {
    if (jobIds.isEmpty) {
      return;
    }

    try {
      for (final int jobId in jobIds) {
        await ref
            .read(collectionServiceProvider)
            .removeCollection(
              request: collection_models.CollectionBO(
                targetType: 'job',
                targetId: jobId,
              ),
            );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        final Set<int> jobIdSet = jobIds.toSet();
        _jobItems = _jobItems
            .where((item) => !jobIdSet.contains(item.jobId))
            .toList();
        _selectedJobIds.removeWhere(
          (String id) => jobIdSet.contains(int.tryParse(id)),
        );
        _submittingJobIds.removeWhere(
          (String id) => jobIdSet.contains(int.tryParse(id)),
        );
        _appliedJobIds.removeWhere(
          (String id) => jobIdSet.contains(int.tryParse(id)),
        );
      });
      ref.read(collectionRefreshTickProvider.notifier).bump();
      _showMessage(jobIds.length == 1 ? '我的.已取消收藏'.tr() : '我的.已批量取消收藏'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveJobErrorMessage(error));
    }
  }

  /// 调用真实取消收藏接口，并同步刷新收藏签证列表。
  Future<void> _removeCollectedPackages(List<int> packageIds) async {
    if (packageIds.isEmpty) {
      return;
    }

    try {
      for (final int packageId in packageIds) {
        await ref
            .read(collectionServiceProvider)
            .removeCollection(
              request: collection_models.CollectionBO(
                targetType: 'visa_package',
                targetId: packageId,
              ),
            );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        final Set<int> packageIdSet = packageIds.toSet();
        _serviceItems = _serviceItems
            .where((item) => !packageIdSet.contains(item.packageId))
            .toList();
        _selectedServiceIds.removeWhere(
          (String id) => packageIdSet.contains(int.tryParse(id)),
        );
      });
      ref.read(collectionRefreshTickProvider.notifier).bump();
      _showMessage(
        packageIds.length == 1 ? '我的.已取消收藏'.tr() : '我的.已批量取消收藏'.tr(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveServiceErrorMessage(error));
    }
  }

  bool get _isCurrentTabFullySelected {
    if (_currentTab == FavoriteTabType.services) {
      return _serviceItems.isNotEmpty &&
          _selectedServiceIds.length == _serviceItems.length;
    }
    return _jobItems.isNotEmpty && _selectedJobIds.length == _jobItems.length;
  }

  bool get _hasSelection {
    if (_currentTab == FavoriteTabType.services) {
      return _selectedServiceIds.isNotEmpty;
    }
    return _selectedJobIds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(collectionRefreshTickProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      _loadCollectedPackages(refresh: true);
      _loadCollectedJobs(refresh: true);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const AppSvgIcon(
            assetPath: _backAsset,
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          '我的.我的收藏'.tr(),
          style: TestStyle.pingFangSemibold(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isManaging ? _exitManageMode : _enterManageMode,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF262626),
                minimumSize: const Size(44, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isManaging ? '我的.退出管理'.tr() : '我的.管理'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isManaging
          ? _FavoritesManageBar(
              allSelected: _isCurrentTabFullySelected,
              hasSelection: _hasSelection,
              onSelectAllTap: _toggleSelectAll,
              onDeleteTap: _hasSelection ? _deleteSelected : null,
            )
          : null,
      body: Column(
        children: <Widget>[
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF096DD9),
              unselectedLabelColor: const Color(0xFF262626),
              labelStyle: TestStyle.medium(fontSize: 14),
              unselectedLabelStyle: TestStyle.regular(fontSize: 14),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: const Color(0xFF096DD9),
              indicatorWeight: 2,
              tabs: <Widget>[
                Tab(text: '我的.签证服务'.tr()),
                Tab(text: '我的.招聘岗位'.tr()),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[_buildServiceTab(), _buildJobTab()],
            ),
          ),
        ],
      ),
    );
  }

  /// 根据收藏岗位加载状态切换列表、空态和错误态。
  Widget _buildJobTab() {
    final Widget child;
    if (_isJobLoading && _jobItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: const CircularProgressIndicator(),
      );
    } else if (_jobErrorMessage != null && _jobItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: _FavoriteJobsErrorState(
          message: _jobErrorMessage!,
          onRetry: _onJobRefresh,
        ),
      );
    } else if (_jobItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: const _FavoriteJobsEmptyState(),
      );
    } else {
      child = _FavoriteJobList(
        items: _jobItems,
        isManaging: _isManaging,
        selectedIds: _selectedJobIds,
        onItemSelectionToggle: _toggleJobSelection,
        applyingJobIds: _submittingJobIds,
        appliedJobIds: _appliedJobIds,
        onApplyTap: _handleApplyJob,
        onDeleteItem: _deleteJobItem,
      );
    }
    return EasyRefresh(
      controller: _jobRefreshController,
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _onJobRefresh,
      onLoad: _jobHasMore && _jobItems.isNotEmpty ? _onJobLoadMore : null,
      child: child,
    );
  }

  /// 根据收藏签证加载状态切换列表、空态和错误态。
  Widget _buildServiceTab() {
    final Widget child;
    if (_isServiceLoading && _serviceItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: const CircularProgressIndicator(),
      );
    } else if (_serviceErrorMessage != null && _serviceItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: _FavoriteServicesErrorState(
          message: _serviceErrorMessage!,
          onRetry: _onServiceRefresh,
        ),
      );
    } else if (_serviceItems.isEmpty) {
      child = _buildScrollableState(
        context: context,
        child: const _FavoriteServicesEmptyState(),
      );
    } else {
      child = _FavoriteServiceList(
        items: _serviceItems,
        isManaging: _isManaging,
        selectedIds: _selectedServiceIds,
        onItemSelectionToggle: _toggleServiceSelection,
        onDeleteItem: _deleteServiceItem,
      );
    }
    return EasyRefresh(
      controller: _serviceRefreshController,
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _onServiceRefresh,
      onLoad: _serviceHasMore && _serviceItems.isNotEmpty
          ? _onServiceLoadMore
          : null,
      child: child,
    );
  }
}

enum FavoriteTabType { services, jobs }

class _FavoriteServiceList extends StatelessWidget {
  const _FavoriteServiceList({
    required this.items,
    required this.isManaging,
    required this.selectedIds,
    required this.onItemSelectionToggle,
    required this.onDeleteItem,
  });

  final List<collection_models.VisaPackageVO> items;
  final bool isManaging;
  final Set<String> selectedIds;
  final ValueChanged<String> onItemSelectionToggle;
  final ValueChanged<int> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, isManaging ? 104 : 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SelectableWrapper(
          key: ValueKey<String>('service-${item.packageId}'),
          isManaging: isManaging,
          selected: selectedIds.contains(item.packageId.toString()),
          onTap: () => onItemSelectionToggle(item.packageId.toString()),
          onDelete: () => onDeleteItem(item.packageId),
          child: _FavoriteServiceCard(item: item),
        );
      },
    );
  }
}

class _FavoriteJobList extends StatelessWidget {
  const _FavoriteJobList({
    required this.items,
    required this.isManaging,
    required this.selectedIds,
    required this.onItemSelectionToggle,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyTap,
    required this.onDeleteItem,
  });

  final List<collection_models.JobListVO> items;
  final bool isManaging;
  final Set<String> selectedIds;
  final ValueChanged<String> onItemSelectionToggle;
  final Set<String> applyingJobIds;
  final Set<String> appliedJobIds;
  final Future<void> Function(collection_models.JobListVO item) onApplyTap;
  final Future<void> Function(int jobId) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, isManaging ? 104 : 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final String itemId = item.jobId.toString();
        return _SelectableWrapper(
          key: ValueKey<String>('job-$itemId'),
          isManaging: isManaging,
          selected: selectedIds.contains(itemId),
          onTap: () => onItemSelectionToggle(itemId),
          onDelete: () => onDeleteItem(item.jobId),
          child: _FavoriteJobCard(
            item: item,
            isApplying: applyingJobIds.contains(itemId),
            isApplied: appliedJobIds.contains(itemId),
            onApplyTap: onApplyTap,
          ),
        );
      },
    );
  }
}

class _SelectableWrapper extends StatelessWidget {
  const _SelectableWrapper({
    super.key,
    required this.isManaging,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.child,
  });

  final bool isManaging;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isManaging) {
      return Slidable(
        key: key,
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 68 / 351,
          children: <Widget>[
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '我的.删除'.tr(),
                  style: TestStyle.pingFangMedium(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: child,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 18, right: 12, left: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: _SelectionIcon(selected: selected),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SelectionIcon extends StatelessWidget {
  const _SelectionIcon({required this.selected});

  final bool selected;

  /// 构建收藏管理态的多选图标，并与全局多选视觉保持一致。
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Icon(
        selected ? Icons.check_circle : Icons.panorama_fish_eye,
        key: ValueKey<bool>(selected),
        size: 20,
        // 收藏管理态属于多选入口，图标与公共多选弹层统一为品牌蓝。
        color: selected ? const Color(0xFF096DD9) : const Color(0xFFBFBFBF),
      ),
    );
  }
}

class _FavoriteServiceCard extends StatelessWidget {
  const _FavoriteServiceCard({required this.item});

  final collection_models.VisaPackageVO item;

  @override
  Widget build(BuildContext context) {
    return VisaServiceCard(
      data: item.toCardData(),
      onTap: () => context.push(
        RoutePaths.serviceDetail,
        extra: ServiceDetailPageArgs(
          packageId: item.packageId,
          initialIsCollected: true,
        ),
      ),
    );
  }
}

class _FavoriteJobCard extends ConsumerWidget {
  const _FavoriteJobCard({
    required this.item,
    required this.isApplying,
    required this.isApplied,
    required this.onApplyTap,
  });

  final collection_models.JobListVO item;
  final bool isApplying;
  final bool isApplied;
  final Future<void> Function(collection_models.JobListVO item) onApplyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<TagCategory, Map<String, TagItemVO>> tagLookupByCategory =
        ref.watch(jobCardTagLookupProvider).asData?.value ??
        const <TagCategory, Map<String, TagItemVO>>{};

    return JobPositionCard(
      data: item.toCardData(),
      tagLookupByCategory: tagLookupByCategory,
      onTap: () => context.push(
        RoutePaths.jobDetail,
        extra: JobDetailPageArgs(jobId: item.jobId),
      ),
      onApply: !isApplied
          ? () {
              onApplyTap(item);
            }
          : null,
      isApplying: isApplying,
      applyButtonText: isApplied ? '招聘.已投递'.tr() : '招聘卡片.一键投递'.tr(),
    );
  }
}

class _FavoriteServicesEmptyState extends StatelessWidget {
  const _FavoriteServicesEmptyState();

  /// 收藏签证为空时展示空态提示。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '我的.还没有收藏签证服务'.tr(),
        style: TestStyle.pingFangRegular(
          fontSize: 14,
          color: Color(0xFF8C8C8C),
        ),
      ),
    );
  }
}

class _FavoriteServicesErrorState extends StatelessWidget {
  const _FavoriteServicesErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  /// 收藏签证加载失败时展示重试入口。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.pingFangRegular(
                fontSize: 14,
                color: Color(0xFF8C8C8C),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

class _FavoriteJobsEmptyState extends StatelessWidget {
  const _FavoriteJobsEmptyState();

  /// 收藏岗位为空时展示空态提示。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '我的.还没有收藏岗位'.tr(),
        style: TestStyle.pingFangRegular(
          fontSize: 14,
          color: Color(0xFF8C8C8C),
        ),
      ),
    );
  }
}

class _FavoriteJobsErrorState extends StatelessWidget {
  const _FavoriteJobsErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  /// 收藏岗位加载失败时展示重试入口。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFBFBFBF),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                onRetry();
              },
              child: Text('通用.重试'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesManageBar extends StatelessWidget {
  const _FavoritesManageBar({
    required this.allSelected,
    required this.hasSelection,
    required this.onSelectAllTap,
    required this.onDeleteTap,
  });

  final bool allSelected;
  final bool hasSelection;
  final VoidCallback onSelectAllTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
        ),
        child: Row(
          children: <Widget>[
            InkWell(
              onTap: onSelectAllTap,
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: <Widget>[
                  _SelectionIcon(selected: allSelected),
                  const SizedBox(width: 8),
                  Text(
                    '我的.全选'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 14,
                      color: Color(0xFF262626),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 96,
              height: 40,
              child: FilledButton(
                onPressed: onDeleteTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D4F),
                  disabledBackgroundColor: const Color(0xFFFFB3B5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  '我的.删除'.tr(),
                  style: TestStyle.pingFangMedium(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on collection_models.JobListVO {
  /// 将收藏岗位接口返回的数据映射为职位卡片数据。
  JobPositionCardData toCardData() {
    final List<JobPositionCardTagData> apiTags = tags
        .map(
          (collection_models.TagVO tag) => JobPositionCardTagData(
            label: tag.label.trim(),
            type: tag.type.trim(),
          ),
        )
        .where((JobPositionCardTagData tag) => tag.label.isNotEmpty)
        .toList(growable: false);
    final List<JobPositionCardTagData> requirementTags = <JobPositionCardTagData>[
      ...apiTags.where(
        (JobPositionCardTagData tag) => tag.type != TagCategory.highlight.value,
      ),
      if (hasVisaSupport)
        JobPositionCardTagData(label: '招聘卡片.提供签证'.tr(), type: null),
    ].take(3).toList(growable: false);
    final List<JobPositionCardTagData> highlightTags = <JobPositionCardTagData>[
      ...apiTags.where(
        (JobPositionCardTagData tag) => tag.type == TagCategory.highlight.value,
      ),
      if (isUrgent)
        JobPositionCardTagData(
          label: '招聘卡片.急招'.tr(),
          type: TagCategory.highlight.value,
        ),
    ];
    final List<String> parts = <String>[
      country.trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    final String currency = salaryCurrency.isEmpty ? '¥' : salaryCurrency;
    final String minText = salaryMin % 1 == 0
        ? salaryMin.toInt().toString()
        : salaryMin.toStringAsFixed(1);
    final String maxText = salaryMax % 1 == 0
        ? salaryMax.toInt().toString()
        : salaryMax.toStringAsFixed(1);
    final String salary = salaryMax > 0
        ? '$currency$minText~$maxText'
        : '$currency$minText';

    return JobPositionCardData(
      title: title,
      salary: salaryPeriod.isEmpty ? salary : '$salary/$salaryPeriod',
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: employer.name,
      location: parts.join('·'),
      showApplyButton: true,
    );
  }
}

extension on collection_models.VisaPackageVO {
  /// 将收藏签证接口数据映射为签证卡片展示数据。
  VisaServiceCardData toCardData() {
    final List<String> tags = <String>[
      _formatFavoriteCountry(targetCountry),
      _formatFavoriteVisaType(visaType),
    ].where((String value) => value.isNotEmpty).toList(growable: false);

    return VisaServiceCardData(
      title: name.trim().isEmpty ? '首页.签证套餐'.tr() : name,
      rating: '0.0',
      cases: estimatedDays > 0
          ? '服务详情.预计办理天数'.tr(
              namedArgs: <String, String>{'days': estimatedDays.toString()},
            )
          : '我的.已收藏套餐'.tr(),
      tags: tags.isEmpty ? <String>['我的.签证服务'.tr()] : tags,
      description: _buildFavoriteDescription(),
      packages: tiers.isEmpty
          ? <VisaServicePackageData>[
              VisaServicePackageData(
                title: '我的.默认档位'.tr(),
                currency: currency,
                price: _formatFavoritePrice(0),
              ),
            ]
          : tiers
                .map(
                  (collection_models.TierVO tier) => VisaServicePackageData(
                    title: tier.name.trim().isEmpty
                        ? '服务详情.套餐档位'.tr()
                        : tier.name,
                    currency: currency,
                    price: _formatFavoritePrice(tier.price),
                  ),
                )
                .toList(growable: false),
    );
  }

  /// 拼装收藏签证卡片简介，优先展示材料数量和办理时长。
  String _buildFavoriteDescription() {
    final List<String> parts = <String>[
      if (requiredMaterials.isNotEmpty)
        '我的.所需材料项'.tr(
          namedArgs: <String, String>{
            'count': requiredMaterials.length.toString(),
          },
        ),
      if (estimatedDays > 0)
        '我的.预计办理天数'.tr(
          namedArgs: <String, String>{'days': estimatedDays.toString()},
        ),
    ];
    if (parts.isEmpty) {
      return '我的.已收藏签证套餐说明'.tr();
    }
    return parts.join('，');
  }
}

/// 格式化收藏签证价格数值，货币符号由卡片组件统一渲染。
String _formatFavoritePrice(double price) {
  return price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(1);
}

/// 将收藏签证国家代码转为展示文案。
String _formatFavoriteCountry(String country) {
  return switch (country.trim().toUpperCase()) {
    'DE' => '国家.德国'.tr(),
    'FR' => '国家.法国'.tr(),
    'IT' => '国家.意大利'.tr(),
    _ => country.trim(),
  };
}

/// 将收藏签证类型代码转为展示文案。
String _formatFavoriteVisaType(String visaType) {
  return switch (visaType.trim().toLowerCase()) {
    'work' => '服务详情.工作签'.tr(),
    'travel' => '服务详情.旅游签'.tr(),
    'tech' => '服务详情.技术签'.tr(),
    'nursing' => '服务详情.护理签'.tr(),
    'study' => '服务详情.留学签'.tr(),
    _ => visaType.trim(),
  };
}
