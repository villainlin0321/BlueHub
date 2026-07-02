import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
class FinanceSettlementPage extends ConsumerStatefulWidget {
  const FinanceSettlementPage({super.key});

  @override
  ConsumerState<FinanceSettlementPage> createState() =>
      _FinanceSettlementPageState();
}

class _FinanceSettlementPageState extends ConsumerState<FinanceSettlementPage> {
  static const String _billDetailAsset =
      'assets/images/finance_settlement_bill_detail.svg';
  static const String _withdrawRecordAsset =
      'assets/images/finance_settlement_withdraw_record.svg';
  static const String _bankCardAsset =
      'assets/images/finance_settlement_bank_card.svg';
  static const String _transactionBillAsset =
      'assets/images/finance_settlement_transaction_bill.svg';

  static const List<_FinanceMenuItem> _menuItems = <_FinanceMenuItem>[
    _FinanceMenuItem(
      labelKey: '财务.账单明细',
      assetPath: _billDetailAsset,
      fallbackIcon: Icons.receipt_long_outlined,
    ),
    _FinanceMenuItem(
      labelKey: '财务.提现记录',
      assetPath: _withdrawRecordAsset,
      fallbackIcon: Icons.account_balance_wallet_outlined,
    ),
    _FinanceMenuItem(
      labelKey: '财务.银行卡管理',
      assetPath: _bankCardAsset,
      fallbackIcon: Icons.credit_card_outlined,
    ),
  ];

