import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// 应用语言配置：统一维护支持的语言、默认语言与切换方法。
class AppLocales {
  const AppLocales._();

  static const Locale english = Locale('en');
  static const Locale chinese = Locale('zh');

  static const List<Locale> supported = <Locale>[english, chinese];

  /// 判断当前 Locale 是否为中文，统一兼容仅语言码的场景。
  static bool isChinese(Locale locale) => locale.languageCode == chinese.languageCode;
}

/// 语言切换扩展：简化页面中的语言判断与切换调用。
extension AppLocaleContextX on BuildContext {
  bool get isChineseLocale => AppLocales.isChinese(locale);

  /// 根据开关状态切换应用语言，true 为中文，false 为英文。
  Future<void> switchAppLocale(bool isChinese) {
    return setLocale(isChinese ? AppLocales.chinese : AppLocales.english);
  }
}
