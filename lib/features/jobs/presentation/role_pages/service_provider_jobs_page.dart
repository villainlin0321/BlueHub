import 'package:easy_localization/easy_localization.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/ui/test_keys.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../visa/data/visa_package_models.dart';
import '../../../visa/data/visa_package_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 服务商套餐管理页：按 Figma「套餐管理-已上架」实现。
class ServiceProviderJobsPage extends ConsumerStatefulWidget {
  const ServiceProviderJobsPage({super.key});

  @override
  ConsumerState<ServiceProviderJobsPage> createState() =>
      _ServiceProviderJobsPageState();
}

class _ServiceProviderJobsPageState
    extends ConsumerState<ServiceProviderJobsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: _PackageTab.values.length,
    vsync: this,
  )..addListener(_handleTabChanged);

  int _selectedTabIndex = 0;

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) {
      return;
    }
    if (_selectedTabIndex == _tabController.index) {
      return;
    }
    setState(() {
      _selectedTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      key: AppTestKeys.pageServiceProviderJobs,
      children: <Widget>[
        _PageHeader(
          topPadding: topPadding,
          onPublishTap: () => context.push(RoutePaths.editVisaPackage),
        ),
        _PageTabBar(
          tabs: _PackageTab.values,
          selectedIndex: _selectedTabIndex,
          onTap: (int index) {
            _tabController.animateTo(index);
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _PackageTab.values
                .map(
                  (_PackageTab tab) => _PackageTabView(
                    key: PageStorageKey<String>(
                      'service-provider-jobs-${tab.name}',
                    ),
                    tab: tab,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

enum _PackageTab {
  active(
    label: '套餐管理.已上架',
    status: 'active',
    emptyText: '套餐管理.暂无已上架套餐',
    secondaryActionLabel: '套餐管理.下架',
    secondaryActionStatus: 'inactive',
  ),
  inactive(
    label: '套餐管理.已下架',
    status: 'inactive',
    emptyText: '套餐管理.暂无已下架套餐',
    secondaryActionLabel: '套餐管理.上架',
    secondaryActionStatus: 'active',
  ),
  draft(label: '套餐管理.已驳回', status: 'draft', emptyText: '套餐管理.暂无已驳回套餐');

  const _PackageTab({
    required this.label,
    required this.status,
    required this.emptyText,
    this.secondaryActionLabel,
    this.secondaryActionStatus,
  });

  final String label;
  final String status;
  final String emptyText;
  final String? secondaryActionLabel;
  final String? secondaryActionStatus;
}

class _PackageTabView extends ConsumerStatefulWidget {
  const _PackageTabView({super.key, required this.tab});

  final _PackageTab tab;

  @override
  ConsumerState<_PackageTabView> createState() => _PackageTabViewState();
}

class _PackageTabViewState extends ConsumerState<_PackageTabView> {
  static const int _pageSize = 20;

  List<VisaPackageVO> _packages = const <VisaPackageVO>[];
  final Set<int> _updatingPackageIds = <int>{};
  final Set<int> _deletingPackageIds = <int>{};
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadPackages);
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final PageResult<VisaPackageVO> pageResult = await ref
          .read(visaPackageServiceProvider)
          .listMyPackages(
            page: 1,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _packages = pageResult.list;
        _currentPage = pageResult.pagination.page;
        _hasMore = pageResult.pagination.hasNext;
        _isInitialLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialLoading = false;
        _hasMore = false;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  Future<void> _refreshPackages() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      if (_packages.isEmpty) {
        _errorMessage = null;
      }
    });

    try {
      final PageResult<VisaPackageVO> pageResult = await ref
          .read(visaPackageServiceProvider)
          .listMyPackages(
            page: 1,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _packages = pageResult.list;
        _currentPage = pageResult.pagination.page;
        _hasMore = pageResult.pagination.hasNext;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshing = false;
        if (_packages.isEmpty) {
          _errorMessage = _normalizeError(error);
        }
      });
      if (_packages.isNotEmpty) {
        _showMessage(_normalizeError(error), isError: true);
      }
    }
  }

  Future<void> _loadMorePackages() async {
    if (_isInitialLoading || _isRefreshing || _isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final PageResult<VisaPackageVO> pageResult = await ref
          .read(visaPackageServiceProvider)
          .listMyPackages(
            page: _currentPage + 1,
            pageSize: _pageSize,
            status: widget.tab.status,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _packages = <VisaPackageVO>[..._packages, ...pageResult.list];
        _currentPage = pageResult.pagination.page;
        _hasMore = pageResult.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
      });
      _showMessage(_normalizeError(error), isError: true);
    }
  }

  Future<void> _handleSecondaryAction(VisaPackageVO package) async {
    final String? nextStatus = widget.tab.secondaryActionStatus;
    if (nextStatus == null ||
        _updatingPackageIds.contains(package.packageId) ||
        _deletingPackageIds.contains(package.packageId)) {
      return;
    }

    setState(() {
      _updatingPackageIds.add(package.packageId);
    });

    try {
      await ref
          .read(visaPackageServiceProvider)
          .updatePackageStatus(
            packageId: package.packageId,
            request: UpdatePackageStatusBO(status: nextStatus),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _updatingPackageIds.remove(package.packageId);
        _packages = _packages
            .where((VisaPackageVO item) => item.packageId != package.packageId)
            .toList(growable: false);
      });
      ref.invalidate(myVisaPackageListProvider(widget.tab.status));
      ref.invalidate(myVisaPackageListProvider(nextStatus));
      _showMessage(
        widget.tab.status == 'active' ? '套餐管理.套餐已下架'.tr() : '套餐管理.套餐已上架'.tr(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _updatingPackageIds.remove(package.packageId);
      });
      _showMessage(_normalizeError(error), isError: true);
    }
  }

  Future<bool> _confirmDeletePackage(VisaPackageVO package) async {
    return showAppDeleteConfirmDialog(
      context: context,
      title: '套餐管理.删除套餐'.tr(),
      message: '套餐管理.确认删除套餐'.tr(
        namedArgs: <String, String>{'name': package.name},
      ),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '企业岗位.删除'.tr(),
    );
  }

  Future<void> _deletePackage(VisaPackageVO package) async {
    if (_deletingPackageIds.contains(package.packageId) ||
        _updatingPackageIds.contains(package.packageId)) {
      return;
    }

    final bool confirmed = await _confirmDeletePackage(package);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _deletingPackageIds.add(package.packageId);
    });

    try {
      await ref
          .read(visaPackageServiceProvider)
          .deletePackage(packageId: package.packageId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPackageIds.remove(package.packageId);
        _packages = _packages
            .where((VisaPackageVO item) => item.packageId != package.packageId)
            .toList(growable: false);
      });
      ref.invalidate(myVisaPackageListProvider(widget.tab.status));
      _showMessage('套餐管理.套餐已删除'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPackageIds.remove(package.packageId);
      });
      _showMessage(_normalizeError(error), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    AppToast.show(message);
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '套餐管理.操作失败'.tr() : message;
  }

  Widget _buildPackageList(
    BuildContext context,
    double bottomPadding,
    List<VisaPackageVO> packages,
  ) {
    if (packages.isEmpty) {
      return _PackageEmptyState(
        key: PageStorageKey<String>(
          'service-provider-jobs-empty-${widget.tab.name}',
        ),
        text: widget.tab.emptyText.tr(),
        bottomPadding: bottomPadding,
      );
    }
    return ListView.separated(
      key: PageStorageKey<String>(
        'service-provider-jobs-list-${widget.tab.name}',
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding + 8),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final VisaPackageVO package = packages[index];
        final bool isDeleting = _deletingPackageIds.contains(package.packageId);
        return _PackageCard(
          data: _PackageCardData.fromVisaPackage(package, widget.tab),
          tabStatus: widget.tab.status,
          onDeleteAction: isDeleting ? null : () => _deletePackage(package),
          onSecondaryAction:
              widget.tab.secondaryActionStatus == null || isDeleting
              ? null
              : () => _handleSecondaryAction(package),
          onPrimaryAction: isDeleting
              ? null
              : () {
                  context
                      .push(
                        '${RoutePaths.editVisaPackage}?packageId=${package.packageId}',
                      )
                      .then((_) {
                        if (!mounted) {
                          return;
                        }
                        _refreshPackages();
                      });
                },
          isDeleteActionLoading: isDeleting,
          isSecondaryActionLoading: _updatingPackageIds.contains(
            package.packageId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return EasyRefresh(
      key: AppTestKeys.sectionServiceProviderJobsPanel(widget.tab.status),
      header: const ClassicHeader(),
      footer: const ClassicFooter(),
      onRefresh: _refreshPackages,
      onLoad: _hasMore && _packages.isNotEmpty ? _loadMorePackages : null,
      child: Builder(
        builder: (BuildContext context) {
          if (_isInitialLoading && _packages.isEmpty) {
            return _PackageLoadingState(bottomPadding: bottomPadding);
          }
          if (_errorMessage != null && _packages.isEmpty) {
            return _PackageLoadError(
              bottomPadding: bottomPadding,
              errorText: _errorMessage!,
              onRetry: _loadPackages,
            );
          }
          if (_packages.isEmpty) {
            return _PackageEmptyState(
              key: PageStorageKey<String>(
                'service-provider-jobs-empty-${widget.tab.name}',
              ),
              text: widget.tab.emptyText.tr(),
              bottomPadding: bottomPadding,
            );
          }
          return _buildPackageList(context, bottomPadding, _packages);
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.topPadding, required this.onPublishTap});

  final double topPadding;
  final VoidCallback onPublishTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 16, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '套餐管理.标题'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 17,
                color: Color(0xE6000000),
              ),
            ),
          ),
          InkWell(
            key: AppTestKeys.actionServiceProviderJobsPublish,
            onTap: onPublishTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '套餐管理.发布'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 14,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTabBar extends StatelessWidget {
  const _PageTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<_PackageTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(tabs.length, (int index) {
          final bool selected = index == selectedIndex;
          final _PackageTab tab = tabs[index];
          return Expanded(
            child: InkWell(
              key: AppTestKeys.tabServiceProviderJobs(tab.status),
              onTap: () => onTap(index),
              child: Padding(
                padding: EdgeInsets.only(top: 11, bottom: selected ? 0 : 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      tab.label.tr(),
                      textAlign: TextAlign.center,
                      style: TestStyle.medium(
                        fontSize: 14,
                        color: selected
                            ? const Color(0xFF096DD9)
                            : const Color(0xFF262626),
                      ),
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.data,
    required this.tabStatus,
    this.onDeleteAction,
    this.onSecondaryAction,
    this.onPrimaryAction,
    this.isDeleteActionLoading = false,
    this.isSecondaryActionLoading = false,
  });

  final _PackageCardData data;
  final String tabStatus;
  final VoidCallback? onDeleteAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onPrimaryAction;
  final bool isDeleteActionLoading;
  final bool isSecondaryActionLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TestStyle.medium(
                              fontSize: 16,
                              color: Color(0xFF262626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _MoreIcon(),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  ...data.tags.map(
                    (String tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TagChip(label: tag),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data.metaText,
                    style: TestStyle.regular(
                      fontSize: 12,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              if (data.packages.isEmpty)
                const _EmptyTierState()
              else
                ...List<Widget>.generate(data.packages.length, (int index) {
                  final _PackagePriceItem item = data.packages[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == data.packages.length - 1 ? 0 : 8,
                    ),
                    child: _PackagePriceRow(item: item),
                  );
                }),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _DeleteButton(
                    buttonKey: AppTestKeys.actionServiceProviderJobsDelete(
                      tabStatus,
                      data.packageId,
                    ),
                    onTap: onDeleteAction,
                    isLoading: isDeleteActionLoading,
                  ),
                  const Spacer(),
                  if (data.secondaryActionLabel != null) ...<Widget>[
                    _GhostButton(
                      buttonKey:
                          AppTestKeys.actionServiceProviderJobsStatusToggle(
                            tabStatus,
                            data.packageId,
                          ),
                      label: data.secondaryActionLabel!.tr(),
                      onTap: onSecondaryAction,
                      isLoading: isSecondaryActionLoading,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _PrimaryButton(
                    buttonKey: AppTestKeys.actionServiceProviderJobsEdit(
                      tabStatus,
                      data.packageId,
                    ),
                    label: '企业岗位.编辑'.tr(),
                    onTap: onPrimaryAction,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackagePriceRow extends StatelessWidget {
  const _PackagePriceRow({required this.item});

  final _PackagePriceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Text(
            item.name,
            style: TestStyle.regular(fontSize: 12, color: Color(0xFF262626)),
          ),
          const SizedBox(width: 12),
          Text(
            item.price,
            style: TestStyle.medium(fontSize: 13, color: Color(0xFFFE5815)),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: TestStyle.pingFangRegular(
                fontSize: 12,
                color: Color(0xFF8C8C8C),
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '套餐管理.已售'.tr(
                    namedArgs: <String, String>{
                      'count': item.soldCount.toString(),
                    },
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4), width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 10, color: Color(0xFF546D96)),
      ),
    );
  }
}

class _EmptyTierState extends StatelessWidget {
  const _EmptyTierState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '套餐管理.暂无套餐档位'.tr(),
        style: TestStyle.pingFangRegular(
          fontSize: 12,
          color: Color(0xFF8C8C8C),
        ),
      ),
    );
  }
}

class _MoreIcon extends StatelessWidget {
  const _MoreIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: Color(0xFF171A1D),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.buttonKey,
    this.onTap,
    this.isLoading = false,
  });

  final Key buttonKey;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 86,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFF4D4F), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFD9363E),
                ),
              )
            : Text(
                '企业岗位.删除'.tr(),
                style: TestStyle.pingFangRegular(
                  fontSize: 12,
                  color: Color(0xFFD9363E),
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.buttonKey,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TestStyle.regular(
                  fontSize: 12,
                  color: Color(0xFF262626),
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.buttonKey,
    required this.label,
    this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF096DD9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TestStyle.regular(
            fontSize: 12,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _PackageCardData {
  const _PackageCardData({
    required this.packageId,
    required this.title,
    required this.metaText,
    required this.tags,
    required this.packages,
    this.secondaryActionLabel,
  });

  factory _PackageCardData.fromVisaPackage(
    VisaPackageVO package,
    _PackageTab tab,
  ) {
    final List<String> tags = <String>[
      _resolveCountryLabel(package.targetCountry),
      _resolveVisaTypeLabel(package.visaType),
    ].where((String value) => value.isNotEmpty).toList(growable: false);

    return _PackageCardData(
      packageId: package.packageId,
      title: package.name,
      metaText: package.estimatedDays > 0
          ? '套餐管理.预计天数'.tr(
              namedArgs: <String, String>{
                'days': package.estimatedDays.toString(),
              },
            )
          : '-',
      tags: tags,
      packages: package.tiers
          .map(
            (TierVO item) => _PackagePriceItem.fromTier(
              tier: item,
              currency: package.currency,
            ),
          )
          .toList(growable: false),
      secondaryActionLabel: tab.secondaryActionLabel,
    );
  }

  final int packageId;
  final String title;
  final String metaText;
  final List<String> tags;
  final List<_PackagePriceItem> packages;
  final String? secondaryActionLabel;
}

class _PackagePriceItem {
  const _PackagePriceItem({
    required this.name,
    required this.price,
    required this.soldCount,
  });

  factory _PackagePriceItem.fromTier({
    required TierVO tier,
    required String currency,
  }) {
    return _PackagePriceItem(
      name: tier.name,
      price: _formatCurrencyAmount(currency, tier.price),
      soldCount: tier.soldCount,
    );
  }

  final String name;
  final String price;
  final int soldCount;
}

class _PackageLoadingState extends StatelessWidget {
  const _PackageLoadingState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      children: const <Widget>[
        SizedBox(height: 96),
        Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}

class _PackageEmptyState extends StatelessWidget {
  const _PackageEmptyState({
    super.key,
    required this.text,
    required this.bottomPadding,
  });

  final String text;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: key,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      children: <Widget>[
        const SizedBox(height: 108),
        Center(
          child: AppEmptyState(
            message: text,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ],
    );
  }
}

class _PackageLoadError extends StatelessWidget {
  const _PackageLoadError({
    required this.bottomPadding,
    required this.errorText,
    required this.onRetry,
  });

  final double bottomPadding;
  final String errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 24,
        top: 96,
        right: 24,
        bottom: bottomPadding + 8,
      ),
      children: <Widget>[
        Text(
          '套餐管理.套餐列表加载失败'.tr(),
          textAlign: TextAlign.center,
          style: TestStyle.pingFangMedium(
            fontSize: 16,
            color: Color(0xFF262626),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorText,
          textAlign: TextAlign.center,
          style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 88,
            height: 32,
            child: OutlinedButton(
              onPressed: onRetry,
              child: Text('通用.重试'.tr()),
            ),
          ),
        ),
      ],
    );
  }
}

const Map<String, String> _countryLabelMap = <String, String>{
  'DE': '国家.德国',
  'FR': '国家.法国',
  'CH': '国家.瑞士',
  'GB': '国家.英国',
  'IT': '国家.意大利',
  'ES': '国家.西班牙',
};

const Map<String, String> _visaTypeLabelMap = <String, String>{
  'work': '服务详情.工作签',
  'travel': '服务详情.旅游签',
  'tech': '服务详情.技术签',
  'nursing': '服务详情.护理签',
  'study': '服务详情.留学签',
};

String _resolveCountryLabel(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final String? labelKey = _countryLabelMap[normalized.toUpperCase()];
  return labelKey == null ? normalized : labelKey.tr();
}

String _resolveVisaTypeLabel(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final String? labelKey = _visaTypeLabelMap[normalized.toLowerCase()];
  return labelKey == null ? normalized : labelKey.tr();
}

String _formatCurrencyAmount(String currency, double amount) {
  return AppCurrency.formatAmount(amount, currency);
}
