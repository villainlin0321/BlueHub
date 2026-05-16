import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/me/data/collection_models.dart';

class CollectionService {
  CollectionService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> removeCollection({required CollectionBO request}) async {
    return _apiClient.deleteVoid('/collections', data: request.toJson());
  }

  Future<void> addCollection({required CollectionBO request}) async {
    return _apiClient.postVoid('/collections', data: request.toJson());
  }

  Future<PageResult<JobListVO>> listCollectedJobs({
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<JobListVO>>(
      '/collections/jobs',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<JobListVO>.fromJson(
        asJsonMap(data),
        fromJson: JobListVO.fromJson,
      ),
    );
    return response;
  }

  Future<PageResult<VisaPackageVO>> listCollectedPackages({
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<VisaPackageVO>>(
      '/collections/visa-packages',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<VisaPackageVO>.fromJson(
        asJsonMap(data),
        fromJson: VisaPackageVO.fromJson,
      ),
    );
    return response;
  }
}
