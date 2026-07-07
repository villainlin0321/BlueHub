import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 持有当前接口语言码，并负责把语言选择持久化到本地。
class AppLanguageStore {
  AppLanguageStore({required SharedPreferences prefs})
    : _prefs = prefs,
      _currentLanguageCode = _readInitialLanguageCode(prefs);

  static const String _languageCodeKey = 'app.language_code';

  final SharedPreferences _prefs;
  String _currentLanguageCode;

  String get currentLanguageCode => _currentLanguageCode;

  /// 同步更新内存中的语言码，并异步写入本地，适合在启动阶段快速对齐。
  void syncLocale(Locale locale) {
    syncLanguageCode(locale.languageCode);
  }

  /// 同步更新内存中的语言码，并异步写入本地，避免阻塞当前 UI 生命周期。
  void syncLanguageCode(String? languageCode) {
    final normalized = _normalizeLanguageCode(languageCode);
    if (_currentLanguageCode == normalized) {
      return;
    }
    _currentLanguageCode = normalized;
    unawaited(_prefs.setString(_languageCodeKey, normalized));
  }

  Future<void> setLocale(Locale locale) async {
    await setLanguageCode(locale.languageCode);
  }

  Future<void> setLanguageCode(String? languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    if (_currentLanguageCode == normalized) {
      return;
    }
    _currentLanguageCode = normalized;
    await _prefs.setString(_languageCodeKey, normalized);
  }

  static String _readInitialLanguageCode(SharedPreferences prefs) {
    final cached = _normalizeLanguageCodeOrNull(
      prefs.getString(_languageCodeKey),
    );
    if (cached != null) {
      return cached;
    }
    return _normalizeLanguageCode(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
  }

  static String _normalizeLanguageCode(String? languageCode) {
    return _normalizeLanguageCodeOrNull(languageCode) ?? 'en';
  }

  static String? _normalizeLanguageCodeOrNull(String? languageCode) {
    final normalized = languageCode?.trim().toLowerCase();
    if (normalized == 'zh') {
      return 'zh';
    }
    if (normalized == 'en') {
      return 'en';
    }
    return null;
  }
}
