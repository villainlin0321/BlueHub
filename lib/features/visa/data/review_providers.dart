import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(apiClient: ref.watch(apiClientProvider));
});
