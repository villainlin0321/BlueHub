import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/visa/data/visa_package_models.dart';

class VisaPackageService {
  VisaPackageService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建签证套餐。
  ///
  /// 提交套餐基础信息、标签和价格配置后，返回接口原始结果。
  Future<Map<String, dynamic>> createPackage({
    required CreateVisaPackageBO request,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/visa-packages',
      data: request.toJson(),
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  /// 分页查询当前服务商发布的签证套餐列表。
  ///
  /// 可按分页参数和套餐状态 `status` 过滤。
  Future<PageResult<VisaPackageVO>> listMyPackages({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get<PageResult<VisaPackageVO>>(
      '/visa-packages/mine',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<VisaPackageVO>.fromJson(
        asJsonMap(data),
        fromJson: VisaPackageVO.fromJson,
      ),
    );
    return response;
  }

  /// 删除指定签证套餐。
  Future<void> deletePackage({required int packageId}) async {
    return _apiClient.deleteVoid('/visa-packages/$packageId');
  }

  /// 获取指定签证套餐的详情。
  Future<VisaPackageVO> getPackageDetail({required int packageId}) async {
    final response = await _apiClient.get<VisaPackageVO>(
      '/visa-packages/$packageId',
      decode: (data) => VisaPackageVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新指定签证套餐的完整信息。
  Future<void> updatePackage({
    required int packageId,
    required CreateVisaPackageBO request,
  }) async {
    return _apiClient.putVoid(
      '/visa-packages/$packageId',
      data: request.toJson(),
    );
  }

  /// 更新签证套餐状态。
  ///
  /// 常用于上架、下架或草稿等状态切换。
  Future<void> updatePackageStatus({
    required int packageId,
    required UpdatePackageStatusBO request,
  }) async {
    return _apiClient.putVoid(
      '/visa-packages/$packageId/status',
      data: request.toJson(),
    );
  }
}
