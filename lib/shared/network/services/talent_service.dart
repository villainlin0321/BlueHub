import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/models/talent_models.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

class TalentService {
  TalentService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 分页浏览人才中心公开简历。
  Future<PageResult<TalentVO>> listTalents({
    String? keyword,
    String? country,
    String? position,
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (country != null) 'country': country,
      if (position != null) 'position': position,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<TalentVO>>(
      '/talents',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<TalentVO>.fromJson(
        asJsonMap(data),
        fromJson: TalentVO.fromJson,
      ),
    );
    return response;
  }
}
