import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_role_mapper.dart';
import '../../application/auth_session_provider.dart';
import '../../data/auth_models.dart';
import '../../data/auth_providers.dart';
import '../../../shell/application/shell_role_provider.dart';
import 'select_role_state.dart';

final selectRoleControllerProvider =
    NotifierProvider<SelectRoleController, SelectRoleState>(
      SelectRoleController.new,
    );

class SelectRoleController extends Notifier<SelectRoleState> {
  @override
  SelectRoleState build() {
    final authUserRole = ref.read(authSessionProvider).user?.role.trim() ?? '';
    final initialRoleId = authUserRole.isNotEmpty
        ? apiRoleFromSelection(authUserRole)
        : apiRoleFromShellRole(ref.read(shellRoleProvider));
    return SelectRoleState(selectedRoleId: initialRoleId);
  }

  void setSelectedRole(String roleId) {
    state = state.copyWith(selectedRoleId: roleId);
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  Future<bool> submitSelection() async {
    final selectedRoleId = state.selectedRoleId;
    if (selectedRoleId == null || selectedRoleId.isEmpty) {
      _emitFeedback('请选择角色', isError: true);
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final login = await ref.read(authServiceProvider).selectRole(
            request: SelectRoleBO(role: apiRoleFromSelection(selectedRoleId)),
          );
      await ref.read(authSessionProvider.notifier).handleLoginResult(login);
      return true;
    } catch (_) {
      _emitFeedback('角色选择失败，请稍后重试', isError: true);
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  void _emitFeedback(String message, {bool isError = false}) {
    state = state.copyWith(
      feedbackMessage: message,
      feedbackIsError: isError,
      feedbackId: state.feedbackId + 1,
    );
  }
}
