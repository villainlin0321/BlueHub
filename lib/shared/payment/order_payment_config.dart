enum OrderPaymentMode { none, skip }

class OrderPaymentConfig {
  const OrderPaymentConfig._();

  /// `skip` 表示创建订单后直接调用支付成功接口并跳转订单详情页。
  static const OrderPaymentMode mode = OrderPaymentMode.skip;

  static bool get isSkipMode => mode == OrderPaymentMode.skip;
}
