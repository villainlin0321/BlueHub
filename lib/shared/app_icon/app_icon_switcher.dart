import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 应用图标切换器：根据 Locale 触发平台侧（Android/iOS）的图标切换逻辑。
class AppIconSwitcher {
  AppIconSwitcher._();

  static const String _channelName = 'bluehub/app_icon';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static Locale? _lastSyncedLocale;

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 同步 App 图标：中文 Locale 使用中文图标，其余使用默认图标。
  static Future<void> syncByLocale(Locale locale) async {
    if (!_isAndroid) {
      return;
    }

    if (_lastSyncedLocale?.languageCode == locale.languageCode) {
      return;
    }

    _lastSyncedLocale = locale;
    final isChinese = locale.languageCode == 'zh';

    try {
      await _channel.invokeMethod<void>(
        'setIcon',
        <String, Object?>{'isChinese': isChinese},
      );
    } on PlatformException {
      return;
    }
  }
}
