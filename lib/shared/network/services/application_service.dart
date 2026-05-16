import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/jobs/data/application_models.dart';

class ApplicationService {
  ApplicationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PageResult<ApplicationVO>> listJobApplications({
    int? jobId,
    int? page,
    int? pageSize,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (jobId != null) 'job_id': jobId,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get<PageResult<ApplicationVO>>(
      '/applications',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<ApplicationVO>.fromJson(
        asJsonMap(data),
        fromJson: ApplicationVO.fromJson,
      ),
    );
    return response;
  }

  Future<Map<String, dynamic>> apply({
    required CreateApplicationBO request,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/applications',
      data: request.toJson(),
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  Future<PageResult<ApplicationVO>> listMyApplications({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get<PageResult<ApplicationVO>>(
      '/applications/mine',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<ApplicationVO>.fromJson(
        asJsonMap(data),
        fromJson: ApplicationVO.fromJson,
      ),
    );
    return response;
  }

  Future<void> updateStatus({
    required int applicationId,
    required UpdateApplicationStatusBO request,
  }) async {
    return _apiClient.putVoid(
      '/applications/$applicationId/status',
      data: request.toJson(),
    );
  }

  Future<void> withdraw({required int applicationId}) async {
    return _apiClient.putVoid('/applications/$applicationId/withdraw');
  }
}
