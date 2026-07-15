import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/logging/app_log_event.dart';
import '../../../../shared/logging/app_log_facade.dart';
import '../../../../shared/logging/app_log_scope.dart';
import '../../../../shared/network/services/visa_order_service.dart';
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
    VisaOrderService? visaOrderService,
    PaymentLauncher? paymentLauncher,
    bool enableDebugDirectPay = kDebugMode,
  }) : _paymentService = paymentService,
       _visaOrderService = visaOrderService,
       _enableDebugDirectPay = enableDebugDirectPay,
       _paymentLauncher = paymentLauncher ?? PaymentLauncher.instance;

  static const Duration _pollDelay = Duration(seconds: 1);
  static const int _maxStatusAttempts = 6;

  final PaymentService _paymentService;
  final VisaOrderService? _visaOrderService;
  final bool _enableDebugDirectPay;
  final PaymentLauncher _paymentLauncher;

  /// 启动支付链路，并在同一条作用域内串联创建、拉起和轮询日志。
  Future<PaymentFlowResult> startPayment({
    required int orderId,
    required AppPaymentMethod method,
  }) async {
    final String traceId = _resolvePaymentTraceId();
    return AppLogScope.run<Future<PaymentFlowResult>>(
      traceId: traceId,
      fields: _buildPaymentScopeFields(orderId: orderId, method: method),
      action: () async {
        _logPaymentCreateStart();
        final PaymentResultVO payment;
        try {
          payment = await _paymentService.createPayment(
            request: CreatePaymentBO(
              orderId: orderId,
              paymentMethod: method.apiValue,
            ),
          );
        } catch (error, stackTrace) {
          _logPaymentCreateFail(error: error, stackTrace: stackTrace);
          rethrow;
        }
        _logPaymentCreateSuccess(payment);
        if (_shouldUseDebugDirectPay) {
          return _completeDebugDirectPay(
            orderId: orderId,
            method: method,
            payment: payment,
          );
        }

        final AppPaymentLaunchResult launchResult = switch (method) {
          AppPaymentMethod.alipay => await _paymentLauncher.payWithAlipay(
            payment,
          ),
          AppPaymentMethod.wechat => await _paymentLauncher.payWithWeChat(
            payment,
          ),
        };
        _logPaymentLaunchResult(
          payment: payment,
          method: method,
          launchResult: launchResult,
        );
        switch (launchResult.status) {
          case AppPaymentLaunchStatus.success:
            return _queryFinalStatus(orderId: orderId, payment: payment);
          case AppPaymentLaunchStatus.cancel:
            return PaymentFlowResult(
              status: PaymentFlowStatus.cancel,
              message: launchResult.message,
            );
          case AppPaymentLaunchStatus.pending:
            // SDK 返回待确认时，继续复用最终状态轮询链路，补齐可回放的 pending/success/fail 日志。
            return _queryFinalStatus(orderId: orderId, payment: payment);
          case AppPaymentLaunchStatus.failed:
          case AppPaymentLaunchStatus.unknown:
            return PaymentFlowResult(
              status: PaymentFlowStatus.failed,
              message: launchResult.message,
            );
        }
      },
    );
  }

  bool get _shouldUseDebugDirectPay =>
      _enableDebugDirectPay && _visaOrderService != null;

  /// Debug 模式下绕过支付 SDK，直接调用订单支付接口并按成功处理。
  Future<PaymentFlowResult> _completeDebugDirectPay({
    required int orderId,
    required AppPaymentMethod method,
    required PaymentResultVO payment,
  }) async {
    try {
      await _visaOrderService!.payOrder(orderId: orderId);
    } catch (error, stackTrace) {
      _logDebugDirectPayFail(
        payment: payment,
        method: method,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _logDebugDirectPaySuccess(payment: payment, method: method);
    return PaymentFlowResult(
      status: PaymentFlowStatus.success,
      message: '服务详情.支付成功'.tr(),
    );
  }

  /// 优先复用上游交互链路的 traceId，仅在缺失时才为支付流程补建新链路。
  String _resolvePaymentTraceId() {
    final Object? inheritedTraceId = AppLogScope.current['traceId'];
    if (inheritedTraceId is String && inheritedTraceId.trim().isNotEmpty) {
      return inheritedTraceId;
    }
    return buildAppTraceId('payment');
  }

  /// 轮询最终支付状态，并持续记录 pending/success/fail 结果。
  Future<PaymentFlowResult> _queryFinalStatus({
    required int orderId,
    required PaymentResultVO payment,
  }) async {
    PaymentStatusVO? latestStatus;
    for (int attempt = 0; attempt < _maxStatusAttempts; attempt++) {
      try {
        latestStatus = await _paymentService.queryPaymentStatus(
          orderId: orderId,
        );
      } catch (error, stackTrace) {
        _logPaymentPollException(
          payment: payment,
          attempt: attempt + 1,
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      final String normalized = latestStatus.status.trim().toLowerCase();
      if (normalized == 'success') {
        _logPaymentPollSuccess(
          payment: payment,
          attempt: attempt + 1,
          status: latestStatus,
        );
        return PaymentFlowResult(
          status: PaymentFlowStatus.success,
          message: '服务详情.支付成功'.tr(),
          paymentStatus: latestStatus,
        );
      }
      if (normalized == 'failed') {
        _logPaymentPollFail(
          payment: payment,
          attempt: attempt + 1,
          status: latestStatus,
        );
        return PaymentFlowResult(
          status: PaymentFlowStatus.failed,
          message: '支付.支付失败请稍后重试'.tr(),
          paymentStatus: latestStatus,
        );
      }
      // 继续记录每次轮询仍未落定的结果，便于排查卡在第几次查询。
      _logPaymentPollPending(
        payment: payment,
        attempt: attempt + 1,
        status: latestStatus,
      );
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

  /// 构建支付链路的基础作用域字段，确保后续所有日志自动继承订单上下文。
  Map<String, Object?> _buildPaymentScopeFields({
    required int orderId,
    required AppPaymentMethod method,
  }) {
    return <String, Object?>{
      'orderId': orderId,
      'paymentMethod': method.apiValue,
      'module': 'order',
      'feature': 'payment',
    };
  }

  /// 记录支付单创建开始事件，作为整条支付日志的起点。
  void _logPaymentCreateStart() {
    StateLog.transition(
      event: 'PAYMENT_CREATE_START',
      message: '开始创建支付单',
      result: AppLogResult.pending,
    );
  }

  /// 记录支付单创建成功事件，并补齐安全的支付单摘要。
  void _logPaymentCreateSuccess(PaymentResultVO payment) {
    StateLog.transition(
      event: 'PAYMENT_CREATE_SUCCESS',
      message: '支付单创建成功',
      result: AppLogResult.success,
      context: buildPaymentLogContext(payment),
    );
  }

  /// 记录支付单创建失败事件，保留统一错误上下文用于排障。
  void _logPaymentCreateFail({
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'PAYMENT_CREATE_FAIL',
      message: '支付单创建失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 按支付拉起结果输出统一事件，避免调用侧重复判断状态与事件名。
  void _logPaymentLaunchResult({
    required PaymentResultVO payment,
    required AppPaymentMethod method,
    required AppPaymentLaunchResult launchResult,
  }) {
    final ({
      String event,
      String message,
      AppLogLevel level,
      AppLogResult result,
    })
    logConfig = _mapLaunchLogConfig(launchResult.status);
    StateLog.transition(
      event: logConfig.event,
      message: logConfig.message,
      level: logConfig.level,
      result: logConfig.result,
      context: <String, Object?>{
        ...buildPaymentLogContext(payment),
        ...buildPaymentLaunchResultLogContext(
          launchResult,
          channel: method.apiValue,
        ),
      },
    );
  }

  /// 将支付拉起状态映射为稳定的日志事件名和结果态。
  ({String event, String message, AppLogLevel level, AppLogResult result})
  _mapLaunchLogConfig(AppPaymentLaunchStatus status) {
    switch (status) {
      case AppPaymentLaunchStatus.success:
        return (
          event: 'PAYMENT_LAUNCH_SUCCESS',
          message: '支付 SDK 拉起成功',
          level: AppLogLevel.info,
          result: AppLogResult.success,
        );
      case AppPaymentLaunchStatus.cancel:
        return (
          event: 'PAYMENT_LAUNCH_CANCEL',
          message: '支付 SDK 拉起后用户取消',
          level: AppLogLevel.warn,
          result: AppLogResult.cancel,
        );
      case AppPaymentLaunchStatus.pending:
        return (
          event: 'PAYMENT_LAUNCH_PENDING',
          message: '支付 SDK 拉起后结果待确认',
          level: AppLogLevel.warn,
          result: AppLogResult.pending,
        );
      case AppPaymentLaunchStatus.failed:
      case AppPaymentLaunchStatus.unknown:
        return (
          event: 'PAYMENT_LAUNCH_FAIL',
          message: '支付 SDK 拉起失败',
          level: AppLogLevel.error,
          result: AppLogResult.fail,
        );
    }
  }

  /// 记录轮询仍处于 pending 的状态，帮助定位卡在第几次查询。
  void _logPaymentPollPending({
    required PaymentResultVO payment,
    required int attempt,
    required PaymentStatusVO status,
  }) {
    StateLog.transition(
      event: 'PAYMENT_STATUS_POLL_PENDING',
      message: '支付状态仍在确认中',
      result: AppLogResult.pending,
      context: _buildPaymentStatusLogContext(
        payment: payment,
        attempt: attempt,
        status: status,
      ),
    );
  }

  /// 记录轮询成功事件，并补齐最终支付状态摘要。
  void _logPaymentPollSuccess({
    required PaymentResultVO payment,
    required int attempt,
    required PaymentStatusVO status,
  }) {
    StateLog.transition(
      event: 'PAYMENT_STATUS_POLL_SUCCESS',
      message: '支付状态轮询成功',
      result: AppLogResult.success,
      context: _buildPaymentStatusLogContext(
        payment: payment,
        attempt: attempt,
        status: status,
      ),
    );
  }

  /// 记录轮询返回失败状态的事件，便于区分业务失败与异常失败。
  void _logPaymentPollFail({
    required PaymentResultVO payment,
    required int attempt,
    required PaymentStatusVO status,
  }) {
    StateLog.transition(
      event: 'PAYMENT_STATUS_POLL_FAIL',
      message: '支付状态轮询返回失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      context: _buildPaymentStatusLogContext(
        payment: payment,
        attempt: attempt,
        status: status,
      ),
    );
  }

  /// 记录轮询异常事件，帮助区分状态失败与查询本身抛错。
  void _logPaymentPollException({
    required PaymentResultVO payment,
    required int attempt,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'PAYMENT_STATUS_POLL_FAIL',
      message: '支付状态轮询异常',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        ...buildPaymentLogContext(payment),
        'attempt': attempt,
      },
    );
  }

  /// 构建轮询日志上下文，统一补齐尝试次数与最终状态摘要。
  Map<String, Object?> _buildPaymentStatusLogContext({
    required PaymentResultVO payment,
    required int attempt,
    required PaymentStatusVO status,
  }) {
    return <String, Object?>{
      ...buildPaymentLogContext(payment),
      'attempt': attempt,
      'paymentStatus': status.status,
      if ((status.paidAt ?? '').trim().isNotEmpty) 'paidAt': status.paidAt,
    };
  }

  /// 记录 Debug 模式下跳过 SDK、直接支付成功的事件。
  void _logDebugDirectPaySuccess({
    required PaymentResultVO payment,
    required AppPaymentMethod method,
  }) {
    StateLog.transition(
      event: 'PAYMENT_DEBUG_DIRECT_PAY_SUCCESS',
      message: 'Debug 模式直接调用订单支付成功',
      result: AppLogResult.success,
      context: <String, Object?>{
        ...buildPaymentLogContext(payment),
        'paymentMethod': method.apiValue,
        'debugDirectPay': true,
      },
    );
  }

  /// 记录 Debug 模式下直接支付失败的事件，保留完整错误上下文。
  void _logDebugDirectPayFail({
    required PaymentResultVO payment,
    required AppPaymentMethod method,
    required Object error,
    required StackTrace stackTrace,
  }) {
    StateLog.transition(
      event: 'PAYMENT_DEBUG_DIRECT_PAY_FAIL',
      message: 'Debug 模式直接调用订单支付失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        ...buildPaymentLogContext(payment),
        'paymentMethod': method.apiValue,
        'debugDirectPay': true,
      },
    );
  }
}