  ProviderFinanceOverviewVO? _overview;
  List<ProviderTransactionVO> _transactions = const <ProviderTransactionVO>[];
  List<ProviderBankCardVO> _bankCards = const <ProviderBankCardVO>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadFinanceData);
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.home);
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final financeService = ref.read(providerFinanceServiceProvider);
      final List<Object?> results =
          await Future.wait<Object?>(<Future<Object?>>[
            financeService.getOverview(),
            financeService.listTransactions(page: 1, pageSize: 20),
            financeService.listBankCards(),
          ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = results[0] as ProviderFinanceOverviewVO;
        _transactions =
            (results[1] as dynamic).list as List<ProviderTransactionVO>;
        _bankCards = results[2] as List<ProviderBankCardVO>;
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

  Future<void> _submitAddBankCard(AddBankCardBO request) async {
    await ref
        .read(providerFinanceServiceProvider)
        .addBankCard(request: request);
    if (!mounted) {
      return;
    }
    _showMessage('财务.添加成功'.tr());
    ref.read(financeRefreshTickProvider.notifier).bump();
  }

  Future<void> _submitWithdraw({
    required double amount,
    required int cardId,
  }) async {
    await ref
        .read(providerFinanceServiceProvider)
        .withdraw(
          request: WithdrawBO(amount: amount, cardId: cardId),
        );
    if (!mounted) {
      return;
    }
    _showMessage('财务.提现申请已提交'.tr());
    ref.read(financeRefreshTickProvider.notifier).bump();
  }

  Future<void> _handleMenuTap(String labelKey) async {
    switch (labelKey) {
      case '财务.账单明细':
        context.push(RoutePaths.financeTransactions);
        return;
      case '财务.提现记录':
        context.push(RoutePaths.financeWithdrawals);
        return;
      case '财务.银行卡管理':
        context.push(RoutePaths.financeBankCards);
        return;
    }
  }

  Future<void> _openAddBankCardSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _AddBankCardSheet(onSubmit: _submitAddBankCard),
        );
      },
    );
  }

  Future<void> _openWithdrawSheet() async {
    if (_overview == null) {
      _showMessage('财务.财务数据加载中'.tr());
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _WithdrawSheet(
            availableAmount: _overview!.availableAmount,
            currency: _overview!.currency,
            bankCards: _bankCards,
            onSubmit: _submitWithdraw,
            onAddBankCardTap: _openAddBankCardSheet,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(financeRefreshTickProvider, (int? previous, int next) {
      if (previous == next) {
        return;
      }
      _loadFinanceData();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () => _handleBack(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          '财务.财务结算'.tr(),
          style: TestStyle.pingFangSemibold(fontSize: 17, color: Color(0xE6000000)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _FinanceStateView(
        message: _errorMessage!,
        onRetry: _loadFinanceData,
      );
    }

    final ProviderFinanceOverviewVO overview =
        _overview ??
        const ProviderFinanceOverviewVO(
          availableAmount: 0,
          pendingAmount: 0,
          totalEarned: 0,
          currency: 'CNY',
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        _FinanceBalanceCard(
          availableAmount: _formatAmount(
            overview.availableAmount,
            overview.currency,
            withSymbol: false,
          ),
          pendingAmount: _formatAmount(
            overview.pendingAmount,
            overview.currency,
            withSymbol: false,
          ),
          totalEarned: _formatAmount(
            overview.totalEarned,
            overview.currency,
            withSymbol: false,
          ),
          onWithdrawTap: _openWithdrawSheet,
        ),
        const SizedBox(height: 12),
        _FinanceMenuCard(items: _menuItems, onItemTap: _handleMenuTap),
        const SizedBox(height: 12),
        _TransactionCard(
          transactionIconAsset: _transactionBillAsset,
          items: _transactions.take(4).toList(growable: false),
        ),
      ],
    );
  }
}

class _FinanceBalanceCard extends StatelessWidget {
  const _FinanceBalanceCard({
    required this.availableAmount,
    required this.pendingAmount,
    required this.totalEarned,
    required this.onWithdrawTap,
  });

  final String availableAmount;
  final String pendingAmount;
  final String totalEarned;
  final VoidCallback onWithdrawTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF4598F2), Color(0xFF2F73E5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        '财务.可提现余额元'.tr(),
                        style: TestStyle.pingFangRegular(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      availableAmount,
                      style: TestStyle.semibold(fontSize: 22, color: Colors.white),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onWithdrawTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(60, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: Text(
                  '财务.提现'.tr(),
                  style: TestStyle.pingFangMedium(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _BalanceValueBlock(
                  label: '财务.未到账元'.tr(),
                  value: pendingAmount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceValueBlock(
                  label: '财务.累计收入元'.tr(),
                  value: totalEarned,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceValueBlock extends StatelessWidget {
  const _BalanceValueBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Opacity(
          opacity: 0.8,
          child: Text(
            label,
            style: TestStyle.regular(fontSize: 12, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TestStyle.semibold(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class _FinanceMenuCard extends StatelessWidget {
  const _FinanceMenuCard({required this.items, required this.onItemTap});

  final List<_FinanceMenuItem> items;
  final Future<void> Function(String label) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: items
            .map(
              (_FinanceMenuItem item) => _FinanceMenuTile(
                item: item,
                onTap: () => onItemTap(item.labelKey),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FinanceMenuTile extends StatelessWidget {
  const _FinanceMenuTile({required this.item, required this.onTap});

  final _FinanceMenuItem item;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            AppSvgIcon(
              assetPath: item.assetPath,
              fallback: item.fallbackIcon,
              size: 24,
              color: const Color(0xFF262626),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.labelKey.tr(),
                style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFBFBFBF),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transactionIconAsset,
    required this.items,
  });

  final String transactionIconAsset;
  final List<ProviderTransactionVO> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '财务.最近交易'.tr(),
            style: TestStyle.pingFangMedium(fontSize: 16, color: Color(0xFF262626)),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _SheetEmptyState(message: '财务.暂无最近交易'.tr()),
            )
          else
            for (int index = 0; index < items.length; index++) ...<Widget>[
              _TransactionTile(
                item: items[index],
                transactionIconAsset: transactionIconAsset,
              ),
              if (index != items.length - 1)
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.transactionIconAsset,
  });

  final ProviderTransactionVO item;
  final String transactionIconAsset;

  @override
  Widget build(BuildContext context) {
    final bool isRefund = item.netAmount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          AppSvgIcon(
            assetPath: transactionIconAsset,
            fallback: Icons.receipt_long_rounded,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _buildTransactionTitle(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TestStyle.regular(fontSize: 14, color: Color(0xFF262626)),
                ),
                const SizedBox(height: 4),
                Text(
                  item.orderNo.trim().isEmpty
                      ? _mapTransactionType(item.txType)
                      : '财务.订单号前缀'.tr(
                          namedArgs: <String, String>{'orderNo': item.orderNo},
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _formatAmount(item.netAmount, item.currency),
                style: TestStyle.medium(fontSize: 14, color: isRefund
                      ? const Color(0xFFFF4D4F)
                      : const Color(0xFFFE5815)),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCompactDateTime(item.settledAt),
                style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStateView extends StatelessWidget {
  const _FinanceStateView({required this.message, required this.onRetry});

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
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

class _FinanceSheetScaffold extends StatelessWidget {
  const _FinanceSheetScaffold({
    required this.title,
    required this.child,
    this.bottomAction,
  });

  final String title;
  final Widget child;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double maxHeight =
        MediaQuery.sizeOf(context).height - topPadding - 12;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 56,
                  child: Stack(
                    children: <Widget>[
                      Align(
                        child: Text(
                          title,
                          style: TestStyle.semibold(fontSize: 16, color: Color(0xFF262626)),
                        ),
                      ),
                      Positioned(
                        top: 18,
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
                              color: Color(0xFF262626),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  ),
                ),
                if (bottomAction != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
                    child: bottomAction!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: AppEmptyState(
          message: message,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}

class _AddBankCardSheet extends StatefulWidget {
  const _AddBankCardSheet({required this.onSubmit});

  final Future<void> Function(AddBankCardBO request) onSubmit;

  @override
  State<_AddBankCardSheet> createState() => _AddBankCardSheetState();
}

class _AddBankCardSheetState extends State<_AddBankCardSheet> {
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
      setState(() => _errorMessage = '财务.请完整填写银行卡信息'.tr());
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
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceSheetScaffold(
      title: '财务.新增银行卡'.tr(),
      bottomAction: FilledButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: const Color(0xFF096DD9),
          disabledBackgroundColor: const Color(0xFF91CAFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(_isSubmitting ? '认证.提交中'.tr() : '财务.确认添加'.tr()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SheetTextField(
            controller: _bankNameController,
            label: '财务.银行名称'.tr(),
            hintText: '财务.银行名称示例'.tr(),
          ),
          const SizedBox(height: 12),
          _SheetTextField(
            controller: _cardHolderController,
            label: '财务.持卡人姓名'.tr(),
            hintText: '财务.请输入持卡人姓名'.tr(),
          ),
          const SizedBox(height: 12),
          _SheetTextField(
            controller: _cardNoMaskController,
            label: '财务.卡号掩码'.tr(),
            hintText: '财务.卡号掩码示例'.tr(),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _isDefault,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '财务.设为默认提现卡'.tr(),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF262626)),
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
                style: TestStyle.regular(fontSize: 12, color: Color(0xFFFF4D4F)),
              ),
            ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({
    required this.availableAmount,
    required this.currency,
    required this.bankCards,
    required this.onSubmit,
    required this.onAddBankCardTap,
  });

  final double availableAmount;
  final String currency;
  final List<ProviderBankCardVO> bankCards;
  final Future<void> Function({required double amount, required int cardId})
  onSubmit;
  final Future<void> Function() onAddBankCardTap;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  late final TextEditingController _amountController = TextEditingController();
  late int? _selectedCardId = _resolveDefaultCardId();
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _resolveDefaultCardId() {
    for (final ProviderBankCardVO card in widget.bankCards) {
      if (card.isDefault) {
        return card.cardId;
      }
    }
    return widget.bankCards.isEmpty ? null : widget.bankCards.first.cardId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }
    if (widget.bankCards.isEmpty || _selectedCardId == null) {
      setState(() => _errorMessage = '财务.请先添加银行卡'.tr());
      return;
    }
    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = '财务.请输入正确的提现金额'.tr());
      return;
    }
    if (amount > widget.availableAmount) {
      setState(() => _errorMessage = '财务.提现金额不能超过可提现余额'.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(amount: amount, cardId: _selectedCardId!);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  Future<void> _handleAddBankCard() async {
    Navigator.of(context).pop();
    await widget.onAddBankCardTap();
  }

  @override
  Widget build(BuildContext context) {
    return _FinanceSheetScaffold(
      title: '财务.申请提现'.tr(),
      bottomAction: FilledButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: const Color(0xFF096DD9),
          disabledBackgroundColor: const Color(0xFF91CAFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(_isSubmitting ? '认证.提交中'.tr() : '财务.确认提现'.tr()),
      ),
      child: widget.bankCards.isEmpty
          ? Column(
              children: <Widget>[
                _SheetEmptyState(message: '财务.暂未绑定银行卡请先新增银行卡'.tr()),
                OutlinedButton(
                  onPressed: _handleAddBankCard,
                  child: Text('财务.新增银行卡'.tr()),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '财务.可提现余额'.tr(
                      namedArgs: <String, String>{
                        'amount': _formatAmount(
                          widget.availableAmount,
                          widget.currency,
                        ),
                      },
                    ),
                    style: TestStyle.medium(fontSize: 14, color: Color(0xFF262626)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCardId,
                  decoration: InputDecoration(
                    labelText: '财务.提现银行卡'.tr(),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: widget.bankCards
                      .map(
                        (ProviderBankCardVO card) => DropdownMenuItem<int>(
                          value: card.cardId,
                          child: Text(
                            '${card.bankName} ${card.cardNoMask}'.trim(),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (int? value) {
                    setState(() => _selectedCardId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '财务.提现金额'.tr(),
                    hintText: '财务.请输入提现金额'.tr(),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _errorMessage!,
                      style: TestStyle.regular(fontSize: 12, color: Color(0xFFFF4D4F)),
                    ),
                  ),
              ],
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

class _FinanceMenuItem {
  const _FinanceMenuItem({
    required this.labelKey,
    required this.assetPath,
    required this.fallbackIcon,
  });

  final String labelKey;
  final String assetPath;
  final IconData fallbackIcon;
}

String _normalizeError(Object error) {
  if (error is ApiException) {
    final String message = error.message.trim();
    return message.isEmpty ? '财务.请求失败'.tr() : message;
  }
  final String message = error.toString().trim();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message.isEmpty ? '财务.请求失败'.tr() : message;
}

String _formatCurrencySymbol(String currency) {
  return switch (currency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'USD' => '\$',
    'EUR' => '€',
    _ => currency.trim().isEmpty ? '¥' : '${currency.trim()} ',
  };
}

String _formatAmount(num amount, String currency, {bool withSymbol = true}) {
  final String symbol = withSymbol ? _formatCurrencySymbol(currency) : '';
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

String _formatCompactDateTime(String raw) {
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

String _mapTransactionType(String txType) {
  return switch (txType.trim().toLowerCase()) {
    'income' => '财务.收入'.tr(),
    'refund' => '财务.退款冲销'.tr(),
    _ => txType.trim().isEmpty ? '财务.结算流水'.tr() : txType.trim(),
  };
}

String _buildTransactionTitle(ProviderTransactionVO item) {
  final String name = item.clientNameMasked.trim();
  final String type = item.txType.trim().toLowerCase();
  if (type == 'refund') {
    final String label = '财务.退款冲销'.tr();
    return name.isEmpty ? label : '$label-$name';
  }
  if (name.isEmpty) {
    return '财务.结算流水'.tr();
  }
  return '${'财务.结算订单'.tr()}-$name';
}
