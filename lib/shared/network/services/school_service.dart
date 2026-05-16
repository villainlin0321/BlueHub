import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/models/dictionary_models.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

class SchoolService {
  SchoolService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 搜索学校列表，支持关键字、国家和分页参数。
  Future<PageResult<SchoolVO>> searchSchools({
    String? keyword,
    String? country,
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (country != null) 'country': country,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<SchoolVO>>(
      '/schools',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<SchoolVO>.fromJson(
        asJsonMap(data),
        fromJson: SchoolVO.fromJson,
      ),
    );
    return response;
  }
}
