import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'config_models.dart';

class ConfigService {
  ConfigService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<TagDictVO> getTags({String? category}) async {
    final queryParameters = <String, dynamic>{
      if (category != null) 'category': category,
    };
    final response = await _apiClient.get<TagDictVO>(
      '/config/tags',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => TagDictVO.fromJson(asJsonMap(data)),
    );
    return response;
  }
}
