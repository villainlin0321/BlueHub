import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'message_service.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService(
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});
