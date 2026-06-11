import 'package:bluehub_app/shared/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(apiClient: ref.watch(apiClientProvider));
});
