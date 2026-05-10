import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';

import 'visa_package_models.dart';
import 'visa_package_service.dart';

final visaPackageServiceProvider = Provider<VisaPackageService>((ref) {
  return VisaPackageService(apiClient: ref.watch(apiClientProvider));
});

/// 根据套餐 ID 获取签证套餐详情，供签证详情页按需读取真实数据。
final visaPackageDetailProvider = FutureProvider.autoDispose
    .family<VisaPackageVO, int>((ref, packageId) async {
      final service = ref.watch(visaPackageServiceProvider);
      return service.getPackageDetail(packageId: packageId);
    });
