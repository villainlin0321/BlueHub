import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';

import '../../../shared/network/page_result.dart';
import 'visa_package_models.dart';
import '../../../shared/network/services/visa_package_service.dart';

final visaPackageServiceProvider = Provider<VisaPackageService>((ref) {
  return VisaPackageService(apiClient: ref.watch(apiClientProvider));
});

/// 我的签证套餐列表刷新信号：编辑、发布、草稿保存后递增，供套餐管理页统一刷新。
final visaPackageListRefreshTickProvider =
    NotifierProvider<VisaPackageListRefreshTickNotifier, int>(
      VisaPackageListRefreshTickNotifier.new,
    );

class VisaPackageListRefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}

/// 根据套餐 ID 获取签证套餐详情，供签证详情页按需读取真实数据。
final visaPackageDetailProvider = FutureProvider.autoDispose
    .family<VisaPackageVO, int>((ref, packageId) async {
      final service = ref.watch(visaPackageServiceProvider);
      return service.getPackageDetail(packageId: packageId);
    });

/// 根据套餐 ID 获取签证套餐编辑态详情，供服务商编辑页回填使用。
final visaPackageEditDetailProvider = FutureProvider.autoDispose
    .family<VisaPackageEditVO, int>((ref, packageId) async {
      final service = ref.watch(visaPackageServiceProvider);
      return service.getPackageEditDetail(packageId: packageId);
    });

/// 根据服务商套餐状态获取我的套餐列表。
final myVisaPackageListProvider =
    FutureProvider.family<PageResult<VisaPackageVO>, String>((
      ref,
      status,
    ) async {
      final service = ref.watch(visaPackageServiceProvider);
      return service.listMyPackages(page: 1, pageSize: 20, status: status);
    });
