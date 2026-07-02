import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/visa_order_providers.dart';
import '../../service_detail/presentation/app_result_page.dart';
import '../application/payment/payment_flow_coordinator.dart';
import '../data/payment_providers.dart';
import 'order_payment_widgets.dart';

class OrderPaymentBottomSheet {
  const OrderPaymentBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required double amount,
    required String? currency,
    required int orderId,
    required String packageName,
    required BuildContext parentContext,
    Future<void> Function()? onFlowCompleted,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _OrderPaymentBottomSheetContent(
          amount: amount,
          currency: currency,
          orderId: orderId,
          packageName: packageName,
          parentContext: parentContext,
          onFlowCompleted: onFlowCompleted,
        );
      },
    );
  }
}

class _OrderPaymentBottomSheetContent extends ConsumerStatefulWidget {
  const _OrderPaymentBottomSheetContent({
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.packageName,
    required this.parentContext,
    this.onFlowCompleted,
  });

  final double amount;
  final String? currency;
  final int orderId;
  final String packageName;
  final BuildContext parentContext;
  final Future<void> Function()? onFlowCompleted;

  @override
  ConsumerState<_OrderPaymentBottomSheetContent> createState() =>
      _OrderPaymentBottomSheetContentState();
}

class _OrderPaymentBottomSheetContentState
    extends ConsumerState<_OrderPaymentBottomSheetContent> {
  static const Duration _tickDuration = Duration(seconds: 1);
  static const Duration _initialDuration = Duration(minutes: 30);

  Timer? _timer;
  Duration _remaining = _initialDuration;
  AppPaymentMethod _selectedMethod = AppPaymentMethod.alipay;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tickDuration, (_) {
      if (!mounted) {
        return;
      }
      if (_remaining.inSeconds <= 1) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= _tickDuration);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F6F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 52,
                child: Stack(
                  children: <Widget>[
                    Align(
                      child: Text(
                        '服务详情.确认支付'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF171A1D),
                          fontSize: 17,
                          height: 25 / 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF171A1D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                child: OrderPaymentAmountCard(
                  amount: widget.amount,
                  currency: widget.currency,
                  remaining: _remaining,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                child: OrderPaymentMethodCard(
                  selectedMethod: _selectedMethod,
                  onSelected: (AppPaymentMethod method) {
                    setState(() => _selectedMethod = method);
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafeArea),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
            ),
          ),
          child: FilledButton(
            onPressed: _isPaying ? null : _handlePayNow,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: const Color(0xFF096DD9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              _isPaying ? '服务详情.支付中'.tr() : '服务详情.立即支付'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayNow() async {
    if (_isPaying) {
      return;
    }
    setState(() => _isPaying = true);
    try {
      if (_selectedMethod == AppPaymentMethod.wechat) {
        // Temporary fallback: backend directly marks the order as paid for WeChat.
        await ref
            .read(visaOrderServiceProvider)
            .payOrder(orderId: widget.orderId);
        if (!mounted) {
          return;
        }
        _handlePaymentSuccess();
        return;
      }
      final PaymentFlowResult result = await ref
          .read(paymentFlowCoordinatorProvider)
          .startPayment(orderId: widget.orderId, method: _selectedMethod);
      if (!mounted) {
        return;
      }
      switch (result.status) {
        case PaymentFlowStatus.success:
          _handlePaymentSuccess();
          return;
        case PaymentFlowStatus.cancel:
        case PaymentFlowStatus.failed:
        case PaymentFlowStatus.pending:
          setState(() => _isPaying = false);
          _showMessage(result.message);
          return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isPaying = false);
      _showMessage(resolveOrderPaymentErrorMessage(error));
    }
  }

  void _handlePaymentSuccess() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.parentContext.mounted) {
        return;
      }
      await widget.parentContext.push(
        RoutePaths.appResult,
        extra: AppResultPageArgs.paymentSuccess(orderId: widget.orderId),
      );
      if (widget.onFlowCompleted != null && widget.parentContext.mounted) {
        await widget.onFlowCompleted!.call();
      }
    });
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }
}
