import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'package:bluehub_app/shared/network/page_result.dart';

import 'provider_models.dart';
import 'provider_service.dart';

final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService(apiClient: ref.watch(apiClientProvider));
});

/// 根据服务商 ID 获取服务商详情和套餐列表，供签证详情页商家模块使用。
final visaProviderDetailProvider = FutureProvider.autoDispose
    .family<VisaProviderDetailVO, int>((ref, providerId) async {
      final service = ref.watch(providerServiceProvider);
      return service.getProviderPackages(providerId: providerId);
    });

/// 根据服务商 ID 获取评价列表，供签证详情页评价模块使用。
final visaProviderReviewsProvider = FutureProvider.autoDispose
    .family<ReviewVO, int>((ref, providerId) async {
      final service = ref.watch(providerServiceProvider);
      return service.listProviderReviews(
        providerId: providerId,
        page: 1,
        pageSize: 20,
        sort: 'latest',
      );
    });

/// 根据签证列表页选中的标签获取服务商列表。
final visaProviderListProvider = FutureProvider.autoDispose
    .family<PageResult<VisaProviderListVO>, String?>((ref, tab) async {
      final service = ref.watch(providerServiceProvider);
      return service.listProviders(page: 1, pageSize: 50, tab: tab);
    });
