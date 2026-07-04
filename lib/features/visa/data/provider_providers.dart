import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:europepass/shared/network/page_result.dart';

import '../../auth/application/auth_session_provider.dart';
import 'provider_models.dart';
import '../../../shared/network/services/provider_service.dart';

final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService(
    apiClient: ref.watch(apiClientProvider),
    onProfileUpdated: () async {
      final authSession = ref.read(authSessionProvider);
      await ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUser(
            fallbackUser: authSession.user,
            preferredNeedSelectRole: authSession.needSelectRole,
          );
      ref.invalidateSelf();
    },
  );
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
    .family<PageResult<VisaProviderListVO>, VisaProviderListQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(providerServiceProvider);
      return service.listProviders(
        page: query.page,
        pageSize: query.pageSize,
        tab: query.tab,
        keyword: query.keyword,
      );
    });

class VisaProviderListQuery {
  const VisaProviderListQuery({
    this.page = 1,
    this.pageSize = 50,
    this.tab,
    this.keyword,
  });

  final int page;
  final int pageSize;
  final String? tab;
  final String? keyword;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VisaProviderListQuery &&
            runtimeType == other.runtimeType &&
            page == other.page &&
            pageSize == other.pageSize &&
            tab == other.tab &&
            keyword == other.keyword;
  }

  @override
  int get hashCode => Object.hash(page, pageSize, tab, keyword);
}
