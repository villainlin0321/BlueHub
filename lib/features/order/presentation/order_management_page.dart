import 'package:easy_refresh/easy_refresh.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../features/me/data/dictionary_providers.dart';
import '../../../features/message/application/chat/chat_page_args.dart';
import '../data/visa_order_models.dart';
import '../data/visa_order_providers.dart';
import '../../../shared/models/app_currency.dart';
import '../../../shared/network/models/dictionary_models.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import 'order_detail_page.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';

class OrderManagementPage extends ConsumerStatefulWidget {
  const OrderManagementPage({super.key});

  @override
  ConsumerState<OrderManagementPage> createState() =>
      _OrderManagementPageState();
}

class _OrderManagementPageState extends ConsumerState<OrderManagementPage> {
  static const int _pageSize = 20;
  static const List<_OrderTab> _tabs = <_OrderTab>[
    _OrderTab.all,
    _OrderTab.pending,
    _OrderTab.processing,
    _OrderTab.completed,
  ];

  static const List<_StatusFilter> _statuses = <_StatusFilter>[
    _StatusFilter.all,
    _StatusFilter.pendingPayment,
    _StatusFilter.pendingUpload,
    _StatusFilter.reviewing,
    _StatusFilter.rejected,
    _StatusFilter.processing,
    _StatusFilter.completed,
    _StatusFilter.cancelled,
    _StatusFilter.refunded,
  ];

