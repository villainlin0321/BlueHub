import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import '../../../shared/network/services/auth_service.dart';
import 'login_account_store.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

final loginAccountStoreProvider = Provider<LoginAccountStore>((ref) {
  return LoginAccountStore(prefs: ref.watch(sharedPreferencesProvider));
});
