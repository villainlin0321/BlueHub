import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_toast.dart';

import '../data/finance_models.dart';
import '../data/finance_providers.dart';
import '../../../shared/widgets/app_dialog.dart';
import 'finance_page_shared.dart';

class FinanceBankCardsPage extends ConsumerStatefulWidget {
  const FinanceBankCardsPage({super.key});

  @override
  ConsumerState<FinanceBankCardsPage> createState() =>
      _FinanceBankCardsPageState();
}

class _FinanceBankCardsPageState extends ConsumerState<FinanceBankCardsPage> {
  List<ProviderBankCardVO> _items = const <ProviderBankCardVO>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_refresh);
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<ProviderBankCardVO> result = await ref
          .read(providerFinanceServiceProvider)
          .listBankCards();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = normalizeFinanceError(error);
      });
    }
  }

  /// 打开新增银行卡弹窗，提交成功后刷新列表并同步财务页数据。
  Future<void> _openAddBankCardSheet() async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FinanceAddBankCardSheet(
          onSubmit: (AddBankCardBO request) async {
            await ref
                .read(providerFinanceServiceProvider)
                .addBankCard(request: request);
            if (!mounted) {
              return;
            }
            _showMessage('财务.添加成功'.tr());
            ref.read(financeRefreshTickProvider.notifier).bump();
          },
        );
      },
    );
    if (added == true) {
      await _refresh();
    }
  }

  /// 删除前先做二次确认，避免误删默认银行卡。
  Future<bool> _confirmDeleteBankCard(ProviderBankCardVO card) async {
    final String label = '${card.bankName} ${card.cardNoMask}'.trim();
    return showAppConfirmDialog(
      context: context,
      title: '财务.删除银行卡'.tr(),
      message: '财务.确认删除银行卡'.tr(namedArgs: <String, String>{'label': label}),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '财务.删除'.tr(),
    );
  }

  Future<void> _deleteBankCard(ProviderBankCardVO card) async {
    final bool confirmed = await _confirmDeleteBankCard(card);
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await ref
          .read(providerFinanceServiceProvider)
          .deleteBankCard(cardId: card.cardId);
      if (!mounted) {
        return;
      }
      _showMessage('财务.删除成功'.tr());
      ref.read(financeRefreshTickProvider.notifier).bump();
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(normalizeFinanceError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          '财务.银行卡管理'.tr(),
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _openAddBankCardSheet,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF096DD9),
                disabledBackgroundColor: const Color(0xFFD9D9D9),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                '财务.新增银行卡'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
          ),
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
      return FinanceStateView(message: _errorMessage!, onRetry: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _items.isEmpty ? 1 : _items.length,
        separatorBuilder: (_, int index) {
          if (_items.isEmpty || index == _items.length - 1) {
            return const SizedBox.shrink();
          }
          return const Divider(height: 1, color: Color(0xFFF0F0F0));
        },
        itemBuilder: (BuildContext context, int index) {
          if (_items.isEmpty) {
            return SizedBox(
              height: 300,
              child: FinanceEmptyState(message: '财务.暂未绑定银行卡'.tr()),
            );
          }
          final ProviderBankCardVO card = _items[index];
          return Container(
            color: Colors.white,
            child: FinanceBankCardTile(
              item: card,
              onDelete: () => _deleteBankCard(card),
            ),
          );
        },
      ),
    );
  }
}
