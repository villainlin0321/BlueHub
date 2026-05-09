import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../me/data/user_providers.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../../shared/network/providers.dart';
import '../data/auth_models.dart';
import 'auth_role_mapper.dart';
import 'auth_session_state.dart';
import 'auth_user.dart';

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
      AuthSessionNotifier.new,
    );

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  bool _restoreScheduled = false;

  @override
  AuthSessionState build() {
    final tokenStore = ref.watch(tokenStoreProvider);
    final hasToken = (tokenStore.accessToken ?? '').isNotEmpty;
    if (!hasToken) {
      _restoreScheduled = false;
      return const AuthSessionState();
    }

    if (!_restoreScheduled) {
      _restoreScheduled = true;
      unawaited(Future<void>.microtask(restoreSession));
    }

    return const AuthSessionState(isHydrating: true);
  }

  Future<void> restoreSession() async {
    final tokenStore = ref.read(tokenStoreProvider);
    final hasToken = (tokenStore.accessToken ?? '').isNotEmpty;
    if (!hasToken) {
      state = const AuthSessionState();
      _restoreScheduled = false;
      return;
    }

    state = state.copyWith(isHydrating: true);

    try {
      final profile = await ref.read(userServiceProvider).getMe();
      final user = AuthUser.fromProfile(profile);
      final needSelectRole = user.role.trim().isEmpty;
      state = AuthSessionState(
        user: user,
        isAuthenticated: true,
        isHydrating: false,
        needSelectRole: needSelectRole,
      );
      _syncShellRole(user.role, needSelectRole: needSelectRole);
    } catch (_) {
      await clearSession();
    } finally {
      _restoreScheduled = false;
    }
  }

  Future<void> handleLoginResult(LoginVO login) async {
    final fallbackUser = AuthUser.fromLoginUser(login.user);
    state = AuthSessionState(
      user: fallbackUser,
      isAuthenticated: true,
      isHydrating: true,
      needSelectRole: login.needSelectRole,
    );
    _syncShellRole(fallbackUser.role, needSelectRole: login.needSelectRole);

    await refreshCurrentUser(
      fallbackUser: fallbackUser,
      preferredNeedSelectRole: login.needSelectRole,
    );
  }

  Future<void> refreshCurrentUser({
    AuthUser? fallbackUser,
    bool? preferredNeedSelectRole,
  }) async {
    state = state.copyWith(isHydrating: true);

    try {
      final profile = await ref.read(userServiceProvider).getMe();
      final user = AuthUser.fromProfile(profile);
      final needSelectRole = user.role.trim().isEmpty
          ? (preferredNeedSelectRole ?? true)
          : false;
      state = AuthSessionState(
        user: user,
        isAuthenticated: true,
        isHydrating: false,
        needSelectRole: needSelectRole,
      );
      _syncShellRole(user.role, needSelectRole: needSelectRole);
    } catch (_) {
      if (fallbackUser == null) {
        await clearSession();
        return;
      }

      final needSelectRole = preferredNeedSelectRole ??
          fallbackUser.role.trim().isEmpty;
      state = AuthSessionState(
        user: fallbackUser,
        isAuthenticated: true,
        isHydrating: false,
        needSelectRole: needSelectRole,
      );
      _syncShellRole(fallbackUser.role, needSelectRole: needSelectRole);
    }
  }

  Future<void> clearSession() async {
    ref.read(tokenStoreProvider).clear();
    state = const AuthSessionState();
  }

  void _syncShellRole(String role, {required bool needSelectRole}) {
    if (needSelectRole || role.trim().isEmpty) {
      return;
    }

    ref.read(shellRoleProvider.notifier).setRole(shellRoleFromApiRole(role));
  }
}
