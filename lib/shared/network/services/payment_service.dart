import 'package:bluehub_app/features/order/data/payment_models.dart';
import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';

class PaymentService {
  PaymentService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建支付订单并返回对应支付渠道所需的拉起参数。
  ///
  /// `request.paymentMethod` 当前按接口约定传 `wechat_pay` 或 `alipay`。
  Future<PaymentResultVO> createPayment({
    required CreatePaymentBO request,
  }) async {
    final response = await _apiClient.post<PaymentResultVO>(
      '/payments/create',
      data: request.toJson(),
      decode: (data) => PaymentResultVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 查询指定订单的支付状态。
  ///
  /// 返回值中的 `status` 目前按接口定义支持 `pending`、`success`、`failed`。
  Future<PaymentStatusVO> queryPaymentStatus({required int orderId}) async {
    final response = await _apiClient.get<PaymentStatusVO>(
      '/payments/$orderId/status',
      decode: (data) => PaymentStatusVO.fromJson(asJsonMap(data)),
    );
    return response;
  }
}
