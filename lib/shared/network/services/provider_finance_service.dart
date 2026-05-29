import 'package:bluehub_app/features/me/data/finance_models.dart';
import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

class ProviderFinanceService {
  ProviderFinanceService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取服务商财务概览。
  Future<ProviderFinanceOverviewVO> getOverview() async {
    final response = await _apiClient.get<ProviderFinanceOverviewVO>(
      '/provider/finance/overview',
      decode: (data) => ProviderFinanceOverviewVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 获取服务商结算流水列表。
  Future<PageResult<ProviderTransactionVO>> listTransactions({
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<ProviderTransactionVO>>(
      '/provider/finance/transactions',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<ProviderTransactionVO>.fromJson(
        asJsonMap(data),
        fromJson: ProviderTransactionVO.fromJson,
      ),
    );
    return response;
  }

  /// 获取服务商提现记录列表。
  Future<PageResult<ProviderWithdrawalVO>> listWithdrawals({
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<ProviderWithdrawalVO>>(
      '/provider/finance/withdrawals',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<ProviderWithdrawalVO>.fromJson(
        asJsonMap(data),
        fromJson: ProviderWithdrawalVO.fromJson,
      ),
    );
    return response;
  }

  /// 获取服务商已绑定银行卡列表。
  Future<List<ProviderBankCardVO>> listBankCards() async {
    final response = await _apiClient.get<List<ProviderBankCardVO>>(
      '/provider/finance/bank-cards',
      decode: (data) => decodeModelList<ProviderBankCardVO>(
        data,
        ProviderBankCardVO.fromJson,
      ),
    );
    return response;
  }

  /// 添加服务商银行卡。
  Future<void> addBankCard({required AddBankCardBO request}) async {
    return _apiClient.postVoid(
      '/provider/finance/bank-cards',
      data: request.toJson(),
    );
  }

  /// 删除服务商银行卡。
  Future<void> deleteBankCard({required int cardId}) async {
    return _apiClient.deleteVoid('/provider/finance/bank-cards/$cardId');
  }

  /// 提交提现申请。
  Future<void> withdraw({required WithdrawBO request}) async {
    return _apiClient.postVoid(
      '/provider/finance/withdraw',
      data: request.toJson(),
    );
  }
}
