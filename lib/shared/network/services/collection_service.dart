import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:europepass/shared/network/page_result.dart';
import '../../../features/me/data/collection_models.dart';

class CollectionService {
  CollectionService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 取消收藏指定业务对象。
  ///
  /// `request` 中需携带收藏类型和目标对象 ID。
  Future<void> removeCollection({required CollectionBO request}) async {
    return _apiClient.deleteVoid('/collections', data: request.toJson());
  }

  /// 收藏指定业务对象。
  ///
  /// 支持岗位、签证套餐等可收藏实体。
  Future<void> addCollection({required CollectionBO request}) async {
    return _apiClient.postVoid('/collections', data: request.toJson());
  }

  /// 分页获取当前用户收藏的岗位列表。
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

  /// 分页获取当前用户收藏的签证套餐列表。
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
