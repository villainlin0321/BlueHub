import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import '../../../shared/network/services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(apiClient: ref.watch(apiClientProvider));
});
