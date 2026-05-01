import 'package:bluehub_app/shared/network/api_client.dart';
import 'review_models.dart';

class ReviewService {
  ReviewService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> createReview({required CreateReviewBO request}) async {
    return _apiClient.postVoid('/reviews', data: request.toJson());
  }
}
