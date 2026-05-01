import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import 'provider_models.dart';

class ProviderService {
  ProviderService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PageResult<VisaProviderListVO>> listProviders({
    int? page,
    int? pageSize,
    String? country,
    String? visaType,
    String? keyword,
    String? tab,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (country != null) 'country': country,
      if (visaType != null) 'visa_type': visaType,
      if (keyword != null) 'keyword': keyword,
      if (tab != null) 'tab': tab,
    };
    final response = await _apiClient.get<PageResult<VisaProviderListVO>>(
      '/visa-providers',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<VisaProviderListVO>.fromJson(
        asJsonMap(data),
        fromJson: VisaProviderListVO.fromJson,
      ),
    );
    return response;
  }

  Future<ProviderVO> getMyProfile() async {
    final response = await _apiClient.get<ProviderVO>(
      '/visa-providers/me',
      decode: (data) => ProviderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updateMyProfile({required UpdateVisaProviderBO request}) async {
    return _apiClient.putVoid('/visa-providers/me', data: request.toJson());
  }

  Future<void> uploadQualifications({
    required UploadQualificationDocsBO request,
  }) async {
    return _apiClient.postVoid(
      '/visa-providers/me/qualifications',
      data: request.toJson(),
    );
  }

  Future<VisaProviderDetailVO> getProviderPackages({
    required int providerId,
  }) async {
    final response = await _apiClient.get<VisaProviderDetailVO>(
      '/visa-providers/$providerId/packages',
      decode: (data) => VisaProviderDetailVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<ReviewVO> listProviderReviews({
    required int providerId,
    int? page,
    int? pageSize,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (sort != null) 'sort': sort,
    };
    final response = await _apiClient.get<ReviewVO>(
      '/visa-providers/$providerId/reviews',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => ReviewVO.fromJson(asJsonMap(data)),
    );
    return response;
  }
}
