import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/visa/data/visa_package_models.dart';

class VisaPackageService {
  VisaPackageService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

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

  Future<void> deletePackage({required int packageId}) async {
    return _apiClient.deleteVoid('/visa-packages/$packageId');
  }

  Future<VisaPackageVO> getPackageDetail({required int packageId}) async {
    final response = await _apiClient.get<VisaPackageVO>(
      '/visa-packages/$packageId',
      decode: (data) => VisaPackageVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updatePackage({
    required int packageId,
    required CreateVisaPackageBO request,
  }) async {
    return _apiClient.putVoid(
      '/visa-packages/$packageId',
      data: request.toJson(),
    );
  }

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
