import 'package:flutter/material.dart';

import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../data/finance_models.dart';

class FinanceStateView extends StatelessWidget {
  const FinanceStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
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
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState(
        message: message,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      ),
    );
  }
}

class FinanceStatusBadge extends StatelessWidget {
  const FinanceStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x14096DD9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF096DD9),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class FinanceTransactionTile extends StatelessWidget {
  const FinanceTransactionTile({
    super.key,
    required this.item,
    required this.transactionIconAsset,
  });

  final ProviderTransactionVO item;
  final String transactionIconAsset;

  @override
  Widget build(BuildContext context) {
    final bool isRefund = item.netAmount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: <Widget>[
          _FinanceLeadingIcon(
            assetPath: transactionIconAsset,
            fallbackIcon: Icons.receipt_long_rounded,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  buildFinanceTransactionTitle(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.orderNo.trim().isEmpty
                      ? mapFinanceTransactionType(item.txType)
                      : '订单号: ${item.orderNo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatFinanceAmount(item.netAmount, item.currency),
                style: TextStyle(
                  color: isRefund
                      ? const Color(0xFFFF4D4F)
                      : const Color(0xFFFE5815),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatFinanceCompactDateTime(item.settledAt),
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinanceWithdrawalTile extends StatelessWidget {
  const FinanceWithdrawalTile({super.key, required this.item});

  final ProviderWithdrawalVO item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${item.bankName} ${item.cardNoMask}'.trim(),
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FinanceStatusBadge(
                label: mapFinanceWithdrawalStatus(item.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatFinanceAmount(item.amount, item.currency),
            style: const TextStyle(
              color: Color(0xFFFE5815),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '申请时间：${formatFinanceDetailDateTime(item.appliedAt)}',
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
          if (item.processedAt.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              '处理时间：${formatFinanceDetailDateTime(item.processedAt)}',
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ],
          if (item.remark.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              '备注：${item.remark}',
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceBankCardTile extends StatelessWidget {
  const FinanceBankCardTile({super.key, required this.item, this.onDelete});

  final ProviderBankCardVO item;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${item.bankName} ${item.cardNoMask}'.trim(),
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                  ),
                ),
              ),
              if (item.isDefault) const FinanceStatusBadge(label: '默认卡'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '持卡人：${item.cardHolder}',
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '绑定时间：${formatFinanceDetailDateTime(item.createdAt)}',
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
          if (onDelete != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFFFF4D4F),
                ),
                child: const Text(
                  '删除',
                  style: TextStyle(
                    color: Color(0xFFFF4D4F),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 18 / 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceAddBankCardSheet extends StatefulWidget {
  const FinanceAddBankCardSheet({super.key, required this.onSubmit});

  final Future<void> Function(AddBankCardBO request) onSubmit;

  @override
  State<FinanceAddBankCardSheet> createState() =>
      _FinanceAddBankCardSheetState();
}

class _FinanceAddBankCardSheetState extends State<FinanceAddBankCardSheet> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _cardNoMaskController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNoMaskController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }
    final String bankName = _bankNameController.text.trim();
    final String cardNoMask = _cardNoMaskController.text.trim();
    final String cardHolder = _cardHolderController.text.trim();
    if (bankName.isEmpty || cardNoMask.isEmpty || cardHolder.isEmpty) {
      setState(() => _errorMessage = '请完整填写银行卡信息');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(
        AddBankCardBO(
          bankName: bankName,
          cardNoMask: cardNoMask,
          cardHolder: cardHolder,
          isDefault: _isDefault,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = normalizeFinanceError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      '新增银行卡',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF262626),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SheetTextField(
                controller: _bankNameController,
                label: '银行名称',
                hintText: '例如：中国工商银行',
              ),
              const SizedBox(height: 12),
              _SheetTextField(
                controller: _cardHolderController,
                label: '持卡人姓名',
                hintText: '请输入持卡人姓名',
              ),
              const SizedBox(height: 12),
              _SheetTextField(
                controller: _cardNoMaskController,
                label: '卡号掩码',
                hintText: '例如：**** 1234',
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isDefault,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '设为默认提现卡',
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                onChanged: (bool value) {
                  setState(() => _isDefault = value);
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFFF4D4F),
                      fontSize: 12,
                      height: 18 / 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  disabledBackgroundColor: const Color(0xFF91CAFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(_isSubmitting ? '提交中...' : '确认添加'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _FinanceLeadingIcon extends StatelessWidget {
  const _FinanceLeadingIcon({
    required this.assetPath,
    required this.fallbackIcon,
    required this.size,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon(
      assetPath: assetPath,
      fallback: fallbackIcon,
      size: size,
      color: const Color(0xFF8C8C8C),
    );
  }
}

String normalizeFinanceError(Object error) {
  if (error is ApiException) {
    final String message = error.message.trim();
    return message.isEmpty ? '请求失败，请稍后重试' : message;
  }
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message.isEmpty ? '请求失败，请稍后重试' : message;
}

String formatFinanceCurrencySymbol(String currency) {
  return switch (currency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'USD' => '\$',
    'EUR' => '€',
    _ => currency.trim().isEmpty ? '¥' : '${currency.trim()} ',
  };
}

String formatFinanceAmount(
  num amount,
  String currency, {
  bool withSymbol = true,
}) {
  final String symbol = withSymbol ? formatFinanceCurrencySymbol(currency) : '';
  final bool isNegative = amount < 0;
  final num absAmount = amount.abs();
  String text = absAmount % 1 == 0
      ? absAmount.toStringAsFixed(0)
      : absAmount
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  final List<String> parts = text.split('.');
  parts[0] = _addThousandsSeparator(parts[0]);
  text = parts.join('.');
  final String sign = isNegative ? '-' : '';
  return '$sign$symbol$text';
}

String _addThousandsSeparator(String digits) {
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    final int reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String formatFinanceCompactDateTime(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.isEmpty ? '--' : raw;
  }
  final DateTime value = parsed.toLocal();
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  final String second = value.second.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute:$second';
}

String formatFinanceDetailDateTime(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.isEmpty ? '--' : raw;
  }
  final DateTime value = parsed.toLocal();
  final String year = value.year.toString();
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

String mapFinanceWithdrawalStatus(String status) {
  return switch (status.trim().toLowerCase()) {
    'pending' => '待处理',
    'success' => '已打款',
    'failed' => '失败',
    _ => status.trim().isEmpty ? '未知状态' : status.trim(),
  };
}

String mapFinanceTransactionType(String txType) {
  return switch (txType.trim().toLowerCase()) {
    'income' => '收入',
    'refund' => '退款冲销',
    _ => txType.trim().isEmpty ? '结算流水' : txType.trim(),
  };
}

String buildFinanceTransactionTitle(ProviderTransactionVO item) {
  final String name = item.clientNameMasked.trim();
  final String type = item.txType.trim().toLowerCase();
  if (type == 'refund') {
    return name.isEmpty ? '退款冲销' : '退款冲销-$name';
  }
  if (name.isEmpty) {
    return '结算流水';
  }
  return '结算订单-$name';
}
