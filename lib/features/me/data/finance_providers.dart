import 'package:bluehub_app/shared/network/providers.dart';
import 'package:bluehub_app/shared/network/services/provider_finance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final providerFinanceServiceProvider = Provider<ProviderFinanceService>((ref) {
  return ProviderFinanceService(apiClient: ref.watch(apiClientProvider));
});

/// 财务数据刷新信号：提现或银行卡变更成功后递增，供财务页统一重拉接口。
final financeRefreshTickProvider =
    NotifierProvider<FinanceRefreshTickNotifier, int>(
      FinanceRefreshTickNotifier.new,
    );

class FinanceRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}
