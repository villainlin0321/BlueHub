import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../message/application/chat/chat_page_args.dart';
import '../../order/data/visa_order_models.dart';
import '../../order/data/visa_order_providers.dart';
import '../../order/presentation/order_detail_page.dart';
import '../../order/presentation/order_payment_bottom_sheet.dart';
import '../../order/presentation/order_review_page.dart';
import '../../../shared/widgets/app_empty_state.dart';

class MyOrdersPage extends ConsumerStatefulWidget {
  const MyOrdersPage({super.key});

  @override
  ConsumerState<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends ConsumerState<MyOrdersPage> {
  static const _tabs = <_OrderFilter>[
    _OrderFilter.all,
    _OrderFilter.pendingUpload,
    _OrderFilter.pendingPayment,
    _OrderFilter.processing,
    _OrderFilter.completed,
  ];

  _OrderFilter _selectedFilter = _OrderFilter.all;
  List<VisaOrderVO> _orders = const <VisaOrderVO>[];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _handleActionTap(_OrderItem order, _OrderAction action) async {
    switch (action.type) {
      case _OrderActionType.goReview:
        final bool? published = await context.push<bool>(
          RoutePaths.orderReview,
          extra: OrderReviewPageArgs(
            orderId: order.orderId,
            providerId: order.providerId,
            title: order.title,
            price: order.price,
            providerName: order.provider,
            packageType: order.packageType,
            orderNo: order.orderNo,
          ),
        );
        if (published == true && mounted) {
          AppToast.show('我的.评价发布成功'.tr());
        }
        return;
      case _OrderActionType.contactMerchant:
        if (order.providerId <= 0) {
          AppToast.show('订单.商家信息缺失'.tr());
          return;
        }
        await context.push(
          RoutePaths.chat,
          extra: ChatPageArgs(
            targetUserId: order.providerId,
            targetUserRole: 'visa_provider',
            nickname: order.provider.trim().isEmpty
                ? '订单.服务商'.tr()
                : order.provider,
            avatarUrl: '',
            relatedOrderId: order.orderId,
            packageName: order.title,
            orderStatus: order.tagLabel ?? '',
          ),
        );
        return;
      case _OrderActionType.uploadMaterials:
      case _OrderActionType.viewProgress:
      case _OrderActionType.viewDetail:
        final bool? updated = await _openOrderDetail(order.orderId);
        if (updated == true && mounted) {
          await _loadOrders();
        }
        return;
      case _OrderActionType.goPay:
        await OrderPaymentBottomSheet.show(
          context: context,
          amountText: order.price,
          orderId: order.orderId,
          packageName: order.title,
          parentContext: context,
          onFlowCompleted: _loadOrders,
        );
        return;
      case _OrderActionType.supplementMaterials:
        AppToast.show(
          '我的.占位提示'.tr(namedArgs: <String, String>{'label': action.label.tr()}),
        );
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadOrders);
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(visaOrderServiceProvider)
          .listMyOrders(
            page: 1,
            pageSize: 20,
            status: _selectedFilter.apiValue,
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
    return message.isEmpty ? '订单.订单加载失败'.tr() : message;
  }

  Future<bool?> _openOrderDetail(int orderId) {
    return context.push<bool>(
      RoutePaths.orderDetail,
      extra: OrderDetailPageArgs(orderId: orderId),
    );
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
          '我的.我的订单'.tr(),
          style: TextStyle(
            color: Color(0xE6262626),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          _OrderStatusTabs(
            filters: _tabs,
            selected: _selectedFilter,
            onSelected: (filter) async {
              if (filter == _selectedFilter) {
                return;
              }
              setState(() => _selectedFilter = filter);
              await _loadOrders();
            },
          ),
          Expanded(child: _buildOrderList(context)),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _OrderStateView(
        message: _errorMessage!,
        buttonLabel: '通用.重试'.tr(),
        onTap: _loadOrders,
      );
    }

    if (_orders.isEmpty) {
      return _OrderStateView(message: '我的.暂无订单数据'.tr());
    }

    final List<_OrderItem> visibleOrders = _orders
        .map(_OrderItem.fromVisaOrder)
        .toList(growable: false);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: visibleOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _OrderCard(
          order: visibleOrders[index],
          onActionTap: _handleActionTap,
          onTap: () => _openOrderDetail(visibleOrders[index].orderId),
        );
      },
    );
  }
}

enum _OrderFilter {
  all('订单.全部', 'all'),
  pendingUpload('我的.待上传', 'pending_upload'),
  pendingPayment('我的.待支付', 'pending_payment'),
  processing('订单.办理中', 'processing'),
  completed('订单.已完成', 'completed');

