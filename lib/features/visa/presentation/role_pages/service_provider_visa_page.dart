import 'package:easy_localization/easy_localization.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/network/api_error_feedback.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../features/me/data/dictionary_providers.dart';
import '../../../../features/message/application/chat/chat_page_args.dart';
import '../../../../features/order/data/visa_order_models.dart';
import '../../../../features/order/data/visa_order_providers.dart';
import '../../../../features/order/presentation/order_detail_page.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/network/models/dictionary_models.dart';
import '../../../../shared/ui/test_keys.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_user_avatar.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 服务商签证页。
class ServiceProviderVisaPage extends ConsumerStatefulWidget {
  const ServiceProviderVisaPage({super.key});

  @override
  ConsumerState<ServiceProviderVisaPage> createState() =>
      _ServiceProviderVisaPageState();
}

class _ServiceProviderVisaPageState
    extends ConsumerState<ServiceProviderVisaPage> {
  static const int _pageSize = 20;

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
  }) async {
    final _CountryFilter effectiveCountry = country ?? _selectedCountry;
    final _StatusFilter effectiveStatus = status ?? _selectedStatus;

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
            status: effectiveStatus.apiValue,
            country: effectiveCountry.apiValue,
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

    setState(() => _isLoadingMore = true);

    try {
      final response = await ref
          .read(visaOrderServiceProvider)
          .listProviderOrders(
            page: _currentPage + 1,
            pageSize: _pageSize,
            status: _selectedStatus.apiValue,
            country: _selectedCountry.apiValue,
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
      _showMessage(_normalizeError(error));
    }
  }

  String _normalizeError(Object error) {
    return ApiErrorFeedback.resolveMessage(error, fallback: '订单.订单加载失败'.tr());
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

  void _openOrderDetail(VisaOrderVO order) {
    if (order.orderId <= 0) {
      _showMessage('订单.订单详情不存在'.tr());
      return;
    }
    context.push(
      RoutePaths.orderDetail,
      extra: OrderDetailPageArgs(orderId: order.orderId),
    );
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
      _showMessage('订单.国家列表加载失败'.tr());
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
      options: _StatusFilter.values,
      labelBuilder: (_StatusFilter item) => item.label.tr(),
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
                            labelBuilder(option),
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
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      key: AppTestKeys.pageServiceProviderVisa,
      color: const Color(0xFFF5F7FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _OrderTopSection(topPadding: topPadding),
          _FilterBar(
            countryLabel: _selectedCountry.label,
            statusLabel: _selectedStatus.label.tr(),
            countryButtonKey: AppTestKeys.actionServiceProviderVisaCountryFilter,
            statusButtonKey: AppTestKeys.actionServiceProviderVisaStatusFilter,
            onCountryTap: _selectCountry,
            onStatusTap: _selectStatus,
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
                    return _OrderErrorState(
                      message: _errorMessage!,
                      bottomInset: bottomPadding,
                      onRetryTap: _loadOrders,
                    );
                  }
                  if (_orders.isEmpty) {
                    return _OrderEmptyState(bottomInset: bottomPadding);
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      bottomPadding + 16,
                    ),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final VisaOrderVO order = _orders[index];
                      return _OrderCard(
                        order: order,
                        onTap: () => _openOrderDetail(order),
                        onContactTap: () => _handleContactTap(order),
                        onProcessTap: () => _openOrderDetail(order),
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
}

class _OrderTopSection extends StatelessWidget {
  const _OrderTopSection({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, topPadding, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '导航.订单'.tr(),
                  style: TestStyle.pingFangMedium(
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/images/mon8ysqa-n6jz78w.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.countryLabel,
    required this.statusLabel,
    required this.countryButtonKey,
    required this.statusButtonKey,
    required this.onCountryTap,
    required this.onStatusTap,
  });

  final String countryLabel;
  final String statusLabel;
  final Key countryButtonKey;
  final Key statusButtonKey;
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
          _FilterButton(
            buttonKey: countryButtonKey,
            label: countryLabel,
            onTap: onCountryTap,
          ),
          const SizedBox(width: 12),
          _FilterButton(
            buttonKey: statusButtonKey,
            label: statusLabel,
            onTap: onStatusTap,
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
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
    required this.onTap,
    required this.onContactTap,
    required this.onProcessTap,
  });

  final VisaOrderVO order;
  final VoidCallback onTap;
  final VoidCallback onContactTap;
  final VoidCallback onProcessTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: AppTestKeys.cardServiceProviderVisaOrder(order.orderId),
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      label: _displayStatusText(order),
                      style: _statusStyleFor(order.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    ClipOval(
                      child: AppUserAvatar(
                        imageUrl: order.avatarUrl,
                        size: 40,
                        placeholderAssetPath:
                            'assets/images/order_management_customer_avatar-56586a.png',
                      ),
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
                                  _displayCustomerName(order),
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
                            _displayServiceName(order),
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
                      buttonKey: AppTestKeys.actionServiceProviderVisaOrderContact(
                        order.orderId,
                      ),
                      label: '订单.联系客户'.tr(),
                      outlined: true,
                      onTap: onContactTap,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      buttonKey: AppTestKeys.actionServiceProviderVisaOrderProcess(
                        order.orderId,
                      ),
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
      ),
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
        label.trim().isEmpty ? '订单.处理中'.tr() : label,
        style: TestStyle.pingFangRegular(fontSize: 11, color: textColor),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TestStyle.regular(
              fontSize: 12,
              color: Color(0xFF262626),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.buttonKey,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF096DD9),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TestStyle.regular(
              fontSize: 12,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return outlined
        ? _GhostActionButton(buttonKey: buttonKey, label: label, onTap: onTap)
        : _PrimaryActionButton(
            buttonKey: buttonKey,
            label: label,
            onTap: onTap,
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
        border: Border.all(color: const Color(0xFFFF6661)),
        borderRadius: BorderRadius.circular(3),
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

class _CountryFilter {
  const _CountryFilter({required this.label, this.apiValue});

  static _CountryFilter get all => _CountryFilter(label: '订单.全部国家'.tr());

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
  all('订单.订单状态', null),
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
  final String? apiValue;
}

enum _OrderStatusStyle { red, blue, outlined }

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _OrderEmptyState extends StatelessWidget {
  const _OrderEmptyState({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppEmptyState(message: '订单.暂无符合条件的订单'.tr()),
        ),
      ],
    );
  }
}

class _OrderErrorState extends StatelessWidget {
  const _OrderErrorState({
    required this.message,
    required this.bottomInset,
    required this.onRetryTap,
  });

  final String message;
  final double bottomInset;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Color(0xFFBFBFBF),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TestStyle.regular(
                  fontSize: 14,
                  color: Color(0xFF8C8C8C),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetryTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF096DD9),
                ),
                child: Text('我的.重新加载'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _displayCustomerName(VisaOrderVO order) {
  final String nickname = order.nickname.trim();
  return nickname.isEmpty ? '订单.订单客户'.tr() : nickname;
}

String _displayServiceName(VisaOrderVO order) {
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

String _displayStatusText(VisaOrderVO order) {
  final String statusLabel = order.statusLabel.trim();
  if (statusLabel.isNotEmpty) {
    return statusLabel;
  }
  final String status = order.status.trim();
  return status.isEmpty ? '订单.处理中'.tr() : status;
}

_OrderStatusStyle _statusStyleFor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'completed':
      return _OrderStatusStyle.outlined;
    case 'pending_payment':
    case 'pending_upload':
    case 'reviewing':
    case 'embassy_submitted':
      return _OrderStatusStyle.blue;
    default:
      return _OrderStatusStyle.red;
  }
}

String _formatAmount(double amount, String? currency) {
  return AppCurrency.formatAmount(
    amount,
    currency,
    fractionDigitsWhenNeeded: 2,
    trimTrailingZeros: false,
  );
}

String _formatUpdatedText(String raw) {
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
