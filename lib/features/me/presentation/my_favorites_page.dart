import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/job_position_card.dart';
import '../../../shared/widgets/visa_service_card.dart';

class MyFavoritesPage extends StatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  State<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage>
    with SingleTickerProviderStateMixin {
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _mapAsset = 'assets/images/job_detail_map-56586a.png';
  static const String _chefAvatarAsset =
      'assets/images/my_favorites_service_avatar_chef.png';
  static const String _italyAvatarAsset =
      'assets/images/my_favorites_service_avatar_italy.png';

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(_handleTabChanged);

  late List<_FavoriteServiceItem> _serviceItems = List<_FavoriteServiceItem>.of(
    _initialServiceItems,
  );
  late List<_FavoriteJobItem> _jobItems = List<_FavoriteJobItem>.of(
    _initialJobItems,
  );

  bool _isManaging = false;
  FavoriteTabType _currentTab = FavoriteTabType.services;
  final Set<String> _selectedServiceIds = <String>{};
  final Set<String> _selectedJobIds = <String>{};

  static const List<_FavoriteServiceItem> _initialServiceItems =
      <_FavoriteServiceItem>[
        _FavoriteServiceItem(
          id: 'service-germany-chef',
          title: '德国厨师专属工作签证',
          avatarAssetPath: _chefAvatarAsset,
          rating: '4.8',
          cases: '服务案例1.2K',
          tags: <String>['过签率高', '办理快'],
          description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国技术工签及厨师专签办理',
          packages: <_FavoriteServicePackage>[
            _FavoriteServicePackage(title: '德国厨师专签标准包', price: '¥15,000'),
            _FavoriteServicePackage(title: '德国厨师专签尊享包', price: '¥15,000'),
          ],
          verified: true,
        ),
        _FavoriteServiceItem(
          id: 'service-italy-center',
          title: '意游签证中心',
          avatarAssetPath: _italyAvatarAsset,
          rating: '4.8',
          cases: '服务案例1.2K',
          tags: <String>['加急办理', '材料辅导'],
          description: '意大利劳务签证、护理工定制签证服务',
          packages: <_FavoriteServicePackage>[
            _FavoriteServicePackage(
              title: '意大利劳务普签',
              price: '¥11,500',
              priceHint: '已降价500',
            ),
          ],
          verified: true,
        ),
        _FavoriteServiceItem(
          id: 'service-france-personal',
          title: '法签通个人服务',
          rating: '4.8',
          cases: '服务案例1.2K',
          tags: <String>['工作签', '个人旅游'],
          description: '提供法国工作签证、旅游签证办理，一对一指导',
          packages: <_FavoriteServicePackage>[
            _FavoriteServicePackage(title: '法国工作签加急', price: '¥18,000'),
          ],
        ),
        _FavoriteServiceItem(
          id: 'service-italy-center-offline',
          title: '意游签证中心',
          avatarAssetPath: _italyAvatarAsset,
          rating: '4.8',
          cases: '服务案例1.2K',
          tags: <String>['加急办理', '材料辅导'],
          description: '意大利劳务签证、护理工定制签证服务',
          packages: <_FavoriteServicePackage>[
            _FavoriteServicePackage(title: '意大利劳务普签', price: '¥11,500'),
          ],
          verified: true,
          archived: true,
        ),
      ];

  static const List<_FavoriteJobItem> _initialJobItems = <_FavoriteJobItem>[
    _FavoriteJobItem(
      id: 'job-chef',
      title: '中餐厨师 (包食宿)',
      salary: '€2,500~3,500',
      company: '柏林老四川餐厅',
      location: '德国·柏林',
      requirementTags: <String>['3-5年经验', '厨师证高级', '提供签证'],
      highlightTags: <String>['急招', '包吃住'],
      showMapPreview: true,
      showApplyButton: true,
    ),
    _FavoriteJobItem(
      id: 'job-assistant',
      title: '中餐帮厨',
      salary: '€1,800~2,200',
      company: '柏林老四川餐厅',
      location: '德国·柏林',
      requirementTags: <String>['3-5年经验', '厨师证高级', '提供签证'],
      highlightTags: <String>['双休', '时间自由'],
      showApplyButton: true,
    ),
    _FavoriteJobItem(
      id: 'job-assistant-offline',
      title: '中餐帮厨',
      salary: '€1,800~2,200',
      company: '柏林老四川餐厅',
      location: '德国·柏林',
      requirementTags: <String>['3-5年经验', '厨师证高级', '提供签证'],
      highlightTags: <String>['双休', '时间自由'],
      archived: true,
    ),
  ];

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
        final ids = _serviceItems.map((item) => item.id).toSet();
        if (_selectedServiceIds.length == ids.length) {
          _selectedServiceIds.clear();
        } else {
          _selectedServiceIds
            ..clear()
            ..addAll(ids);
        }
        return;
      }
      final ids = _jobItems.map((item) => item.id).toSet();
      if (_selectedJobIds.length == ids.length) {
        _selectedJobIds.clear();
      } else {
        _selectedJobIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      if (_currentTab == FavoriteTabType.services) {
        _serviceItems = _serviceItems
            .where((item) => !_selectedServiceIds.contains(item.id))
            .toList();
        _selectedServiceIds.clear();
      } else {
        _jobItems = _jobItems
            .where((item) => !_selectedJobIds.contains(item.id))
            .toList();
        _selectedJobIds.clear();
      }
    });
  }

  void _deleteServiceItem(String id) {
    setState(() {
      _serviceItems = _serviceItems.where((item) => item.id != id).toList();
      _selectedServiceIds.remove(id);
    });
  }

  void _deleteJobItem(String id) {
    setState(() {
      _jobItems = _jobItems.where((item) => item.id != id).toList();
      _selectedJobIds.remove(id);
    });
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
              children: <Widget>[
                _FavoriteServiceList(
                  items: _serviceItems,
                  isManaging: _isManaging,
                  selectedIds: _selectedServiceIds,
                  onItemSelectionToggle: _toggleServiceSelection,
                  onDeleteItem: _deleteServiceItem,
                ),
                _FavoriteJobList(
                  items: _jobItems,
                  isManaging: _isManaging,
                  selectedIds: _selectedJobIds,
                  mapAssetPath: _mapAsset,
                  onItemSelectionToggle: _toggleJobSelection,
                  onApplyTap: () => _showMessage('一键投递（占位）'),
                  onDeleteItem: _deleteJobItem,
                ),
              ],
            ),
          ),
        ],
      ),
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

  final List<_FavoriteServiceItem> items;
  final bool isManaging;
  final Set<String> selectedIds;
  final ValueChanged<String> onItemSelectionToggle;
  final ValueChanged<String> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12, 12, 12, isManaging ? 104 : 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SelectableWrapper(
          key: ValueKey<String>('service-${item.id}'),
          isManaging: isManaging,
          selected: selectedIds.contains(item.id),
          onTap: () => onItemSelectionToggle(item.id),
          onDelete: () => onDeleteItem(item.id),
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
    required this.onApplyTap,
    required this.onDeleteItem,
  });

  final List<_FavoriteJobItem> items;
  final bool isManaging;
  final Set<String> selectedIds;
  final String mapAssetPath;
  final ValueChanged<String> onItemSelectionToggle;
  final VoidCallback onApplyTap;
  final ValueChanged<String> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12, 12, 12, isManaging ? 104 : 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SelectableWrapper(
          key: ValueKey<String>('job-${item.id}'),
          isManaging: isManaging,
          selected: selectedIds.contains(item.id),
          onTap: () => onItemSelectionToggle(item.id),
          onDelete: () => onDeleteItem(item.id),
          child: _FavoriteJobCard(
            item: item,
            mapAssetPath: mapAssetPath,
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

  final _FavoriteServiceItem item;

  @override
  Widget build(BuildContext context) {
    return VisaServiceCard(
      data: item.cardData,
      onTap: () => context.push(RoutePaths.serviceDetail),
    );
  }
}

class _FavoriteJobCard extends StatelessWidget {
  const _FavoriteJobCard({
    required this.item,
    required this.mapAssetPath,
    required this.onApplyTap,
  });

  final _FavoriteJobItem item;
  final String mapAssetPath;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    return JobPositionCard(
      data: item.cardData(mapAssetPath: mapAssetPath),
      onApply: item.showApplyButton && !item.archived ? onApplyTap : null,
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

class _FavoriteServiceItem {
  const _FavoriteServiceItem({
    required this.id,
    required this.title,
    required this.rating,
    required this.cases,
    required this.tags,
    required this.description,
    required this.packages,
    this.avatarAssetPath,
    this.verified = false,
    this.archived = false,
  });

  final String id;
  final String title;
  final String? avatarAssetPath;
  final String rating;
  final String cases;
  final List<String> tags;
  final String description;
  final List<_FavoriteServicePackage> packages;
  final bool verified;
  final bool archived;

  VisaServiceCardData get cardData {
    return VisaServiceCardData(
      title: title,
      avatarAssetPath: avatarAssetPath,
      rating: rating,
      cases: cases,
      tags: tags,
      description: description,
      packages: packages
          .map((package) => package.cardData)
          .toList(growable: false),
      verified: verified,
      archived: archived,
      statusText: archived ? '已下架' : null,
    );
  }
}

class _FavoriteServicePackage {
  const _FavoriteServicePackage({
    required this.title,
    required this.price,
    this.priceHint,
  });

  final String title;
  final String price;
  final String? priceHint;

  VisaServicePackageData get cardData {
    return VisaServicePackageData(
      title: title,
      price: price,
      priceHint: priceHint,
    );
  }
}

class _FavoriteJobItem {
  const _FavoriteJobItem({
    required this.id,
    required this.title,
    required this.salary,
    required this.company,
    required this.location,
    required this.requirementTags,
    required this.highlightTags,
    this.showMapPreview = false,
    this.showApplyButton = false,
    this.archived = false,
  });

  final String id;
  final String title;
  final String salary;
  final String company;
  final String location;
  final List<String> requirementTags;
  final List<String> highlightTags;
  final bool showMapPreview;
  final bool showApplyButton;
  final bool archived;

  JobPositionCardData cardData({required String mapAssetPath}) {
    return JobPositionCardData(
      title: title,
      salary: salary,
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: company,
      location: location,
      showApplyButton: showApplyButton && !archived,
      archived: archived,
      statusText: archived ? '已下架' : null,
      previewImageAssetPath: showMapPreview ? mapAssetPath : null,
    );
  }
}
