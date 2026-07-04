import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import '../../../shared/network/services/resume_service.dart';

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService(apiClient: ref.watch(apiClientProvider));
});
