import 'package:bluehub_app/shared/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/payment/payment_flow_coordinator.dart';
import '../../../shared/network/services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(apiClient: ref.watch(apiClientProvider));
});

final paymentFlowCoordinatorProvider = Provider<PaymentFlowCoordinator>((ref) {
  return PaymentFlowCoordinator(
    paymentService: ref.watch(paymentServiceProvider),
  );
});
