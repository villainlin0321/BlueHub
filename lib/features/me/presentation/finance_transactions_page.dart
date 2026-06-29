import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../shared/network/page_result.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';
import 'finance_page_shared.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
class FinanceTransactionsPage extends ConsumerStatefulWidget {
  const FinanceTransactionsPage({super.key});

  @override
  ConsumerState<FinanceTransactionsPage> createState() =>
      _FinanceTransactionsPageState();
}

class _FinanceTransactionsPageState
    extends ConsumerState<FinanceTransactionsPage> {
  static const String _transactionBillAsset =
      'assets/images/finance_settlement_transaction_bill.svg';

  final ScrollController _scrollController = ScrollController();
  List<ProviderTransactionVO> _items = const <ProviderTransactionVO>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasNext = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    Future<void>.microtask(_refresh);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 120) {
      return;
    }
    _loadMore();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final PageResult<ProviderTransactionVO> result = await ref
          .read(providerFinanceServiceProvider)
          .listTransactions(page: 1, pageSize: 20);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = result.list;
        _page = result.pagination.page;
        _hasNext = result.pagination.hasNext;
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

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasNext) {
      return;
    }
    setState(() => _isLoadingMore = true);
    try {
      final PageResult<ProviderTransactionVO> result = await ref
          .read(providerFinanceServiceProvider)
          .listTransactions(page: _page + 1, pageSize: 20);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = <ProviderTransactionVO>[..._items, ...result.list];
        _page = result.pagination.page;
        _hasNext = result.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      AppToast.show(normalizeFinanceError(error));
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
          '财务.账单明细'.tr(),
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
      return FinanceStateView(message: _errorMessage!, onRetry: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _items.isEmpty ? 1 : _items.length + 1,
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
              child: FinanceEmptyState(message: '财务.暂无账单明细'.tr()),
            );
          }
          if (index == _items.length) {
            return _LoadMoreFooter(
              isLoadingMore: _isLoadingMore,
              hasNext: _hasNext,
            );
          }
          return Container(
            color: Colors.white,
            child: FinanceTransactionTile(
              item: _items[index],
              transactionIconAsset: _transactionBillAsset,
            ),
          );
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.isLoadingMore, required this.hasNext});

  final bool isLoadingMore;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final String text = isLoadingMore
        ? '财务.加载中'.tr()
        : hasNext
        ? '财务.上滑加载更多'.tr()
        : '财务.没有更多了'.tr();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
        ),
      ),
    );
  }
}
