import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../auth/application/auth_session_provider.dart';
import 'employer_models.dart';
import '../../../shared/network/services/employer_service.dart';

final employerServiceProvider = Provider<EmployerService>((ref) {
  return EmployerService(
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

final employerPublicProfileProvider =
    FutureProvider.autoDispose.family<EmployerPublicVO, int>((
      ref,
      profileId,
    ) async {
      return ref
          .watch(employerServiceProvider)
          .getPublicProfile(profileId: profileId);
    });
