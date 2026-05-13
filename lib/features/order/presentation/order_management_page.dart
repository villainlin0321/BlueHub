import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../data/visa_order_models.dart';
import '../data/visa_order_providers.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class OrderManagementPage extends ConsumerStatefulWidget {
  const OrderManagementPage({super.key});

  @override
  ConsumerState<OrderManagementPage> createState() =>
      _OrderManagementPageState();
}

class _OrderManagementPageState extends ConsumerState<OrderManagementPage> {
  static const List<_OrderTab> _tabs = <_OrderTab>[
    _OrderTab.all,
    _OrderTab.pending,
    _OrderTab.processing,
    _OrderTab.completed,
  ];

  static const List<_CountryFilter> _countries = <_CountryFilter>[
    _CountryFilter.all,
    _CountryFilter.germany,
    _CountryFilter.france,
  ];

  static const List<_StatusFilter> _statuses = <_StatusFilter>[
    _StatusFilter.all,
    _StatusFilter.pendingPayment,
    _StatusFilter.pendingUpload,
    _StatusFilter.processing,
    _StatusFilter.completed,
  ];

  _OrderTab _selectedTab = _OrderTab.all;
  _CountryFilter _selectedCountry = _CountryFilter.all;
  _StatusFilter _selectedStatus = _StatusFilter.all;
  List<VisaOrderVO> _orders = const <VisaOrderVO>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadOrders);
  }

  void _showPlaceholderToast(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label（占位）')));
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(visaOrderServiceProvider).listProviderOrders(
        page: 1,
        pageSize: 20,
        status: _selectedStatus.apiValue,
        country: _selectedCountry.apiValue,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _orders = response.list;
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

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '订单加载失败，请稍后重试' : message;
  }

  Future<void> _selectCountry() async {
    final _CountryFilter? result = await _showFilterSheet<_CountryFilter>(
      title: '选择国家',
      currentValue: _selectedCountry,
      options: _countries,
      labelBuilder: (_CountryFilter item) => item.label,
    );
    if (result == null || result == _selectedCountry) {
      return;
    }
    setState(() => _selectedCountry = result);
    await _loadOrders();
  }

  Future<void> _selectStatus() async {
    final _StatusFilter? result = await _showFilterSheet<_StatusFilter>(
      title: '选择订单状态',
      currentValue: _selectedStatus,
      options: _statuses,
      labelBuilder: (_StatusFilter item) => item.label,
    );
    if (result == null || result == _selectedStatus) {
      return;
    }
    setState(() => _selectedStatus = result);
    await _loadOrders();
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
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...options.map((T option) {
                  final bool selected = option == currentValue;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      labelBuilder(option),
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF096DD9)
                            : const Color(0xFF262626),
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<VisaOrderVO> get _visibleOrders {
    return _orders.where((VisaOrderVO item) {
      if (_selectedTab == _OrderTab.all) {
        return true;
      }
      return _tabForStatus(item.status) == _selectedTab;
    }).toList(growable: false);
  }

  _OrderTab _tabForStatus(String status) {
    final String normalized = status.trim().toLowerCase();
    if (normalized == 'completed') {
      return _OrderTab.completed;
    }
    if (normalized == 'processing') {
      return _OrderTab.processing;
    }
    if (normalized.startsWith('pending_') || normalized == 'all') {
      return _OrderTab.pending;
    }
    return _OrderTab.pending;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final List<VisaOrderVO> visibleOrders = _visibleOrders;

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
        title: const Text(
          '订单管理',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showPlaceholderToast('搜索'),
            icon: const AppSvgIcon(
              assetPath: 'assets/images/company_application_search.svg',
              fallback: Icons.search_rounded,
              size: 20,
              color: Color(0xE6000000),
            ),
          ),
          const SizedBox(width: 4),
        ],
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
            },
          ),
          _FilterBar(
            countryLabel: _selectedCountry.label,
            statusLabel: _selectedStatus.label,
            onCountryTap: _selectCountry,
            onStatusTap: _selectStatus,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
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
                  if (visibleOrders.isEmpty) {
                    return _OrderManagementEmptyState(
                      bottomInset: bottomInset,
                      onResetTap: () async {
                        setState(() {
                          _selectedTab = _OrderTab.all;
                          _selectedCountry = _CountryFilter.all;
                          _selectedStatus = _StatusFilter.all;
                        });
                        await _loadOrders();
                      },
                    );
                  }

                  return Stack(
                    children: <Widget>[
                      ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          bottomInset + 16,
                        ),
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final VisaOrderVO item = visibleOrders[index];
                          return _OrderCard(
                            order: item,
                            onContactTap: () => _showPlaceholderToast(
                              '联系客户 ${_displayCustomerName(item)}',
                            ),
                            onProcessTap: () => context.push(RoutePaths.orderDetail),
                            onTap: () => context.push(RoutePaths.orderDetail),
                          );
                        },
                      ),
                      if (_isLoading)
                        const Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: Color(0xFF096DD9),
                            backgroundColor: Color(0xFFE6F4FF),
                          ),
                        ),
                    ],
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
    return '订单客户';
  }
}

