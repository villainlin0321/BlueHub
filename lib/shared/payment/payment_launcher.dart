import 'dart:async';

import 'package:fluwx/fluwx.dart';
import 'package:tobias/tobias.dart';

import '../../features/order/data/payment_models.dart';
import '../logging/app_logger.dart';
import 'payment_channel_config.dart';

enum AppPaymentLaunchStatus { success, cancel, failed, pending, unknown }

class AppPaymentLaunchResult {
  const AppPaymentLaunchResult({
    required this.status,
    required this.message,
    this.raw,
  });

  final AppPaymentLaunchStatus status;
  final String message;
  final Object? raw;
}

class PaymentLauncher {
  PaymentLauncher._();

  static final PaymentLauncher instance = PaymentLauncher._();

  final Fluwx _fluwx = Fluwx();
  final Tobias _tobias = Tobias();

  PaymentChannelConfig _config = PaymentChannelConfig.fromEnvironment();
  bool _didInitWeChat = false;

  Future<void> initialize({PaymentChannelConfig? config}) async {
    _config = config ?? PaymentChannelConfig.fromEnvironment();
    if (!_config.hasWeChatConfig) {
      AppLogger.instance.warn(
        'PAYMENT',
        '微信支付配置缺失，跳过 SDK 注册',
        context: <String, Object?>{
          'hasWeChatAppId': _config.weChatAppId.isNotEmpty,
          'hasUniversalLink': _config.weChatUniversalLinkHost.isNotEmpty,
        },
      );
      return;
    }
    try {
      _didInitWeChat = await _fluwx.registerApi(
        appId: _config.weChatAppId,
        universalLink: _config.weChatUniversalLink,
      );
      AppLogger.instance.info(
        'PAYMENT',
        '微信支付 SDK 注册完成',
        context: <String, Object?>{
          'registered': _didInitWeChat,
          'appIdTail': _mask(_config.weChatAppId),
          'universalLinkHost': _config.weChatUniversalLinkHost,
        },
      );
    } catch (error, stackTrace) {
      _didInitWeChat = false;
      AppLogger.instance.error(
        'PAYMENT',
        '微信支付 SDK 注册失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AppPaymentLaunchResult> payWithAlipay(PaymentResultVO payload) async {
    final String orderString = (payload.alipayOrderString ?? '').trim();
    if (orderString.isEmpty) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '支付宝支付参数缺失',
      );
    }

    final bool isInstalled = await _tobias.isAliPayInstalled;
    if (!isInstalled) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '请先安装支付宝客户端',
      );
    }

    try {
      final Map result = await _tobias.pay(orderString, evn: AliPayEvn.online);
      final String status =
          '${result['resultStatus'] ?? result['result_status'] ?? ''}'.trim();
      final String memo = '${result['memo'] ?? result['message'] ?? ''}'.trim();
      AppLogger.instance.info(
        'PAYMENT',
        '支付宝支付返回',
        context: <String, Object?>{
          'resultStatus': status,
          'memo': memo,
          'paymentId': payload.paymentId,
          'orderNo': _mask(payload.outTradeNo),
        },
      );
      switch (status) {
        case '9000':
          return AppPaymentLaunchResult(
            status: AppPaymentLaunchStatus.success,
            message: memo.isEmpty ? '支付宝支付成功' : memo,
            raw: result,
          );
        case '6001':
          return AppPaymentLaunchResult(
            status: AppPaymentLaunchStatus.cancel,
            message: memo.isEmpty ? '已取消支付宝支付' : memo,
            raw: result,
          );
        case '8000':
          return AppPaymentLaunchResult(
            status: AppPaymentLaunchStatus.pending,
            message: memo.isEmpty ? '支付宝支付结果确认中' : memo,
            raw: result,
          );
        default:
          return AppPaymentLaunchResult(
            status: AppPaymentLaunchStatus.failed,
            message: memo.isEmpty ? '支付宝支付失败' : memo,
            raw: result,
          );
      }
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'PAYMENT',
        '支付宝支付拉起失败',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '支付宝支付拉起失败',
      );
    }
  }

  Future<AppPaymentLaunchResult> payWithWeChat(PaymentResultVO payload) async {
    if (!_config.hasWeChatConfig) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '微信支付配置缺失',
      );
    }
    if (!_didInitWeChat) {
      await initialize(config: _config);
    }
    if (!_didInitWeChat) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '微信支付初始化失败',
      );
    }

    final String? partnerId = payload.wxPartnerId?.trim();
    final String? prepayId = payload.wxPrepayId?.trim();
    final String? packageValue = payload.wxPackageValue?.trim();
    final String? nonceStr = payload.wxNonceStr?.trim();
    final String? sign = payload.wxSign?.trim();
    final int? timestamp = int.tryParse(payload.wxTimestamp?.trim() ?? '');
    if (partnerId == null ||
        prepayId == null ||
        packageValue == null ||
        nonceStr == null ||
        sign == null ||
        timestamp == null) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '微信支付参数缺失',
      );
    }

    final bool isInstalled = await _fluwx.isWeChatInstalled;
    if (!isInstalled) {
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '请先安装微信客户端',
      );
    }

    final Completer<AppPaymentLaunchResult> completer =
        Completer<AppPaymentLaunchResult>();
    late final FluwxCancelable cancelable;
    cancelable = _fluwx.addSubscriber((response) {
      if (response is! WeChatPaymentResponse || completer.isCompleted) {
        return;
      }
      cancelable.cancel();
      completer.complete(_mapWeChatResponse(response));
    });

    try {
      final bool launched = await _fluwx.pay(
        which: Payment(
          appId: _config.weChatAppId,
          partnerId: partnerId,
          prepayId: prepayId,
          packageValue: packageValue,
          nonceStr: nonceStr,
          timestamp: timestamp,
          sign: sign,
        ),
      );
      if (!launched) {
        cancelable.cancel();
        return const AppPaymentLaunchResult(
          status: AppPaymentLaunchStatus.failed,
          message: '微信支付拉起失败',
        );
      }
      return completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          cancelable.cancel();
          return const AppPaymentLaunchResult(
            status: AppPaymentLaunchStatus.unknown,
            message: '微信支付结果回调超时',
          );
        },
      );
    } catch (error, stackTrace) {
      cancelable.cancel();
      AppLogger.instance.error(
        'PAYMENT',
        '微信支付拉起失败',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.failed,
        message: '微信支付拉起失败',
      );
    }
  }

  AppPaymentLaunchResult _mapWeChatResponse(WeChatPaymentResponse response) {
    final int code = response.errCode ?? -1;
    AppLogger.instance.info(
      'PAYMENT',
      '微信支付返回',
      context: <String, Object?>{'errCode': code, 'errStr': response.errStr},
    );
    if (code == 0) {
      return AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.success,
        message: '微信支付成功',
        raw: response.toRecord(),
      );
    }
    if (code == -2) {
      return AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.cancel,
        message: '已取消微信支付',
        raw: response.toRecord(),
      );
    }
    return AppPaymentLaunchResult(
      status: AppPaymentLaunchStatus.failed,
      message: (response.errStr ?? '').trim().isEmpty
          ? '微信支付失败'
          : response.errStr!.trim(),
      raw: response.toRecord(),
    );
  }
}

String _mask(String raw) {
  final String value = raw.trim();
  if (value.length <= 8) {
    return value;
  }
  return '${value.substring(0, 4)}****${value.substring(value.length - 4)}';
}
