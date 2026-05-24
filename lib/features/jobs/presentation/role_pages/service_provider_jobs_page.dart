import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/page_result.dart';
import '../../../visa/data/visa_package_models.dart';
import '../../../visa/data/visa_package_providers.dart';

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
      children: <Widget>[
        _PageHeader(
          topPadding: topPadding,
          onPublishTap: () => context.push(RoutePaths.editVisaPackage),
        ),
        _PageTabBar(
          tabs: _PackageTab.values
              .map((tab) => tab.label)
              .toList(growable: false),
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
    label: '已上架',
    status: 'active',
    emptyText: '暂无已上架套餐',
    secondaryActionLabel: '下架',
    secondaryActionStatus: 'inactive',
  ),
  inactive(
    label: '已下架',
    status: 'inactive',
    emptyText: '暂无已下架套餐',
    secondaryActionLabel: '上架',
    secondaryActionStatus: 'active',
  ),
  draft(label: '已驳回', status: 'draft', emptyText: '暂无已驳回套餐');

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
  List<VisaPackageVO>? _packages;
  final Set<int> _updatingPackageIds = <int>{};

  Future<void> _handleSecondaryAction(VisaPackageVO package) async {
    final String? nextStatus = widget.tab.secondaryActionStatus;
    if (nextStatus == null || _updatingPackageIds.contains(package.packageId)) {
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
        final List<VisaPackageVO> currentPackages =
            _packages ?? const <VisaPackageVO>[];
        _packages = currentPackages
            .where((VisaPackageVO item) => item.packageId != package.packageId)
            .toList(growable: false);
      });
      ref.invalidate(myVisaPackageListProvider(widget.tab.status));
      ref.invalidate(myVisaPackageListProvider(nextStatus));
      _showMessage(widget.tab.status == 'active' ? '套餐已下架' : '套餐已上架');
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? const Color(0xFFD9363E) : null,
          content: Text(message),
        ),
      );
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '操作失败，请稍后重试' : message;
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
        text: widget.tab.emptyText,
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
        return _PackageCard(
          data: _PackageCardData.fromVisaPackage(package, widget.tab),
          onSecondaryAction: widget.tab.secondaryActionStatus == null
              ? null
              : () => _handleSecondaryAction(package),
          onPrimaryAction: () {
            context.push(
              '${RoutePaths.editVisaPackage}?packageId=${package.packageId}',
            );
          },
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
    final AsyncValue<PageResult<VisaPackageVO>> packagesAsync = ref.watch(
      myVisaPackageListProvider(widget.tab.status),
    );
    ref.listen<AsyncValue<PageResult<VisaPackageVO>>>(
      myVisaPackageListProvider(widget.tab.status),
      (_, AsyncValue<PageResult<VisaPackageVO>> next) {
        next.whenData((PageResult<VisaPackageVO> pageResult) {
          if (!mounted) {
            return;
          }
          setState(() {
            _packages = pageResult.list;
          });
        });
      },
    );

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(myVisaPackageListProvider(widget.tab.status).future),
      child: packagesAsync.when(
        data: (PageResult<VisaPackageVO> pageResult) {
          final List<VisaPackageVO> packages = _packages ?? pageResult.list;
          return _buildPackageList(context, bottomPadding, packages);
        },
        loading: () => _packages != null
            ? _buildPackageList(context, bottomPadding, _packages!)
            : _PackageLoadingState(bottomPadding: bottomPadding),
        error: (Object error, StackTrace _) => _packages != null
            ? _buildPackageList(context, bottomPadding, _packages!)
            : _PackageLoadError(
                bottomPadding: bottomPadding,
                errorText: error.toString(),
                onRetry: () {
                  ref.invalidate(myVisaPackageListProvider(widget.tab.status));
                },
              ),
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
          const Expanded(
            child: Text(
              '套餐管理',
              style: TextStyle(
                color: Color(0xE6000000),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
          ),
          InkWell(
            onTap: onPublishTap,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '发布',
                style: TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
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

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(tabs.length, (int index) {
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
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF096DD9)
                            : const Color(0xFF262626),
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        height: 22 / 14,
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
    this.onSecondaryAction,
    this.onPrimaryAction,
    this.isSecondaryActionLoading = false,
  });

  final _PackageCardData data;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onPrimaryAction;
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
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 24 / 16,
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
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
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
                  const _DeleteButton(),
                  const Spacer(),
                  if (data.secondaryActionLabel != null) ...<Widget>[
                    _GhostButton(
                      label: data.secondaryActionLabel!,
                      onTap: onSecondaryAction,
                      isLoading: isSecondaryActionLoading,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _PrimaryButton(label: '编辑', onTap: onPrimaryAction),
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
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 20 / 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.price,
            style: const TextStyle(
              color: Color(0xFFFE5815),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 20 / 12,
              ),
              children: <InlineSpan>[
                const TextSpan(text: '已售 '),
                TextSpan(text: '${item.soldCount}'),
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
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 10 / 10,
        ),
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
      child: const Text(
        '暂无套餐档位',
        style: TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 20 / 12,
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
  const _DeleteButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF4D4F), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '删除',
        style: TextStyle(
          color: Color(0xFFD9363E),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 12 / 12,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 12 / 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _PackageCardData {
  const _PackageCardData({
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
      title: package.name,
      metaText: package.estimatedDays > 0 ? '预计${package.estimatedDays}天' : '-',
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
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 22 / 14,
            ),
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
        const Text(
          '套餐列表加载失败',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF262626),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 20 / 12,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 88,
            height: 32,
            child: OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ),
        ),
      ],
    );
  }
}

const Map<String, String> _countryLabelMap = <String, String>{
  'DE': '德国',
  'FR': '法国',
  'CH': '瑞士',
  'GB': '英国',
  'IT': '意大利',
  'ES': '西班牙',
};

const Map<String, String> _visaTypeLabelMap = <String, String>{
  'work': '工作签',
  'travel': '旅行签',
  'tech': '技术签',
  'nursing': '护理签',
  'study': '留学签',
};

String _resolveCountryLabel(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  return _countryLabelMap[normalized.toUpperCase()] ?? normalized;
}

String _resolveVisaTypeLabel(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  return _visaTypeLabelMap[normalized.toLowerCase()] ?? normalized;
}

String _formatCurrencyAmount(String currency, double amount) {
  final String prefix = switch (currency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'EUR' => 'EUR ',
    'USD' => 'USD ',
    _ => currency.trim().isEmpty ? '' : '${currency.trim().toUpperCase()} ',
  };
  return '$prefix${_formatDecimal(amount)}';
}

String _formatDecimal(double amount) {
  final bool isInteger = amount == amount.roundToDouble();
  final String raw = isInteger
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  final List<String> parts = raw.split('.');
  final StringBuffer buffer = StringBuffer();
  final String integerPart = parts.first;

  for (int index = 0; index < integerPart.length; index++) {
    final int remaining = integerPart.length - index;
    buffer.write(integerPart[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  if (parts.length > 1 && parts[1].isNotEmpty) {
    buffer
      ..write('.')
      ..write(parts[1]);
  }
  return buffer.toString();
}
