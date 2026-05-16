import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/application_service.dart';

final applicationServiceProvider = Provider<ApplicationService>((ref) {
  return ApplicationService(apiClient: ref.watch(apiClientProvider));
});
