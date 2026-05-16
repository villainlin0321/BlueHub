import 'package:bluehub_app/features/jobs/data/job_models.dart';
import 'package:bluehub_app/features/shell/application/shell_role_provider.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_models.dart';
import '../../../shared/network/services/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService(apiClient: ref.watch(apiClientProvider));
});

/// 首页最新岗位 Provider，专门用于求职者首页首屏数据。
final homeLatestJobsProvider = FutureProvider.autoDispose<List<JobListVO>>((
  ref,
) async {
  final homeService = ref.watch(homeServiceProvider);
  return homeService.getLatestJobs(limit: 10);
});

/// 首页热门签证套餐 Provider，专门用于求职者首页首屏数据。
final homeHotVisaPackagesProvider =
    FutureProvider.autoDispose<List<HomeHotPackageVO>>((ref) async {
      final homeService = ref.watch(homeServiceProvider);
      return homeService.getHotVisaPackages(limit: 6);
    });

/// 首页统计 Provider，会在壳层角色切换时重新请求当前 activeRole 对应的统计数据。
final homeDashboardStatsProvider =
    FutureProvider.autoDispose<HomeDashboardStatsVO>((ref) async {
      ref.watch(shellRoleProvider);
      final homeService = ref.watch(homeServiceProvider);
      return homeService.getDashboardStats();
    });
