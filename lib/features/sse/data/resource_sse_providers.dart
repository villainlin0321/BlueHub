import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/resource_sse_service.dart';

final resourceSseServiceProvider = Provider<ResourceSseService>((ref) {
  return ResourceSseService(
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});
