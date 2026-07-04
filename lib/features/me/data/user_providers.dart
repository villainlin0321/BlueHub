import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/shared/network/providers.dart';
import '../../../shared/network/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(apiClient: ref.watch(apiClientProvider));
});
