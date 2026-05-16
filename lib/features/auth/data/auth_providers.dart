import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
});
