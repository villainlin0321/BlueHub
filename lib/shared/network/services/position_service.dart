import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/models/dictionary_models.dart';

class PositionService {
  PositionService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取职位两级树，传关键字时仅返回匹配职位所在的分类。
  Future<List<PositionCategoryVO>> listPositionTree({String? keyword}) async {
    final queryParameters = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
    };
    final response = await _apiClient.get<List<PositionCategoryVO>>(
      '/positions',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => decodeModelList<PositionCategoryVO>(
        data,
        PositionCategoryVO.fromJson,
      ),
    );
    return response;
  }
}
