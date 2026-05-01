import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'visa_package_service.dart';

final visaPackageServiceProvider = Provider<VisaPackageService>((ref) {
  return VisaPackageService(apiClient: ref.watch(apiClientProvider));
});
