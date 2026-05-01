import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import 'visa_order_service.dart';

final visaOrderServiceProvider = Provider<VisaOrderService>((ref) {
  return VisaOrderService(apiClient: ref.watch(apiClientProvider));
});