  const _OrderFilter(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

enum _OrderTagStyle { urgent, blue }

enum _OrderActionType {
  contactMerchant,
  uploadMaterials,
  goPay,
  viewProgress,
  supplementMaterials,
  goReview,
  viewDetail,
}

class _OrderItem {
  const _OrderItem({
    required this.orderId,
    required this.providerId,
    required this.filter,
    required this.timeText,
    required this.title,
    required this.price,
    required this.provider,
    required this.packageType,
    required this.orderNo,
    required this.actions,
    this.tagLabel,
    this.tagStyle,
    this.progressLabel,
    this.progressValue,
  });

  final int orderId;
  final int providerId;
  final _OrderFilter filter;
  final String? tagLabel;
  final _OrderTagStyle? tagStyle;
  final String timeText;
  final String title;
  final String price;
  final String provider;
  final String packageType;
  final String orderNo;
  final String? progressLabel;
  final String? progressValue;
  final List<_OrderAction> actions;

  bool get hasProgress => progressLabel != null && progressValue != null;

  factory _OrderItem.fromVisaOrder(VisaOrderVO order) {
    final _OrderFilter filter = _OrderFilterX.fromStatus(order.status);
    final ({String? label, _OrderTagStyle? style}) tag = _buildTag(order);
    final ({String? label, String? value}) progress = _buildProgress(order);

    return _OrderItem(
      orderId: order.orderId,
      providerId: order.providerInfo.providerId,
      filter: filter,
      tagLabel: tag.label,
      tagStyle: tag.style,
      timeText: _formatTime(order.createdAt),
      title: order.packageName.isEmpty ? '订单.未命名订单'.tr() : order.packageName,
      price: _formatAmount(order.amount),
      provider: order.providerName,
      packageType: order.tierName,
      orderNo: order.orderNo,
      progressLabel: progress.label,
      progressValue: progress.value,
      actions: _buildActions(order),
    );
  }

  static ({String? label, _OrderTagStyle? style}) _buildTag(VisaOrderVO order) {
    if (order.isUrgent) {
      return (label: '订单.紧急'.tr(), style: _OrderTagStyle.urgent);
    }
    final String label = order.statusLabel.trim();
    if (label.isEmpty) {
      return (label: null, style: null);
    }
    return (label: label, style: _OrderTagStyle.blue);
  }

  static ({String? label, String? value}) _buildProgress(VisaOrderVO order) {
    final _OrderFilter filter = _OrderFilterX.fromStatus(order.status);
    if (filter != _OrderFilter.processing) {
      return (label: null, value: null);
    }
    final String stepLabel =
        order.steps
            .asMap()
            .entries
            .where((entry) => entry.key + 1 == order.currentStep)
            .map((entry) => entry.value.label.trim())
            .where((label) => label.isNotEmpty)
            .cast<String?>()
            .firstWhere((label) => label != null, orElse: () => null) ??
        order.statusLabel.trim();
    return (
      label: '我的.当前进度'.tr(),
      value: stepLabel.isEmpty ? '订单.处理中'.tr() : stepLabel,
    );
  }

  static List<_OrderAction> _buildActions(VisaOrderVO order) {
    final _OrderFilter filter = _OrderFilterX.fromStatus(order.status);
    switch (filter) {
      case _OrderFilter.pendingPayment:
        return const <_OrderAction>[
          _OrderAction.outline(_OrderActionType.contactMerchant, '订单.联系商家'),
          _OrderAction.filled(_OrderActionType.goPay, '我的.去支付'),
        ];
      case _OrderFilter.pendingUpload:
        return const <_OrderAction>[
          _OrderAction.outline(_OrderActionType.contactMerchant, '订单.联系商家'),
          _OrderAction.filled(_OrderActionType.uploadMaterials, '订单.上传材料'),
        ];
      case _OrderFilter.processing:
        return const <_OrderAction>[
          _OrderAction.outline(_OrderActionType.contactMerchant, '订单.联系商家'),
          _OrderAction.filled(_OrderActionType.viewProgress, '我的.查看进度'),
        ];
      case _OrderFilter.completed:
        return const <_OrderAction>[
          _OrderAction.outline(_OrderActionType.contactMerchant, '订单.联系商家'),
          _OrderAction.filled(_OrderActionType.goReview, '我的.去评价'),
        ];
      case _OrderFilter.all:
        return const <_OrderAction>[
          _OrderAction.outline(_OrderActionType.contactMerchant, '订单.联系商家'),
          _OrderAction.filled(_OrderActionType.viewDetail, '我的.查看详情'),
        ];
    }
  }

  static String _formatAmount(double amount) {
    final String value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '¥$value';
  }

  static String _formatTime(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '我的.时间未知'.tr() : raw;
    }
    final String year = parsed.year.toString();
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    final String hour = parsed.hour.toString().padLeft(2, '0');
    final String minute = parsed.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

extension _OrderFilterX on _OrderFilter {
  static _OrderFilter fromStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending_payment':
        return _OrderFilter.pendingPayment;
      case 'pending_upload':
        return _OrderFilter.pendingUpload;
      case 'completed':
        return _OrderFilter.completed;
      case 'processing':
      case 'reviewing':
      case 'rejected':
      case 'embassy_submitted':
        return _OrderFilter.processing;
      default:
        return _OrderFilter.all;
    }
  }
}

class _OrderAction {
  const _OrderAction._({
    required this.type,
    required this.label,
    required this.filled,
  });

