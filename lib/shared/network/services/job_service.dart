import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:europepass/shared/network/page_result.dart';
import '../../../features/jobs/data/job_models.dart';

class JobService {
  JobService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 分页查询岗位列表。
  ///
  /// 支持按国家、关键字、薪资区间、薪资币种、是否支持签证以及排序方式筛选。
  Future<PageResult<JobListVO>> listJobs({
    int? page,
    int? pageSize,
    String? country,
    String? keyword,
    double? salaryMin,
    double? salaryMax,
    String? currency,
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
      if (currency != null) 'currency': currency,
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

  /// 创建岗位。
  ///
  /// 提交 `request` 中的岗位信息后，返回接口原始结果，通常包含新岗位 ID 等字段。
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

  /// 分页查询当前雇主发布的岗位列表。
  ///
  /// 可按分页参数和岗位状态 `status` 过滤。
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

  /// 删除指定岗位。
  Future<void> deleteJob({required int jobId}) async {
    return _apiClient.deleteVoid('/jobs/$jobId');
  }

  /// 获取指定岗位的完整详情。
  Future<JobDetailVO> getJobDetail({required int jobId}) async {
    final response = await _apiClient.get<JobDetailVO>(
      '/jobs/$jobId',
      decode: (data) => JobDetailVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新指定岗位的基础信息。
  ///
  /// 使用 `CreateJobBO` 作为请求体，按后端约定提交完整岗位内容。
  Future<void> updateJob({
    required int jobId,
    required CreateJobBO request,
  }) async {
    return _apiClient.putVoid('/jobs/$jobId', data: request.toJson());
  }

  /// 更新岗位状态。
  ///
  /// `request.status` 支持：
  /// - `active`：上线
  /// - `inactive`：下线
  /// - `draft`：草稿
  Future<void> updateJobStatus({
    required int jobId,
    required UpdateJobStatusBO request,
  }) async {
    return _apiClient.putVoid('/jobs/$jobId/status', data: request.toJson());
  }
}
