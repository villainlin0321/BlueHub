import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'provider_service.dart';

final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService(apiClient: ref.watch(apiClientProvider));
});
