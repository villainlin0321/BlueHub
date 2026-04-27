import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'service_detail_package_tab.dart';

class ServiceDetailApplyBottomSheet {
  const ServiceDetailApplyBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required String serviceTitle,
    required ServicePackageData package,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ApplyBottomSheetContent(
          parentContext: context,
          serviceTitle: serviceTitle,
          package: package,
        );
      },
    );
  }
}

class ServiceDetailConfirmPaymentBottomSheet {
  const ServiceDetailConfirmPaymentBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required String amountText,
    required BuildContext parentContext,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ConfirmPaymentBottomSheetContent(
          amountText: amountText,
          parentContext: parentContext,
        );
      },
    );
  }
}

class _ApplyBottomSheetContent extends StatefulWidget {
  const _ApplyBottomSheetContent({
    required this.parentContext,
    required this.serviceTitle,
    required this.package,
  });

  final BuildContext parentContext;
  final String serviceTitle;
  final ServicePackageData package;

  @override
  State<_ApplyBottomSheetContent> createState() =>
      _ApplyBottomSheetContentState();
}

class _ApplyBottomSheetContentState extends State<_ApplyBottomSheetContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '张先生');
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final maxSheetHeight = MediaQuery.sizeOf(context).height - topSafeArea - 12;

    return TapBlankToDismissKeyboard(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 64,
                        child: Stack(
                          children: <Widget>[
                            Align(
                              child: Text(
                                '确认订单信息',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF262626),
                                  fontSize: 18,
                                  height: 24 / 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Color(0xFF262626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(55.5, 0, 55.5, 34),
                        child: Text(
                          '提交后将生成订单，请在订单详情页上传相关材料',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFBFBFBF),
                            fontSize: 12,
                            height: 18 / 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _ApplyOrderSummaryCard(
                          serviceTitle: widget.serviceTitle,
                          package: widget.package,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                        child: _ApplyApplicantSection(
                          nameController: _nameController,
                          phoneController: _phoneController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafeArea),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
                  ),
                ),
                child: FilledButton(
                  onPressed: _handleGoPay,
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
                    '去支付',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoPay() {
    FocusScope.of(context).unfocus();
    final amountText = _formatPaymentAmount(widget.package.price);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServiceDetailConfirmPaymentBottomSheet.show(
        context: widget.parentContext,
        amountText: amountText,
        parentContext: widget.parentContext,
      );
    });
  }
}

class _ConfirmPaymentBottomSheetContent extends StatefulWidget {
  const _ConfirmPaymentBottomSheetContent({
    required this.amountText,
    required this.parentContext,
  });

  final String amountText;
  final BuildContext parentContext;

  @override
  State<_ConfirmPaymentBottomSheetContent> createState() =>
      _ConfirmPaymentBottomSheetContentState();
}

enum _PaymentMethod { alipay, wechat }

class _ConfirmPaymentBottomSheetContentState
    extends State<_ConfirmPaymentBottomSheetContent> {
  static const _tickDuration = Duration(seconds: 1);
  static const _initialDuration = Duration(minutes: 30);
  Timer? _timer;
  Duration _remaining = _initialDuration;
  _PaymentMethod _selectedMethod = _PaymentMethod.alipay;

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
    final theme = Theme.of(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

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
                        '确认支付',
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
                  amountText: widget.amountText,
                  remaining: _remaining,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                child: _PaymentMethodCard(
                  selectedMethod: _selectedMethod,
                  onSelected: (method) {
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
            onPressed: _handlePayNow,
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
              '立即支付',
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

  void _handlePayNow() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.parentContext.push(RoutePaths.serviceDetailPaymentResult);
    });
  }
}

class _PaymentAmountCard extends StatelessWidget {
  const _PaymentAmountCard({required this.amountText, required this.remaining});

  final String amountText;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountValue = amountText.replaceFirst('¥', '');
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
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
                    text: '¥',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFFFE5815),
                      fontSize: 20,
                      height: 28 / 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: amountValue,
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
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF262626),
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w400,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: '请在 '),
                  TextSpan(
                    text: minutes,
                    style: const TextStyle(
                      color: Color(0xFFFE5815),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: '分钟',
                    style: TextStyle(color: Color(0xFFFE5815)),
                  ),
                  TextSpan(
                    text: seconds,
                    style: const TextStyle(
                      color: Color(0xFFFE5815),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: '秒',
                    style: TextStyle(color: Color(0xFFFE5815)),
                  ),
                  const TextSpan(text: ' 内支付，过时将被取消'),
                ],
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

  final _PaymentMethod selectedMethod;
  final ValueChanged<_PaymentMethod> onSelected;

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
              label: '支付宝支付',
              logoAsset: 'assets/images/service_detail_payment_alipay_logo.png',
              selected: selectedMethod == _PaymentMethod.alipay,
              showDivider: true,
              onTap: () => onSelected(_PaymentMethod.alipay),
            ),
            _PaymentMethodRow(
              label: '微信支付',
              logoAsset: 'assets/images/service_detail_payment_wechat_logo.png',
              selected: selectedMethod == _PaymentMethod.wechat,
              showDivider: false,
              onTap: () => onSelected(_PaymentMethod.wechat),
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
    final theme = Theme.of(context);
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

class _ApplyOrderSummaryCard extends StatelessWidget {
  const _ApplyOrderSummaryCard({
    required this.serviceTitle,
    required this.package,
  });

  final String serviceTitle;
  final ServicePackageData package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            serviceTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ApplySummaryRow(label: '套餐类型', value: package.title),
          const SizedBox(height: 4),
          _ApplySummaryRow(
            label: '预计费用',
            value: package.price,
            valueColor: const Color(0xFFFE5815),
          ),
          const SizedBox(height: 12),
          Text(
            '提示：当前仅为提交申请，需先上传材料供服务商审核，审核通过后方可支付。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplySummaryRow extends StatelessWidget {
  const _ApplySummaryRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF262626),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF595959),
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ApplyApplicantSection extends StatelessWidget {
  const _ApplyApplicantSection({
    required this.nameController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '申请人信息',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ApplyLabeledInput(
          label: '姓名',
          controller: nameController,
          textColor: const Color(0xFF262626),
          hintText: '',
        ),
        const SizedBox(height: 12),
        _ApplyLabeledInput(
          label: '手机号',
          controller: phoneController,
          hintText: '请输入',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

class _ApplyLabeledInput extends StatelessWidget {
  const _ApplyLabeledInput({
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textColor = const Color(0xFF262626),
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );

    return SizedBox(
      height: 48,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 14,
            child: IgnorePointer(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8C8C8C),
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              cursorColor: const Color(0xFF096DD9),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                hintText: hintText.isEmpty ? null : hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFBFBFBF),
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.fromLTRB(104, 14, 16, 14),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                disabledBorder: border,
                errorBorder: border,
                focusedErrorBorder: border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPaymentAmount(String priceText) {
  final numericText = priceText.replaceAll(RegExp(r'[^0-9.]'), '');
  if (numericText.isEmpty) {
    return '¥0.00';
  }
  final amount = double.tryParse(numericText.replaceAll(',', '')) ?? 0;
  final hasDecimals = numericText.contains('.');
  final formatted = hasDecimals
      ? amount.toStringAsFixed(2)
      : amount.toStringAsFixed(2);
  final parts = formatted.split('.');
  final integerPart = parts.first;
  final decimalPart = parts.last;
  final groupedInteger = integerPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '¥$groupedInteger.$decimalPart';
}
