import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/visa/data/provider_models.dart';

class ProviderService {
  ProviderService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取签证服务商列表，支持分页以及国家、签证类型、关键词和标签筛选。
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

  /// 获取当前登录服务商的机构资料。
  Future<ProviderVO> getMyProfile() async {
    final response = await _apiClient.get<ProviderVO>(
      '/visa-providers/me',
      decode: (data) => ProviderVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新当前登录服务商的基础资料与服务信息。
  Future<void> updateMyProfile({required UpdateVisaProviderBO request}) async {
    return _apiClient.putVoid('/visa-providers/me', data: request.toJson());
  }

  /// 上传当前登录服务商的资质文档列表。
  Future<void> uploadQualifications({
    required UploadQualificationDocsBO request,
  }) async {
    return _apiClient.postVoid(
      '/visa-providers/me/qualifications',
      data: request.toJson(),
    );
  }

  /// 获取指定服务商的资料与已发布套餐列表。
  Future<VisaProviderDetailVO> getProviderPackages({
    required int providerId,
  }) async {
    final response = await _apiClient.get<VisaProviderDetailVO>(
      '/visa-providers/$providerId/packages',
      decode: (data) => VisaProviderDetailVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 获取指定服务商的评价列表，支持分页与排序方式切换。
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
