import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/jobs/data/application_models.dart';

class ApplicationService {
  ApplicationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 雇主端分页查询岗位收到的应聘列表。
  ///
  /// 可按岗位 `jobId`、分页参数和应聘状态 `status` 过滤。
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

  /// 求职者投递岗位。
  ///
  /// 请求体使用 `CreateApplicationBO`，当前只需要传 `jobId`。
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

  /// 求职者分页查询自己的投递记录。
  ///
  /// 支持按分页参数和投递状态 `status` 过滤。
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

  /// 雇主端更新应聘状态。
  ///
  /// 常用于把待处理应聘更新为 `interview`、`rejected`、`hired` 等状态。
  Future<void> updateStatus({
    required int applicationId,
    required UpdateApplicationStatusBO request,
  }) async {
    return _apiClient.putVoid(
      '/applications/$applicationId/status',
      data: request.toJson(),
    );
  }

  /// 求职者撤回自己的投递。
  Future<void> withdraw({required int applicationId}) async {
    return _apiClient.putVoid('/applications/$applicationId/withdraw');
  }
}
