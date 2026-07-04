import 'package:europepass/shared/network/api_decoders.dart';

class CreatePaymentBO {
  const CreatePaymentBO({required this.orderId, required this.paymentMethod});

  final int orderId;
  final String paymentMethod;

  factory CreatePaymentBO.fromJson(JsonMap json) {
    return CreatePaymentBO(
      orderId: readInt(json, 'orderId', fallback: readInt(json, 'order_id')),
      paymentMethod: readString(
        json,
        'paymentMethod',
        fallback: readString(json, 'payment_method'),
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'paymentMethod': paymentMethod,
    };
  }
}

class PaymentResultVO {
  const PaymentResultVO({
    required this.paymentId,
    required this.paymentMethod,
    required this.outTradeNo,
    required this.wxPartnerId,
    required this.wxPrepayId,
    required this.wxPackageValue,
    required this.wxNonceStr,
    required this.wxTimestamp,
    required this.wxSign,
    required this.alipayOrderString,
  });

  final int paymentId;
  final String paymentMethod;
  final String outTradeNo;
  final String? wxPartnerId;
  final String? wxPrepayId;
  final String? wxPackageValue;
  final String? wxNonceStr;
  final String? wxTimestamp;
  final String? wxSign;
  final String? alipayOrderString;

  factory PaymentResultVO.fromJson(JsonMap json) {
    return PaymentResultVO(
      paymentId: readInt(
        json,
        'paymentId',
        fallback: readInt(json, 'payment_id'),
      ),
      paymentMethod: readString(
        json,
        'paymentMethod',
        fallback: readString(json, 'payment_method'),
      ),
      outTradeNo: readString(
        json,
        'outTradeNo',
        fallback: readString(json, 'out_trade_no'),
      ),
      wxPartnerId: _readNullableString(
        json['wxPartnerId'] ?? json['wx_partner_id'],
      ),
      wxPrepayId: _readNullableString(
        json['wxPrepayId'] ?? json['wx_prepay_id'],
      ),
      wxPackageValue: _readNullableString(
        json['wxPackageValue'] ?? json['wx_package_value'],
      ),
      wxNonceStr: _readNullableString(
        json['wxNonceStr'] ?? json['wx_nonce_str'],
      ),
      wxTimestamp: _readNullableString(
        json['wxTimestamp'] ?? json['wx_timestamp'],
      ),
      wxSign: _readNullableString(json['wxSign'] ?? json['wx_sign']),
      alipayOrderString: _readNullableString(
        json['alipayOrderString'] ?? json['alipay_order_string'],
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'outTradeNo': outTradeNo,
      'wxPartnerId': wxPartnerId,
      'wxPrepayId': wxPrepayId,
      'wxPackageValue': wxPackageValue,
      'wxNonceStr': wxNonceStr,
      'wxTimestamp': wxTimestamp,
      'wxSign': wxSign,
      'alipayOrderString': alipayOrderString,
    };
  }
}

class PaymentStatusVO {
  const PaymentStatusVO({
    required this.paymentId,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.paidAt,
  });

  final int paymentId;
  final int orderId;
  final String paymentMethod;
  final double amount;
  final String status;
  final String? paidAt;

  factory PaymentStatusVO.fromJson(JsonMap json) {
    return PaymentStatusVO(
      paymentId: readInt(
        json,
        'paymentId',
        fallback: readInt(json, 'payment_id'),
      ),
      orderId: readInt(json, 'orderId', fallback: readInt(json, 'order_id')),
      paymentMethod: readString(
        json,
        'paymentMethod',
        fallback: readString(json, 'payment_method'),
      ),
      amount: readDouble(json, 'amount'),
      status: readString(json, 'status'),
      paidAt: _readNullableString(json['paidAt'] ?? json['paid_at']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'paymentId': paymentId,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'status': status,
      'paidAt': paidAt,
    };
  }
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}