  _OrderTab _selectedTab = _OrderTab.all;
  _CountryFilter _selectedCountry = _CountryFilter.all;
  _StatusFilter _selectedStatus = _StatusFilter.all;
  List<VisaOrderVO> _orders = const <VisaOrderVO>[];
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadOrders);
  }

  Future<void> _loadOrders({
    _CountryFilter? country,
    _StatusFilter? status,
    _OrderTab? tab,
  }) async {
    final _OrderTab effectiveTab = tab ?? _selectedTab;
    final _CountryFilter effectiveCountry = country ?? _selectedCountry;
    final _StatusFilter effectiveStatus = status ?? _selectedStatus;
    final String? apiStatus = _statusForRequest(
      tab: effectiveTab,
      status: effectiveStatus,
    );
    final String? apiCountry = effectiveTab == _OrderTab.all
        ? effectiveCountry.apiValue
        : null;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(visaOrderServiceProvider)
          .listProviderOrders(
            page: 1,
            pageSize: _pageSize,
            status: apiStatus,
            country: apiCountry,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _orders = response.list;
        _currentPage = response.pagination.page;
        _hasMore = response.pagination.hasNext;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final String? apiStatus = _statusForRequest(
      tab: _selectedTab,
      status: _selectedStatus,
    );
    final String? apiCountry = _selectedTab == _OrderTab.all
        ? _selectedCountry.apiValue
        : null;

    setState(() => _isLoadingMore = true);

    try {
      final response = await ref
          .read(visaOrderServiceProvider)
          .listProviderOrders(
            page: _currentPage + 1,
            pageSize: _pageSize,
            status: apiStatus,
            country: apiCountry,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _orders = <VisaOrderVO>[..._orders, ...response.list];
        _currentPage = response.pagination.page;
        _hasMore = response.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingMore = false);
      AppToast.show(_normalizeError(error));
    }
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '订单.订单加载失败'.tr() : message;
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  void _handleContactTap(VisaOrderVO order) {
    final int targetUserId = order.contactTargetUserId;
    if (targetUserId <= 0) {
      _showMessage('订单.客户信息缺失'.tr());
      return;
    }
    context.push(
      RoutePaths.chat,
      extra: ChatPageArgs(
        targetUserId: targetUserId,
        targetUserRole: order.contactTargetUserRole,
        nickname: _displayCustomerName(order),
        avatarUrl: order.avatarUrl,
        relatedOrderId: order.orderId,
        packageName: order.packageName.trim().isNotEmpty
            ? order.packageName
            : order.tierName,
        orderStatus: order.statusLabel,
      ),
    );
  }

  String? _statusForRequest({
    required _OrderTab tab,
    required _StatusFilter status,
  }) {
    if (tab == _OrderTab.all) {
      return status == _StatusFilter.all ? null : status.apiValue;
    }
    return tab.apiValue;
  }

  Future<List<_CountryFilter>> _loadCountryFilters() async {
    final result = await ref.read(
      countrySearchProvider(
        const CountrySearchQuery(page: 1, pageSize: 300),
      ).future,
    );
    final Set<String> seen = <String>{};
    final List<_CountryFilter> countries = result.list
        .where(
          (CountryVO item) =>
              item.countryCode.trim().isNotEmpty &&
              item.nameZh.trim().isNotEmpty &&
              seen.add(item.countryCode.trim()),
        )
        .map(
          (CountryVO item) => _CountryFilter(
            label: item.nameZh.trim(),
            apiValue: item.countryCode.trim(),
          ),
        )
        .toList(growable: false);
    return <_CountryFilter>[_CountryFilter.all, ...countries];
  }

  Future<void> _selectCountry() async {
    final List<_CountryFilter> countries;
    try {
      countries = await _loadCountryFilters();
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show('订单.国家列表加载失败'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final _CountryFilter? result = await _showFilterSheet<_CountryFilter>(
      title: '订单.选择国家'.tr(),
      currentValue: _selectedCountry,
      options: countries,
      labelBuilder: (_CountryFilter item) => item.label,
    );
    if (result == null || result == _selectedCountry) {
      return;
    }
    setState(() => _selectedCountry = result);
    await _loadOrders(country: result);
  }

  Future<void> _selectStatus() async {
    final _StatusFilter? result = await _showFilterSheet<_StatusFilter>(
      title: '订单.选择订单状态'.tr(),
      currentValue: _selectedStatus,
      options: _statuses,
      labelBuilder: (_StatusFilter item) => item.label,
    );
    if (result == null || result == _selectedStatus) {
      return;
    }
    setState(() => _selectedStatus = result);
    await _loadOrders(status: result);
  }

  Future<T?> _showFilterSheet<T>({
    required String title,
    required T currentValue,
    required List<T> options,
    required String Function(T value) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (BuildContext context) {
        final double maxHeight = MediaQuery.sizeOf(context).height * 0.6;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      title,
                      style: TestStyle.semibold(
                        fontSize: 16,
                        color: Color(0xFF262626),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T option = options[index];
                        final bool selected = option == currentValue;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Text(
                            labelBuilder(option).tr(),
                            style: TestStyle.semibold(
                              fontSize: 14,
                              color: selected
                                  ? const Color(0xFF096DD9)
                                  : const Color(0xFF262626),
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF096DD9),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 40,
        titleSpacing: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(RoutePaths.me);
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '订单.订单管理'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _OrderTabs(
            tabs: _tabs,
            selectedTab: _selectedTab,
            onSelected: (_OrderTab value) {
              if (value == _selectedTab) {
                return;
              }
              setState(() => _selectedTab = value);
              _loadOrders(tab: value);
            },
          ),
          _FilterBar(
            countryLabel: _selectedCountry.label,
            statusLabel: _selectedStatus.label,
            onCountryTap: _selectCountry,
            onStatusTap: _selectStatus,
            showStatusFilter: _selectedTab == _OrderTab.all,
          ),
          Expanded(
            child: EasyRefresh(
              header: const ClassicHeader(),
              footer: const ClassicFooter(),
              onRefresh: _loadOrders,
              onLoad: _hasMore && _orders.isNotEmpty ? _loadMoreOrders : null,
              child: Builder(
                builder: (BuildContext context) {
                  if (_isLoading && _orders.isEmpty) {
                    return const _LoadingView();
                  }
                  if (_errorMessage != null && _orders.isEmpty) {
                    return _OrderManagementErrorState(
                      bottomInset: bottomInset,
                      message: _errorMessage!,
                      onRetryTap: _loadOrders,
                    );
                  }
                  if (_orders.isEmpty) {
                    return _OrderManagementEmptyState(
                      bottomInset: bottomInset,
                      onResetTap: () async {
                        setState(() {
                          _selectedTab = _OrderTab.all;
                          _selectedCountry = _CountryFilter.all;
                          _selectedStatus = _StatusFilter.all;
                        });
                        await _loadOrders(
                          country: _CountryFilter.all,
                          status: _StatusFilter.all,
                          tab: _OrderTab.all,
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final VisaOrderVO item = _orders[index];
                      return _OrderCard(
                        order: item,
                        onContactTap: () => _handleContactTap(item),
                        onProcessTap: () => context.push(
                          RoutePaths.orderDetail,
                          extra: OrderDetailPageArgs(orderId: item.orderId),
                        ),
                        onTap: () => context.push(
                          RoutePaths.orderDetail,
                          extra: OrderDetailPageArgs(orderId: item.orderId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayCustomerName(VisaOrderVO order) {
    final String nickname = order.nickname.trim();
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return '订单.订单客户'.tr();
  }
}

enum _OrderTab {
  all('订单.全部'),
  pending('订单.待处理', 'pending_payment'),
  processing('订单.办理中', 'embassy_submitted'),
  completed('订单.已完成', 'completed');

  const _OrderTab(this.label, [this.apiValue]);

  final String label;
  final String? apiValue;
}

class _CountryFilter {
  const _CountryFilter({required this.label, this.apiValue});

  static _CountryFilter all = _CountryFilter(label: '订单.全部国家'.tr());

  final String label;
  final String? apiValue;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CountryFilter &&
            runtimeType == other.runtimeType &&
            label == other.label &&
            apiValue == other.apiValue;
  }

  @override
  int get hashCode => Object.hash(label, apiValue);
}

enum _StatusFilter {
  all('订单.订单状态', 'all'),
  pendingPayment('订单.待付款', 'pending_payment'),
  pendingUpload('订单.待用户上传材料', 'pending_upload'),
  reviewing('订单.材料审核中', 'reviewing'),
  rejected('订单.材料被驳回', 'rejected'),
  processing('订单.办理中', 'embassy_submitted'),
  completed('订单.已完成', 'completed'),
  cancelled('订单.已取消', 'cancelled'),
  refunded('订单.已退款', 'refunded');

  const _StatusFilter(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

enum _OrderStatusStyle { red, blue, outlined }

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<_OrderTab> tabs;
  final _OrderTab selectedTab;
  final ValueChanged<_OrderTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x297E868E), width: 0.5),
        ),
      ),
      child: Row(
        children: tabs
            .map((_OrderTab tab) {
              final bool selected = tab == selectedTab;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        tab.label.tr(),
                        style: TestStyle.medium(
                          fontSize: 14,
                          color: selected
                              ? const Color(0xFF096DD9)
                              : const Color(0xFF262626),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: 20,
                        height: 2,
                        color: selected
                            ? const Color(0xFF096DD9)
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.countryLabel,
    required this.statusLabel,
    required this.onCountryTap,
    required this.onStatusTap,
    required this.showStatusFilter,
  });

  final String countryLabel;
  final String statusLabel;
  final VoidCallback onCountryTap;
  final VoidCallback onStatusTap;
  final bool showStatusFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          _FilterButton(label: countryLabel, onTap: onCountryTap),
          if (showStatusFilter) ...<Widget>[
            const SizedBox(width: 12),
            _FilterButton(label: statusLabel, onTap: onStatusTap),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label.tr(),
              style: TestStyle.regular(fontSize: 14, color: Color(0xFF171A1D)),
            ),
            const SizedBox(width: 2),
            SvgPicture.asset(
              'assets/images/icon_arrow_down.svg',
              width: 12,
              height: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onContactTap,
    required this.onProcessTap,
    required this.onTap,
  });

  final VisaOrderVO order;
  final VoidCallback onContactTap;
  final VoidCallback onProcessTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(text: '订单.订单号'.tr()),
                          TextSpan(
                            text: order.orderNo,
                            style: TestStyle.regular(color: Color(0xFF8C8C8C)),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TestStyle.regular(
                        fontSize: 12,
                        color: Color(0xFF8C8C8C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusTag(
                    label: order.statusLabel.trim().isEmpty
                        ? '订单.处理中'.tr()
                        : order.statusLabel,
                    style: _statusStyleFor(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipOval(child: _OrderAvatar(avatarUrl: order.avatarUrl)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                _customerNameFor(order),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TestStyle.medium(
                                  fontSize: 16,
                                  color: Color(0xFF262626),
                                ),
                              ),
                            ),
                            if (order.isUrgent) ...<Widget>[
                              const SizedBox(width: 6),
                              const _UrgentTag(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _serviceNameFor(order),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TestStyle.regular(
                            fontSize: 12,
                            color: Color(0xFF8C8C8C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatAmount(order.amount, order.currency),
                    style: TestStyle.medium(
                      fontSize: 16,
                      color: Color(0xFFFE5815),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _formatUpdatedText(order.updatedAt),
                      style: TestStyle.pingFangRegular(
                        fontSize: 12,
                        color: Color(0xFF8C8C8C),
                      ),
                    ),
                  ),
                  _ActionButton(
                    label: '订单.联系客户'.tr(),
                    outlined: true,
                    onTap: onContactTap,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: '订单.处理订单'.tr(),
                    outlined: false,
                    onTap: onProcessTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _customerNameFor(VisaOrderVO order) {
    final String nickname = order.nickname.trim();
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return '订单.订单客户'.tr();
  }

  static String _serviceNameFor(VisaOrderVO order) {
    final String packageName = order.packageName.trim();
    if (packageName.isNotEmpty) {
      return packageName;
    }
    final String tierName = order.tierName.trim();
    if (tierName.isNotEmpty) {
      return tierName;
    }
    return '订单.签证服务'.tr();
  }

  static _OrderStatusStyle _statusStyleFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return _OrderStatusStyle.outlined;
      case 'pending_payment':
        return _OrderStatusStyle.blue;
      case 'pending_upload':
        return _OrderStatusStyle.blue;
      case 'reviewing':
        return _OrderStatusStyle.blue;
      case 'embassy_submitted':
        return _OrderStatusStyle.blue;
      default:
        return _OrderStatusStyle.red;
    }
  }

  static String _formatAmount(double amount, String? currency) {
    return AppCurrency.formatAmount(
      amount,
      currency,
      fractionDigitsWhenNeeded: 2,
      trimTrailingZeros: false,
    );
  }

  static String _formatUpdatedText(String raw) {
    final DateTime? updatedAt = DateTime.tryParse(raw)?.toLocal();
    if (updatedAt == null) {
      return raw.trim().isEmpty ? '订单.刚刚更新'.tr() : raw;
    }

    final Duration difference = DateTime.now().difference(updatedAt);
    if (difference.inMinutes < 1) {
      return '订单.刚刚更新'.tr();
    }
    if (difference.inMinutes < 60) {
      return '订单.分钟前更新'.tr(
        namedArgs: <String, String>{'count': difference.inMinutes.toString()},
      );
    }
    if (difference.inHours < 24) {
      return '订单.小时前更新'.tr(
        namedArgs: <String, String>{'count': difference.inHours.toString()},
      );
    }
    return '订单.月日更新'.tr(
      namedArgs: <String, String>{
        'month': updatedAt.month.toString(),
        'day': updatedAt.day.toString(),
      },
    );
  }
}

class _OrderAvatar extends StatelessWidget {
  const _OrderAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppUserAvatar(
      imageUrl: avatarUrl,
      size: 40,
      placeholderAssetPath:
          'assets/images/order_management_customer_avatar-56586a.png',
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.style});

  final String label;
  final _OrderStatusStyle style;

  @override
  Widget build(BuildContext context) {
    late final Color backgroundColor;
    late final Color borderColor;
    late final Color textColor;

    switch (style) {
      case _OrderStatusStyle.red:
        backgroundColor = const Color(0xFFFFEBEB);
        borderColor = Colors.transparent;
        textColor = const Color(0xFFFF4D4F);
        break;
      case _OrderStatusStyle.blue:
        backgroundColor = const Color(0xFFEDF5FF);
        borderColor = Colors.transparent;
        textColor = const Color(0xFF386EF8);
        break;
      case _OrderStatusStyle.outlined:
        backgroundColor = Colors.white;
        borderColor = const Color(0xFFA3AFD4);
        textColor = const Color(0xFF546D96);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 11, color: textColor),
      ),
    );
  }
}

class _UrgentTag extends StatelessWidget {
  const _UrgentTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFFF6661)),
      ),
      child: Text(
        '订单.紧急'.tr(),
        style: TestStyle.pingFangRegular(
          fontSize: 10,
          color: Color(0xFFFF0B03),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = outlined
        ? Colors.white
        : const Color(0xFF096DD9);
    final Color borderColor = outlined
        ? const Color(0xFFD9D9D9)
        : const Color(0xFF096DD9);
    final Color textColor = outlined ? const Color(0xFF262626) : Colors.white;

    return SizedBox(
      width: 77,
      height: 28,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: textColor,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TestStyle.regular(fontSize: 12, color: textColor),
        ),
      ),
    );
  }
}

class _OrderManagementEmptyState extends StatelessWidget {
  const _OrderManagementEmptyState({
    required this.bottomInset,
    required this.onResetTap,
  });

  final double bottomInset;
  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 80, 24, bottomInset + 24),
      children: <Widget>[
        AppEmptyState(message: '订单.暂无符合条件的订单'.tr()),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onResetTap,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF096DD9)),
          child: Text('订单.重置筛选'.tr()),
        ),
      ],
    );
  }
}

class _OrderManagementErrorState extends StatelessWidget {
  const _OrderManagementErrorState({
    required this.bottomInset,
    required this.message,
    required this.onRetryTap,
  });

  final double bottomInset;
  final String message;
  final VoidCallback onRetryTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 80, 24, bottomInset + 24),
      children: <Widget>[
        const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFBFBFBF)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onRetryTap,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF096DD9)),
          child: Text('订单.重新加载'.tr()),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const <Widget>[
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
