import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'collection_service.dart';

final collectionServiceProvider = Provider<CollectionService>((ref) {
  return CollectionService(apiClient: ref.watch(apiClientProvider));
});
