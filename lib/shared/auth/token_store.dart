import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._({SharedPreferences? prefs}) : _prefs = prefs {
    _loadFromPrefs();
  }

  factory TokenStore.inMemory() => TokenStore._();

  factory TokenStore.sharedPreferences(SharedPreferences prefs) => TokenStore._(prefs: prefs);

  static const _kAccessToken = 'auth.accessToken';
  static const _kRefreshToken = 'auth.refreshToken';

  final SharedPreferences? _prefs;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;
    _accessToken = prefs.getString(_kAccessToken);
    _refreshToken = prefs.getString(_kRefreshToken);
  }

  void setTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.setString(_kAccessToken, accessToken));
      if (refreshToken != null) {
        unawaited(prefs.setString(_kRefreshToken, refreshToken));
      }
    }
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;

    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.remove(_kAccessToken));
      unawaited(prefs.remove(_kRefreshToken));
    }
  }
}
