import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'job_service.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService(apiClient: ref.watch(apiClientProvider));
});
