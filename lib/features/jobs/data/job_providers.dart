import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

import 'job_models.dart';
import 'job_service.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService(apiClient: ref.watch(apiClientProvider));
});

/// 求职者岗位列表 Provider。
///
/// 当前先按首页首屏场景请求第 1 页最新岗位，后续接搜索和筛选时，
/// 只需要把查询条件收敛到新的参数 Provider 即可。
final jobSeekerJobsProvider = FutureProvider.autoDispose<PageResult<JobListVO>>((
  ref,
) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.listJobs(page: 1, pageSize: 20, sort: 'latest');
});