  const _OrderAction.outline(_OrderActionType type, String label)
    : this._(type: type, label: label, filled: false);

  const _OrderAction.filled(_OrderActionType type, String label)
    : this._(type: type, label: label, filled: true);

  final _OrderActionType type;
  final String label;
  final bool filled;
}

class _OrderStatusTabs extends StatelessWidget {
  const _OrderStatusTabs({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<_OrderFilter> filters;
  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onSelected;

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
        children: filters.map((filter) {
          final isSelected = filter == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(filter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    filter.label.tr(),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF096DD9)
                          : const Color(0xFF262626),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Container(
                    width: 20,
                    height: 2,
                    color: isSelected
                        ? const Color(0xFF096DD9)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderStateView extends StatelessWidget {
  const _OrderStateView({required this.message, this.buttonLabel, this.onTap});

  final String message;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (buttonLabel == null && onTap == null) {
      return Center(
        child: AppEmptyState(
          message: message,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      );
    }

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
            if (buttonLabel != null && onTap != null) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(onPressed: onTap, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onActionTap,
    this.onTap,
  });

  final _OrderItem order;
  final Future<void> Function(_OrderItem order, _OrderAction action)
  onActionTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actionButtons = order.actions
        .map(
          (action) => _OrderActionButton(
            action: action,
            onPressed: () => onActionTap(order, action),
          ),
        )
        .toList();

    return SizedBox(
      height: order.hasProgress ? 258 : 202,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/my_orders_card_bg_blue.svg',
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.white.withValues(alpha: 0.96)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            order.timeText,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                            ),
                          ),
                          const Spacer(),
                          if (order.tagLabel != null && order.tagStyle != null)
                            _OrderTag(
                              label: order.tagLabel!,
                              style: order.tagStyle!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              order.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 22 / 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            order.price,
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 22 / 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _OrderMetaRow(
                        label: '订单.服务商'.tr(),
                        value: order.provider,
                      ),
                      const SizedBox(height: 4),
                      _OrderMetaRow(
                        label: '我的.套餐类型'.tr(),
                        value: order.packageType,
                      ),
                      const SizedBox(height: 4),
                      _OrderMetaRow(label: '我的.订单号'.tr(), value: order.orderNo),
                      if (order.hasProgress) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8EDF3)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: Color(0xFF096DD9),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.progressLabel!,
                                style: const TextStyle(
                                  color: Color(0xFF8C8C8C),
                                  fontSize: 12,
                                  height: 18 / 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.progressValue!,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 18 / 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          for (
                            var i = 0;
                            i < actionButtons.length;
                            i++
                          ) ...<Widget>[
                            if (i > 0) const SizedBox(width: 12),
                            actionButtons[i],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTag extends StatelessWidget {
  const _OrderTag({required this.label, required this.style});

  final String label;
  final _OrderTagStyle style;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = style == _OrderTagStyle.urgent
        ? const Color(0x14FF4D4F)
        : const Color(0x14096DD9);
    final foregroundColor = style == _OrderTagStyle.urgent
        ? const Color(0xFFFF4D4F)
        : const Color(0xFF096DD9);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 12 / 12,
        ),
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({required this.action, required this.onPressed});

  final _OrderAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isPayAction = action.type == _OrderActionType.goPay;
    final backgroundColor = action.filled
        ? (isPayAction ? const Color(0xFFFE5815) : const Color(0xFF096DD9))
        : Colors.white;
    final borderColor = action.filled
        ? (isPayAction ? const Color(0xFFFE5815) : const Color(0xFF096DD9))
        : const Color(0xFFD9D9D9);
    final foregroundColor = action.filled
        ? Colors.white
        : const Color(0xFF262626);

    return SizedBox(
      width: 77,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            action.label.tr(),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 12 / 12,
            ),
          ),
        ),
      ),
    );
  }
}
