import 'package:europepass/shared/network/api_client.dart';
import '../../../features/visa/data/review_models.dart';

class ReviewService {
  ReviewService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建服务评价。
  ///
  /// 提交订单或服务相关的评分、标签与文本内容。
  Future<void> createReview({required CreateReviewBO request}) async {
    return _apiClient.postVoid('/reviews', data: request.toJson());
  }
}
