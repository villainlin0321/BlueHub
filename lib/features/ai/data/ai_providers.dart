import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});