enum _OrderTab {
  all('全部'),
  pending('待处理'),
  processing('办理中'),
  completed('已完成');

  const _OrderTab(this.label);

  final String label;
}

enum _CountryFilter {
  all('全部国家', null),
  germany('德国', 'DE'),
  france('法国', 'FR');

  const _CountryFilter(this.label, this.apiValue);

  final String label;
  final String? apiValue;
}

enum _StatusFilter {
  all('订单状态', 'all'),
  pendingPayment('待付款', 'pending_payment'),
  pendingUpload('待用户上传材料', 'pending_upload'),
  processing('办理中', 'processing'),
  completed('已完成', 'completed');

  const _StatusFilter(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

enum _OrderStatusStyle {
  red,
  blue,
  outlined,
}

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
        children: tabs.map((_OrderTab tab) {
          final bool selected = tab == selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(tab),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF096DD9)
                          : const Color(0xFF262626),
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w500 : FontWeight.w400,
                      height: 22 / 14,
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
        }).toList(growable: false),
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
  });

  final String countryLabel;
  final String statusLabel;
  final VoidCallback onCountryTap;
  final VoidCallback onStatusTap;

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
          const SizedBox(width: 12),
          _FilterButton(label: statusLabel, onTap: onStatusTap),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.onTap,
  });

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
              label,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
            const SizedBox(width: 2),
            Image.asset(
              'assets/images/dropdown_arrow.png',
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
                          const TextSpan(text: '订单号：'),
                          TextSpan(
                            text: order.orderNo,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontFamily: 'SF UI Text',
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusTag(
                    label: order.statusLabel.trim().isEmpty
                        ? '处理中'
                        : order.statusLabel,
                    style: _statusStyleFor(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ClipOval(
                    child: _OrderAvatar(avatarUrl: order.avatarUrl),
                  ),
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
                                style: const TextStyle(
                                  color: Color(0xFF262626),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 24 / 16,
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
                          style: const TextStyle(
                            color: Color(0xFF8C8C8C),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatAmount(order.amount),
                    style: const TextStyle(
                      color: Color(0xFFFE5815),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
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
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                  _ActionButton(
                    label: '联系客户',
                    outlined: true,
                    onTap: onContactTap,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: '处理订单',
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
    return '订单客户';
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
    return '签证服务';
  }

  static _OrderStatusStyle _statusStyleFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return _OrderStatusStyle.outlined;
      case 'pending_payment':
        return _OrderStatusStyle.blue;
      case 'pending_upload':
        return _OrderStatusStyle.blue;
      case 'processing':
        return _OrderStatusStyle.blue;
      default:
        return _OrderStatusStyle.red;
    }
  }

  static String _formatAmount(double amount) {
    final bool hasFraction = amount % 1 != 0;
    final String raw = hasFraction
        ? amount.toStringAsFixed(2)
        : amount.toStringAsFixed(0);
    final List<String> parts = raw.split('.');
    final String integerPart = parts.first;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      final int reverseIndex = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    if (parts.length == 2 && parts[1].isNotEmpty && parts[1] != '00') {
      return '¥${buffer.toString()}.${parts[1]}';
    }
    return '¥${buffer.toString()}';
  }

  static String _formatUpdatedText(String raw) {
    final DateTime? updatedAt = DateTime.tryParse(raw)?.toLocal();
    if (updatedAt == null) {
      return raw.trim().isEmpty ? '刚刚更新' : raw;
    }

    final Duration difference = DateTime.now().difference(updatedAt);
    if (difference.inMinutes < 1) {
      return '刚刚更新';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前更新';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}小时前更新';
    }
    return '${updatedAt.month}月${updatedAt.day}日更新';
  }
}

class _OrderAvatar extends StatelessWidget {
  const _OrderAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final String url = avatarUrl.trim();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Image.asset(
      'assets/images/order_management_customer_avatar-56586a.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.style,
  });

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
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 12 / 11,
        ),
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
      child: const Text(
        '紧急',
        style: TextStyle(
          color: Color(0xFFFF0B03),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 10 / 10,
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
    final Color backgroundColor =
        outlined ? Colors.white : const Color(0xFF096DD9);
    final Color borderColor =
        outlined ? const Color(0xFFD9D9D9) : const Color(0xFF096DD9);
    final Color textColor =
        outlined ? const Color(0xFF262626) : Colors.white;

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
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 12 / 12,
          ),
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
        const Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: Color(0xFFBFBFBF),
        ),
        const SizedBox(height: 16),
        const Text(
          '暂无符合条件的订单',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onResetTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF096DD9),
          ),
          child: const Text('重置筛选'),
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
        const Icon(
          Icons.cloud_off_rounded,
          size: 48,
          color: Color(0xFFBFBFBF),
        ),
        const SizedBox(height: 16),
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
        TextButton(
          onPressed: onRetryTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF096DD9),
          ),
          child: const Text('重新加载'),
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
