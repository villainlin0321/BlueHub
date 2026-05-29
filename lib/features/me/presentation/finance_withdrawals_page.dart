import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/page_result.dart';
import '../data/finance_models.dart';
import '../data/finance_providers.dart';
import 'finance_page_shared.dart';

class FinanceWithdrawalsPage extends ConsumerStatefulWidget {
  const FinanceWithdrawalsPage({super.key});

  @override
  ConsumerState<FinanceWithdrawalsPage> createState() =>
      _FinanceWithdrawalsPageState();
}

class _FinanceWithdrawalsPageState
    extends ConsumerState<FinanceWithdrawalsPage> {
  final ScrollController _scrollController = ScrollController();
  List<ProviderWithdrawalVO> _items = const <ProviderWithdrawalVO>[];
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
      final PageResult<ProviderWithdrawalVO> result = await ref
          .read(providerFinanceServiceProvider)
          .listWithdrawals(page: 1, pageSize: 20);
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
      final PageResult<ProviderWithdrawalVO> result = await ref
          .read(providerFinanceServiceProvider)
          .listWithdrawals(page: _page + 1, pageSize: 20);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = <ProviderWithdrawalVO>[..._items, ...result.list];
        _page = result.pagination.page;
        _hasNext = result.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(normalizeFinanceError(error))),
      );
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
        title: const Text(
          '提现记录',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w600,
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
            return const SizedBox(
              height: 300,
              child: FinanceEmptyState(message: '暂无提现记录'),
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
            child: FinanceWithdrawalTile(item: _items[index]),
          );
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoadingMore,
    required this.hasNext,
  });

  final bool isLoadingMore;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final String text = isLoadingMore
        ? '加载中...'
        : hasNext
        ? '上滑加载更多'
        : '没有更多了';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 12,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }
}
