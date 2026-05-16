import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/models/dictionary_models.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

class CountryService {
  CountryService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 搜索国家/地区列表，未传关键字时返回按权重排序的启用国家。
  Future<PageResult<CountryVO>> searchCountries({
    String? keyword,
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<CountryVO>>(
      '/countries',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<CountryVO>.fromJson(
        asJsonMap(data),
        fromJson: CountryVO.fromJson,
      ),
    );
    return response;
  }
}
