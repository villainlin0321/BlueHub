import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/job_position_card.dart';
import '../../../shared/widgets/visa_service_card.dart';
import '../../jobs/presentation/job_apply_helper.dart';
import '../../jobs/presentation/job_detail_page.dart';
import '../../service_detail/presentation/service_detail_page.dart';
import '../data/collection_models.dart' as collection_models;
import '../data/collection_providers.dart';

class MyFavoritesPage extends ConsumerStatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  ConsumerState<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends ConsumerState<MyFavoritesPage>
    with SingleTickerProviderStateMixin {
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _mapAsset = 'assets/images/job_detail_map-56586a.png';
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_handleTabChanged);

  List<collection_models.VisaPackageVO> _serviceItems =
      <collection_models.VisaPackageVO>[];
  List<collection_models.JobListVO> _jobItems = <collection_models.JobListVO>[];

  bool _isManaging = false;
  FavoriteTabType _currentTab = FavoriteTabType.services;
  bool _isServiceLoading = false;
  bool _isJobLoading = false;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
  Future<void> _loadCollectedPackages() async {
    setState(() {
      _isServiceLoading = true;
      _serviceErrorMessage = null;
    });

    try {
      final response = await ref
          .read(collectionServiceProvider)
          .listCollectedPackages(page: 1, pageSize: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _isServiceLoading = false;
        _serviceItems = response.list;
        _serviceErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isServiceLoading = false;
        _serviceErrorMessage = _resolveServiceErrorMessage(error);
      });
    }
  }

  /// 加载收藏岗位列表，成功后用于详情跳转与投递。
  Future<void> _loadCollectedJobs() async {
    setState(() {
      _isJobLoading = true;
      _jobErrorMessage = null;
    });

    try {
      final response = await ref
          .read(collectionServiceProvider)
          .listCollectedJobs(page: 1, pageSize: 50);
      if (!mounted) {
        return;
      }
      setState(() {
        _isJobLoading = false;
        _jobItems = response.list;
        _jobErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJobLoading = false;
        _jobErrorMessage = _resolveJobErrorMessage(error);
      });
    }
  }

  /// 统一提取收藏岗位列表的错误文案。
  String _resolveJobErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '收藏岗位加载失败，请稍后重试';
  }

  /// 统一提取收藏签证列表的错误文案。
  String _resolveServiceErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '收藏签证加载失败，请稍后重试';
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

    final String? errorMessage = await submitJobApplication(
      context,
      jobId: item.jobId,
    );
    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      setState(() {
        _submittingJobIds.remove(itemId);
        _appliedJobIds.add(itemId);
      });
      _showMessage('投递成功');
      return;
    }

    setState(() {
      _submittingJobIds.remove(itemId);
    });
    _showMessage(errorMessage);
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
      _showMessage(jobIds.length == 1 ? '已取消收藏' : '已批量取消收藏');
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
      _showMessage(packageIds.length == 1 ? '已取消收藏' : '已批量取消收藏');
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
        title: const Text(
          '我的收藏',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w600,
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
                _isManaging ? '退出管理' : '管理',
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
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
              indicatorColor: const Color(0xFF096DD9),
              indicatorWeight: 2,
              tabs: const <Widget>[
                Tab(text: '签证服务'),
                Tab(text: '招聘岗位'),
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
    if (_isJobLoading && _jobItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_jobErrorMessage != null && _jobItems.isEmpty) {
      return _FavoriteJobsErrorState(
        message: _jobErrorMessage!,
        onRetry: _loadCollectedJobs,
      );
    }
    if (_jobItems.isEmpty) {
      return const _FavoriteJobsEmptyState();
    }
    return _FavoriteJobList(
      items: _jobItems,
      isManaging: _isManaging,
      selectedIds: _selectedJobIds,
      mapAssetPath: _mapAsset,
      onItemSelectionToggle: _toggleJobSelection,
      applyingJobIds: _submittingJobIds,
      appliedJobIds: _appliedJobIds,
      onApplyTap: _handleApplyJob,
      onDeleteItem: _deleteJobItem,
    );
  }

  /// 根据收藏签证加载状态切换列表、空态和错误态。
  Widget _buildServiceTab() {
    if (_isServiceLoading && _serviceItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_serviceErrorMessage != null && _serviceItems.isEmpty) {
      return _FavoriteServicesErrorState(
        message: _serviceErrorMessage!,
        onRetry: _loadCollectedPackages,
      );
    }
    if (_serviceItems.isEmpty) {
      return const _FavoriteServicesEmptyState();
    }
    return _FavoriteServiceList(
      items: _serviceItems,
      isManaging: _isManaging,
      selectedIds: _selectedServiceIds,
      onItemSelectionToggle: _toggleServiceSelection,
      onDeleteItem: _deleteServiceItem,
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
    required this.mapAssetPath,
    required this.onItemSelectionToggle,
    required this.applyingJobIds,
    required this.appliedJobIds,
    required this.onApplyTap,
    required this.onDeleteItem,
  });

  final List<collection_models.JobListVO> items;
  final bool isManaging;
  final Set<String> selectedIds;
  final String mapAssetPath;
  final ValueChanged<String> onItemSelectionToggle;
  final Set<String> applyingJobIds;
  final Set<String> appliedJobIds;
  final Future<void> Function(collection_models.JobListVO item) onApplyTap;
  final Future<void> Function(int jobId) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
            mapAssetPath: mapAssetPath,
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
                child: const Text(
                  '删除',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF186CFF) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF186CFF) : const Color(0xFFD9D9D9),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
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
        extra: ServiceDetailPageArgs(packageId: item.packageId),
      ),
    );
  }
}

