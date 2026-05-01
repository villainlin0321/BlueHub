import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'employer_service.dart';

final employerServiceProvider = Provider<EmployerService>((ref) {
  return EmployerService(apiClient: ref.watch(apiClientProvider));
});
