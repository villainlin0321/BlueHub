import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';

import 'collection_models.dart';
import '../../../shared/network/services/collection_service.dart';

final collectionServiceProvider = Provider<CollectionService>((ref) {
  return CollectionService(apiClient: ref.watch(apiClientProvider));
});

/// 收藏数据刷新信号：任一页面收藏状态变更后递增，供收藏页统一重拉真实接口。
final collectionRefreshTickProvider =
    NotifierProvider<CollectionRefreshTickNotifier, int>(
      CollectionRefreshTickNotifier.new,
    );

class CollectionRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// 递增收藏刷新信号，通知收藏页重新拉取真实收藏列表。
  void bump() {
    state = state + 1;
  }
}

/// 读取当前登录用户已收藏的签证套餐 ID 集合，供列表页同步收藏初始态。
final collectedVisaPackageIdsProvider = FutureProvider.autoDispose<Set<int>>((
  ref,
) async {
  ref.watch(collectionRefreshTickProvider);
  final response = await ref
      .read(collectionServiceProvider)
      .listCollectedPackages(page: 1, pageSize: 200);
  return response.list.map((VisaPackageVO item) => item.packageId).toSet();
});

/// 读取当前登录用户已收藏的岗位 ID 集合，供岗位列表页同步收藏初始态。
final collectedJobIdsProvider = FutureProvider.autoDispose<Set<int>>((
  ref,
) async {
  ref.watch(collectionRefreshTickProvider);
  final response = await ref
      .read(collectionServiceProvider)
      .listCollectedJobs(page: 1, pageSize: 200);
  return response.list.map((JobListVO item) => item.jobId).toSet();
});