class _FavoriteJobCard extends StatelessWidget {
  const _FavoriteJobCard({
    required this.item,
    required this.mapAssetPath,
    required this.isApplying,
    required this.isApplied,
    required this.onApplyTap,
  });

  final collection_models.JobListVO item;
  final String mapAssetPath;
  final bool isApplying;
  final bool isApplied;
  final Future<void> Function(collection_models.JobListVO item) onApplyTap;

  @override
  Widget build(BuildContext context) {
    return JobPositionCard(
      data: item.toCardData(mapAssetPath: mapAssetPath),
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
      applyButtonText: isApplied ? '已投递' : '一键投递',
    );
  }
}

class _FavoriteServicesEmptyState extends StatelessWidget {
  const _FavoriteServicesEmptyState();

  /// 收藏签证为空时展示空态提示。
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '还没有收藏签证服务',
        style: TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 14,
          fontWeight: FontWeight.w400,
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
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
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
    return const Center(
      child: Text(
        '还没有收藏岗位',
        style: TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 14,
          fontWeight: FontWeight.w400,
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
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('重试'),
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
                  const Text(
                    '全选',
                    style: TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
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
                  hasSelection ? '删除' : '删除',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
  JobPositionCardData toCardData({required String mapAssetPath}) {
    final List<String> tagLabels = tags
        .map((collection_models.TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != '急招'),
      if (hasVisaSupport && !tagLabels.contains('提供签证')) '提供签证',
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[if (isUrgent) '急招'];
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
      previewImageAssetPath: mapAssetPath,
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
      title: name.trim().isEmpty ? '签证套餐' : name,
      rating: '0.0',
      cases: estimatedDays > 0 ? '预计$estimatedDays天' : '已收藏套餐',
      tags: tags.isEmpty ? <String>['签证服务'] : tags,
      description: _buildFavoriteDescription(),
      packages: tiers.isEmpty
          ? <VisaServicePackageData>[
              VisaServicePackageData(
                title: '默认档位',
                price: _formatFavoritePrice(0, currency),
              ),
            ]
          : tiers
                .map(
                  (collection_models.TierVO tier) => VisaServicePackageData(
                    title: tier.name.trim().isEmpty ? '套餐档位' : tier.name,
                    price: _formatFavoritePrice(tier.price, currency),
                  ),
                )
                .toList(growable: false),
    );
  }

  /// 拼装收藏签证卡片简介，优先展示材料数量和办理时长。
  String _buildFavoriteDescription() {
    final List<String> parts = <String>[
      if (requiredMaterials.isNotEmpty) '所需材料${requiredMaterials.length}项',
      if (estimatedDays > 0) '预计办理$estimatedDays天',
    ];
    if (parts.isEmpty) {
      return '已收藏签证套餐，可进入详情查看完整服务说明';
    }
    return parts.join('，');
  }
}

/// 格式化收藏签证价格。
String _formatFavoritePrice(double price, String currency) {
  final String prefix = switch (currency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'EUR' => '€',
    'USD' => '\$',
    _ => currency.trim().isEmpty ? '¥' : '${currency.trim()} ',
  };
  final String value = price % 1 == 0
      ? price.toInt().toString()
      : price.toStringAsFixed(1);
  return '$prefix$value';
}

/// 将收藏签证国家代码转为展示文案。
String _formatFavoriteCountry(String country) {
  return switch (country.trim().toUpperCase()) {
    'DE' => '德国',
    'FR' => '法国',
    'IT' => '意大利',
    _ => country.trim(),
  };
}

/// 将收藏签证类型代码转为展示文案。
String _formatFavoriteVisaType(String visaType) {
  return switch (visaType.trim().toLowerCase()) {
    'work' => '工作签',
    'travel' => '旅游签',
    'tech' => '技术签',
    'nursing' => '护理签',
    'study' => '留学签',
    _ => visaType.trim(),
  };
}
