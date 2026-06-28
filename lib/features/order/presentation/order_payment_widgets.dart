import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/app_currency.dart';
import '../application/payment/payment_flow_coordinator.dart';

class OrderPaymentAmountCard extends StatelessWidget {
  const OrderPaymentAmountCard({
    super.key,
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

class OrderPaymentMethodCard extends StatelessWidget {
  const OrderPaymentMethodCard({
    super.key,
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
            _OrderPaymentMethodRow(
              label: '服务详情.支付宝支付'.tr(),
              logoAsset: 'assets/images/service_detail_payment_alipay_logo.png',
              selected: selectedMethod == AppPaymentMethod.alipay,
              showDivider: true,
              onTap: () => onSelected(AppPaymentMethod.alipay),
            ),
            _OrderPaymentMethodRow(
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

class _OrderPaymentMethodRow extends StatelessWidget {
  const _OrderPaymentMethodRow({
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
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
                _OrderPaymentRadio(selected: selected),
                const SizedBox(width: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderPaymentRadio extends StatelessWidget {
  const _OrderPaymentRadio({required this.selected});

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

String resolveOrderPaymentErrorMessage(Object error) {
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  if (message.isNotEmpty) {
    return message;
  }
  return '服务详情.支付发起失败'.tr();
}
