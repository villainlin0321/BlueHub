import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/config_service.dart';

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService(apiClient: ref.watch(apiClientProvider));
});
