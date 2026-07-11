import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:europepass/shared/network/page_result.dart';
import '../../../features/visa/data/visa_package_models.dart';

class VisaPackageService {
  VisaPackageService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建签证套餐。
  ///
  /// 提交套餐基础信息、标签和价格配置后，返回接口原始结果。
  /// 调用方需从返回体中继续解析新建套餐的资源 ID。
  Future<Map<String, dynamic>> createPackage({
    required CreateVisaPackageBO request,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/visa-packages',
      data: _buildPackageRequestBody(request),
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

  /// 获取签证套餐编辑态详情。
  ///
  /// 返回专门用于服务商编辑页回填的数据结构，包含 `coverImageIds`、
  /// `status` 以及材料示例文件 ID 等编辑态字段。
  Future<VisaPackageEditVO> getPackageEditDetail({
    required int packageId,
  }) async {
    final response = await _apiClient.get<VisaPackageEditVO>(
      '/visa-packages/$packageId/edit',
      decode: (data) => VisaPackageEditVO.fromJson(asJsonMap(data)),
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
      data: _buildPackageRequestBody(request),
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

  Map<String, dynamic> _buildPackageRequestBody(CreateVisaPackageBO request) {
    return <String, dynamic>{
      'name': request.name,
      'targetCountry': request.targetCountry,
      'visaType': request.visaType,
      'estimatedDays': request.estimatedDays,
      'currency': request.currency,
      'coverImageIds': request.coverImageIds,
      'coverImages': request.coverImages,
      'tiers': request.tiers.map(_buildTierRequestBody).toList(growable: false),
      'isDraft': request.isDraft,
    };
  }

  Map<String, dynamic> _buildTierRequestBody(TierBO tier) {
    return <String, dynamic>{
      'tierId': tier.tierId,
      'name': tier.name,
      'price': tier.price,
      'services': tier.services,
      'customServices': tier.customServices,
      'description': tier.description,
      'showMaterials': tier.showMaterials,
      'sortOrder': tier.sortOrder,
      'materials': tier.materials
          .map(_buildMaterialRequestBody)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _buildMaterialRequestBody(MaterialBO material) {
    return <String, dynamic>{
      'name': material.name,
      'description': material.description,
      'isRequired': material.isRequired,
      'sortOrder': material.sortOrder,
      'exampleFileIds': material.exampleFileIds,
    };
  }
}
