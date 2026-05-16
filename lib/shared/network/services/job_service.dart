import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/jobs/data/job_models.dart';

class JobService {
  JobService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PageResult<JobListVO>> listJobs({
    int? page,
    int? pageSize,
    String? country,
    String? keyword,
    double? salaryMin,
    double? salaryMax,
    bool? hasVisaSupport,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (country != null) 'country': country,
      if (keyword != null) 'keyword': keyword,
      if (salaryMin != null) 'salary_min': salaryMin,
      if (salaryMax != null) 'salary_max': salaryMax,
      if (hasVisaSupport != null) 'has_visa_support': hasVisaSupport,
      if (sort != null) 'sort': sort,
    };
    final response = await _apiClient.get<PageResult<JobListVO>>(
      '/jobs',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<JobListVO>.fromJson(
        asJsonMap(data),
        fromJson: JobListVO.fromJson,
      ),
    );
    return response;
  }

  Future<Map<String, dynamic>> createJob({required CreateJobBO request}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/jobs',
      data: request.toJson(),
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  Future<PageResult<JobDetailVO>> listMyJobs({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get<PageResult<JobDetailVO>>(
      '/jobs/mine',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<JobDetailVO>.fromJson(
        asJsonMap(data),
        fromJson: JobDetailVO.fromJson,
      ),
    );
    return response;
  }

  Future<void> deleteJob({required int jobId}) async {
    return _apiClient.deleteVoid('/jobs/$jobId');
  }

  Future<JobDetailVO> getJobDetail({required int jobId}) async {
    final response = await _apiClient.get<JobDetailVO>(
      '/jobs/$jobId',
      decode: (data) => JobDetailVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updateJob({
    required int jobId,
    required CreateJobBO request,
  }) async {
    return _apiClient.putVoid('/jobs/$jobId', data: request.toJson());
  }

  Future<void> updateJobStatus({
    required int jobId,
    required UpdateJobStatusBO request,
  }) async {
    return _apiClient.putVoid('/jobs/$jobId/status', data: request.toJson());
  }
}
