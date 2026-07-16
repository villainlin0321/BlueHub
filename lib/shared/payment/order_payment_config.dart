enum OrderPaymentMode { none, review }

class OrderPaymentConfig {
  const OrderPaymentConfig._();

  /// `review` 表示审核模式：
  /// 创建订单后直接调用支付成功接口并跳转订单详情页，
  /// 同时登录页仅保留邮箱登录入口。
  static const OrderPaymentMode mode = OrderPaymentMode.review;

  static bool get isReviewMode => mode == OrderPaymentMode.review;

  /// 兼容既有调用方，继续沿用原有判断入口。
  static bool get isSkipMode => isReviewMode;
}
