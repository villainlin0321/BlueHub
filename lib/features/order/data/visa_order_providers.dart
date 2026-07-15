import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import '../../../shared/network/services/visa_order_service.dart';

final visaOrderServiceProvider = Provider<VisaOrderService>((ref) {
  return VisaOrderService(apiClient: ref.watch(apiClientProvider));
});

/// 订单刷新信号：订单支付或状态变更成功后递增，供订单列表统一刷新。
final orderRefreshTickProvider =
    NotifierProvider<OrderRefreshTickNotifier, int>(
      OrderRefreshTickNotifier.new,
    );

class OrderRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}
