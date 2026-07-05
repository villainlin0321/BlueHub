import 'package:flutter/widgets.dart';

import '../../../shared/localization/app_locales.dart';

/// 订单支付文案助手：按当前界面语言返回稳定文案，避免界面回退到翻译 key。
class OrderPaymentCopy {
  const OrderPaymentCopy._();

  /// 返回“确认支付”主文案，覆盖标题和主按钮的统一展示。
  static String confirmPayment(BuildContext context) {
    return _isChinese(context) ? '确认支付' : 'Confirm Payment';
  }

  /// 返回支付中的按钮文案，保持中英文环境都能稳定展示。
  static String paying(BuildContext context) {
    return _isChinese(context) ? '支付中...' : 'Paying...';
  }

  /// 返回支付倒计时文案，直接在当前语言下拼出可读文本。
  static String countdown(
    BuildContext context, {
    required String minutes,
    required String seconds,
  }) {
    if (_isChinese(context)) {
      return '请在 $minutes分$seconds秒 内支付，过时将被取消';
    }
    return 'Please complete payment within ${minutes}m ${seconds}s, or it will be canceled.';
  }

  /// 返回支付宝支付方式名称，避免支付方式行回退为 key。
  static String alipay(BuildContext context) {
    return _isChinese(context) ? '支付宝支付' : 'Alipay';
  }

  /// 返回微信支付方式名称，避免支付方式行回退为 key。
  static String wechat(BuildContext context) {
    return _isChinese(context) ? '微信支付' : 'WeChat Pay';
  }

  /// 返回支付发起失败提示，供兜底错误提示复用。
  static String startFail(BuildContext context) {
    return _isChinese(context) ? '支付发起失败，请稍后重试' : 'Failed to initiate payment. Please try again later.';
  }

  /// 判断当前界面语言是否为中文，保证文案选择跟随应用语言而不是系统默认语言。
  static bool _isChinese(BuildContext context) {
    return AppLocales.isChinese(Localizations.localeOf(context));
  }
}
