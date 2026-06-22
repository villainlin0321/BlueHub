import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/models/app_currency.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../service_detail/presentation/app_result_page.dart';
import '../application/payment/payment_flow_coordinator.dart';
import '../data/payment_providers.dart';

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
                child: _PaymentAmountCard(
                  amount: widget.amount,
                  currency: widget.currency,
                  remaining: _remaining,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                child: _PaymentMethodCard(
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
      final PaymentFlowResult result = await ref
          .read(paymentFlowCoordinatorProvider)
          .startPayment(orderId: widget.orderId, method: _selectedMethod);
      if (!mounted) {
        return;
      }
      switch (result.status) {
        case PaymentFlowStatus.success:
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!widget.parentContext.mounted) {
              return;
            }
            await widget.parentContext.push(
              RoutePaths.appResult,
              extra: AppResultPageArgs.paymentSuccess(orderId: widget.orderId),
            );
            if (widget.onFlowCompleted != null &&
                widget.parentContext.mounted) {
              await widget.onFlowCompleted!.call();
            }
          });
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
      _showMessage(_resolvePaymentErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }
}

class _PaymentAmountCard extends StatelessWidget {
  const _PaymentAmountCard({
    required this.amount,
    required this.currency,
    required this.remaining,
  });

  final double amount;
  final String? currency;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ({String symbol, String value}) amountParts =
        AppCurrency.buildAmountParts(
          amount,
          currency,
          fractionDigitsWhenNeeded: 2,
          trimTrailingZeros: false,
        );
    final String minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: amountParts.symbol,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFE5815),
                      fontSize: 20,
                      height: 28 / 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: amountParts.value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFE5815),
                      fontSize: 24,
                      height: 28 / 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '服务详情.支付倒计时'.tr(
                namedArgs: <String, String>{
                  'minutes': minutes,
                  'seconds': seconds,
                },
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF262626),
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.selectedMethod,
    required this.onSelected,
  });

  final AppPaymentMethod selectedMethod;
  final ValueChanged<AppPaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
        child: Column(
          children: <Widget>[
            _PaymentMethodRow(
              label: '服务详情.支付宝支付'.tr(),
              logoAsset: 'assets/images/service_detail_payment_alipay_logo.png',
              selected: selectedMethod == AppPaymentMethod.alipay,
              showDivider: true,
              onTap: () => onSelected(AppPaymentMethod.alipay),
            ),
            _PaymentMethodRow(
              label: '服务详情.微信支付'.tr(),
              logoAsset: 'assets/images/service_detail_payment_wechat_logo.png',
              selected: selectedMethod == AppPaymentMethod.wechat,
              showDivider: false,
              onTap: () => onSelected(AppPaymentMethod.wechat),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.label,
    required this.logoAsset,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final String label;
  final String logoAsset;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
              )
            : null,
      ),
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                _PaymentRadio(selected: selected),
                const SizedBox(width: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentRadio extends StatelessWidget {
  const _PaymentRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFBFBF), width: 1.8),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF096DD9),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }
}

String _resolvePaymentErrorMessage(Object error) {
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  if (message.isNotEmpty) {
    return message;
  }
  return '服务详情.支付发起失败'.tr();
}
