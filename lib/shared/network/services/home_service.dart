import 'package:bluehub_app/features/jobs/data/job_models.dart';
import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';

import '../../../features/home/data/home_models.dart';

class HomeService {
  HomeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取首页最新欧洲岗位列表，默认按接口约定请求首屏 10 条。
  Future<List<JobListVO>> getLatestJobs({int? limit}) async {
    final Map<String, dynamic>? queryParameters = limit == null
        ? null
        : <String, dynamic>{'limit': limit};
    final response = await _apiClient.get<List<JobListVO>>(
      '/home/latest-jobs',
      queryParameters: queryParameters,
      decode: (data) => decodeModelList<JobListVO>(data, JobListVO.fromJson),
    );
    return response;
  }

  /// 获取首页热门签证套餐列表，默认按接口约定请求首屏 6 条。
  Future<List<HomeHotPackageVO>> getHotVisaPackages({int? limit}) async {
    final Map<String, dynamic>? queryParameters = limit == null
        ? null
        : <String, dynamic>{'limit': limit};
    final response = await _apiClient.get<List<HomeHotPackageVO>>(
      '/home/hot-visa-packages',
      queryParameters: queryParameters,
      decode: (data) =>
          decodeModelList<HomeHotPackageVO>(data, HomeHotPackageVO.fromJson),
    );
    return response;
  }

  /// 获取当前角色首页统计数据，接口 data 结构会随 activeRole 变化。
  Future<HomeDashboardStatsVO> getDashboardStats() async {
    final response = await _apiClient.get<HomeDashboardStatsVO>(
      '/home/stats',
      decode: (data) => HomeDashboardStatsVO.fromJson(asJsonMap(data)),
    );
    return response;
  }
}
