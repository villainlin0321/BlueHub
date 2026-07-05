import 'package:shared_preferences/shared_preferences.dart';

enum LoginAccountMode { phone, email }

class CachedLoginAccount {
  const CachedLoginAccount({required this.mode, required this.account});

  final LoginAccountMode mode;
  final String account;
}

class LoginAccountStore {
  const LoginAccountStore({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _accountKey = 'auth.last_login_account';
  static const String _modeKey = 'auth.last_login_mode';

  final SharedPreferences _prefs;

  CachedLoginAccount? load() {
    final String account = _prefs.getString(_accountKey)?.trim() ?? '';
    final String modeValue = _prefs.getString(_modeKey)?.trim() ?? '';
    if (account.isEmpty || modeValue.isEmpty) {
      return null;
    }

    final LoginAccountMode? mode = switch (modeValue) {
      'phone' => LoginAccountMode.phone,
      'email' => LoginAccountMode.email,
      _ => null,
    };
    if (mode == null) {
      return null;
    }

    return CachedLoginAccount(mode: mode, account: account);
  }

  Future<void> save({
    required LoginAccountMode mode,
    required String account,
  }) async {
    final String normalizedAccount = account.trim();
    if (normalizedAccount.isEmpty) {
      await clear();
      return;
    }

    await _prefs.setString(_accountKey, normalizedAccount);
    await _prefs.setString(_modeKey, mode.name);
  }

  Future<void> clear() async {
    await _prefs.remove(_accountKey);
    await _prefs.remove(_modeKey);
  }
}
