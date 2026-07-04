import '../../../shared/widgets/app_toast.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../order/data/visa_order_models.dart';
import '../../order/data/visa_order_providers.dart';
import '../../order/presentation/order_payment_bottom_sheet.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'service_detail_package_tab.dart';

class ServiceDetailApplyBottomSheet {
  const ServiceDetailApplyBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required String serviceTitle,
    required ServicePackageData package,
  }) async {
    await _showServiceDetailBottomSheet(
      context: context,
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
    required double amount,
    required String? currency,
    required int orderId,
    required String packageName,
    required BuildContext parentContext,
  }) async {
    await OrderPaymentBottomSheet.show(
      context: context,
      amount: amount,
      currency: currency,
      orderId: orderId,
      packageName: packageName,
      parentContext: parentContext,
    );
  }
}

Future<void> _showServiceDetailBottomSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => builder(sheetContext),
  );
}

class _ApplyBottomSheetContent extends ConsumerStatefulWidget {
  const _ApplyBottomSheetContent({
    required this.parentContext,
    required this.serviceTitle,
    required this.package,
  });

  final BuildContext parentContext;
  final String serviceTitle;
  final ServicePackageData package;

  @override
  ConsumerState<_ApplyBottomSheetContent> createState() =>
      _ApplyBottomSheetContentState();
}

class _ApplyBottomSheetContentState
    extends ConsumerState<_ApplyBottomSheetContent> with WidgetsBindingObserver {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _phoneFocusNode;
  bool _isSubmitting = false;
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _nameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
      final bool keyboardJustClosed =
          _lastKeyboardInset > 0 && keyboardInset == 0;
      _lastKeyboardInset = keyboardInset;
      if (!keyboardJustClosed) {
        return;
      }
      if (_nameFocusNode.hasFocus || _phoneFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final maxSheetHeight = MediaQuery.sizeOf(context).height - topSafeArea - 12;

    return TapBlankToDismissKeyboard(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
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
                                  '服务详情.确认订单信息'.tr(),
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
                            '服务详情.下单提示'.tr(),
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
                            nameFocusNode: _nameFocusNode,
                            phoneFocusNode: _phoneFocusNode,
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
                            onPressed: _isSubmitting ? null : _handleGoPay,
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
                              _isSubmitting ? '服务详情.提交中'.tr() : '服务详情.去支付'.tr(),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoPay() async {
    if (_isSubmitting) {
      return;
    }
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      _showMessage('通用.请输入姓名'.tr());
      return;
    }
    if (phone.isEmpty) {
      _showMessage('通用.请输入手机号'.tr());
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final order = await ref
          .read(visaOrderServiceProvider)
          .createOrder(
            request: CreateVisaOrderBO(
              packageId: widget.package.packageId,
              tierId: widget.package.tierId,
            ),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.parentContext.mounted) {
          return;
        }
        ServiceDetailConfirmPaymentBottomSheet.show(
          context: widget.parentContext,
          amount: widget.package.amount,
          currency: widget.package.currency,
          orderId: order.orderId,
          packageName: widget.package.title,
          parentContext: widget.parentContext,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showMessage(
        _resolveBottomSheetErrorMessage(error, fallback: '服务详情.创建订单失败'.tr()),
      );
    }
  }

  void _showMessage(String message) {
    AppToast.show(message);
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
          _ApplySummaryRow(label: '服务详情.套餐类型'.tr(), value: package.title),
          const SizedBox(height: 4),
          _ApplySummaryRow(
            label: '服务详情.预计费用'.tr(),
            value: package.price,
            valueColor: const Color(0xFFFE5815),
          ),
          const SizedBox(height: 12),
          Text(
            '服务详情.下单说明'.tr(),
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
    required this.nameFocusNode,
    required this.phoneFocusNode,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final FocusNode nameFocusNode;
  final FocusNode phoneFocusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '服务详情.申请人信息'.tr(),
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
          label: '服务详情.姓名'.tr(),
          controller: nameController,
          focusNode: nameFocusNode,
          textColor: const Color(0xFF262626),
          hintText: '通用.请输入'.tr(),
        ),
        const SizedBox(height: 12),
        _ApplyLabeledInput(
          label: '认证.手机号'.tr(),
          controller: phoneController,
          focusNode: phoneFocusNode,
          hintText: '通用.请输入'.tr(),
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
    required this.focusNode,
    required this.hintText,
    this.keyboardType,
    this.textColor = const Color(0xFF262626),
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
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
              focusNode: focusNode,
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

String _resolveBottomSheetErrorMessage(
  Object error, {
  required String fallback,
}) {
  if (error is ApiException) {
    return error.message;
  }
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message.isEmpty ? fallback : message;
}
