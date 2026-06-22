import 'dart:async';

import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/payment/payment_launcher.dart';
import '../../../order/data/payment_models.dart';
import '../../../../shared/network/services/payment_service.dart';

enum AppPaymentMethod { alipay, wechat }

extension AppPaymentMethodX on AppPaymentMethod {
  String get apiValue {
    switch (this) {
      case AppPaymentMethod.alipay:
        return 'alipay';
      case AppPaymentMethod.wechat:
        return 'wechat_pay';
    }
  }
}

enum PaymentFlowStatus { success, cancel, failed, pending }

class PaymentFlowResult {
  const PaymentFlowResult({
    required this.status,
    required this.message,
    this.paymentStatus,
  });

  final PaymentFlowStatus status;
  final String message;
  final PaymentStatusVO? paymentStatus;
}

class PaymentFlowCoordinator {
  PaymentFlowCoordinator({
    required PaymentService paymentService,
    PaymentLauncher? paymentLauncher,
  }) : _paymentService = paymentService,
       _paymentLauncher = paymentLauncher ?? PaymentLauncher.instance;

  static const Duration _pollDelay = Duration(seconds: 1);
  static const int _maxStatusAttempts = 6;

  final PaymentService _paymentService;
  final PaymentLauncher _paymentLauncher;

  Future<PaymentFlowResult> startPayment({
    required int orderId,
    required AppPaymentMethod method,
  }) async {
    final PaymentResultVO payment = await _paymentService.createPayment(
      request: CreatePaymentBO(
        orderId: orderId,
        paymentMethod: method.apiValue,
      ),
    );

    final AppPaymentLaunchResult launchResult = switch (method) {
      AppPaymentMethod.alipay => await _paymentLauncher.payWithAlipay(payment),
      AppPaymentMethod.wechat => await _paymentLauncher.payWithWeChat(payment),
    };
    switch (launchResult.status) {
      case AppPaymentLaunchStatus.success:
        return _queryFinalStatus(orderId: orderId);
      case AppPaymentLaunchStatus.cancel:
        return PaymentFlowResult(
          status: PaymentFlowStatus.cancel,
          message: launchResult.message,
        );
      case AppPaymentLaunchStatus.pending:
        return PaymentFlowResult(
          status: PaymentFlowStatus.pending,
          message: '支付.支付结果确认中请稍后刷新订单状态'.tr(),
        );
      case AppPaymentLaunchStatus.failed:
      case AppPaymentLaunchStatus.unknown:
        return PaymentFlowResult(
          status: PaymentFlowStatus.failed,
          message: launchResult.message,
        );
    }
  }

  Future<PaymentFlowResult> _queryFinalStatus({required int orderId}) async {
    PaymentStatusVO? latestStatus;
    for (int attempt = 0; attempt < _maxStatusAttempts; attempt++) {
      latestStatus = await _paymentService.queryPaymentStatus(orderId: orderId);
      final String normalized = latestStatus.status.trim().toLowerCase();
      if (normalized == 'success') {
        return PaymentFlowResult(
          status: PaymentFlowStatus.success,
          message: '服务详情.支付成功'.tr(),
          paymentStatus: latestStatus,
        );
      }
      if (normalized == 'failed') {
        return PaymentFlowResult(
          status: PaymentFlowStatus.failed,
          message: '支付.支付失败请稍后重试'.tr(),
          paymentStatus: latestStatus,
        );
      }
      if (attempt < _maxStatusAttempts - 1) {
        await Future<void>.delayed(_pollDelay);
      }
    }
    return PaymentFlowResult(
      status: PaymentFlowStatus.pending,
      message: '支付.支付结果确认中请稍后刷新订单状态'.tr(),
      paymentStatus: latestStatus,
    );
  }
}
