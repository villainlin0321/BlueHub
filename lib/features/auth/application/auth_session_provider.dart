import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../me/data/user_providers.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../../shared/logging/app_logger.dart';
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
  /// 根据本地 token 决定是否恢复会话，并返回当前鉴权状态快照。
  AuthSessionState build() {
    final tokenStore = ref.watch(tokenStoreProvider);
    final hasToken = (tokenStore.accessToken ?? '').isNotEmpty;
    if (!hasToken) {
      _restoreScheduled = false;
      return const AuthSessionState();
    }

    if (!_restoreScheduled) {
      _restoreScheduled = true;
      AppLogger.instance.info('AUTH', '检测到本地 token，准备恢复会话');
      unawaited(Future<void>.microtask(restoreSession));
    }

    return const AuthSessionState(isHydrating: true);
  }

  /// 启动后用 `/users/me` 恢复完整用户信息，确保登录态可用。
  Future<void> restoreSession() async {
    final tokenStore = ref.read(tokenStoreProvider);
    final hasToken = (tokenStore.accessToken ?? '').isNotEmpty;
    if (!hasToken) {
      state = const AuthSessionState();
      _restoreScheduled = false;
      AppLogger.instance.warn('AUTH', '恢复会话时发现 token 已为空');
      return;
    }

    state = state.copyWith(isHydrating: true);
    AppLogger.instance.info('AUTH', '开始恢复会话');

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
      AppLogger.instance.info(
        'AUTH',
        '恢复会话成功',
        context: <String, Object?>{
          'userId': user.userId,
          'role': user.role,
          'needSelectRole': needSelectRole,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'AUTH',
        '恢复会话失败，准备清理登录态',
        error: error,
        stackTrace: stackTrace,
      );
      await clearSession(reason: 'restore_session_failed');
    } finally {
      _restoreScheduled = false;
    }
  }

  /// 登录完成后先建立临时态，再异步刷新完整用户资料。
  Future<void> handleLoginResult(LoginVO login) async {
    final fallbackUser = AuthUser.fromLoginUser(login.user);
    state = AuthSessionState(
      user: fallbackUser,
      isAuthenticated: true,
      isHydrating: true,
      needSelectRole: login.needSelectRole,
    );
    _syncShellRole(fallbackUser.role, needSelectRole: login.needSelectRole);
    AppLogger.instance.info(
      'AUTH',
      '登录结果已写入会话状态',
      context: <String, Object?>{
        'userId': fallbackUser.userId,
        'role': fallbackUser.role,
        'needSelectRole': login.needSelectRole,
      },
    );

    await refreshCurrentUser(
      fallbackUser: fallbackUser,
      preferredNeedSelectRole: login.needSelectRole,
    );
  }

  /// 刷新当前用户资料，优先使用服务端最新返回，失败时回退到登录态快照。
  Future<void> refreshCurrentUser({
    AuthUser? fallbackUser,
    bool? preferredNeedSelectRole,
  }) async {
    state = state.copyWith(isHydrating: true);
    AppLogger.instance.info('AUTH', '开始刷新当前用户信息');

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
      AppLogger.instance.info(
        'AUTH',
        '刷新当前用户信息成功',
        context: <String, Object?>{
          'userId': user.userId,
          'role': user.role,
          'needSelectRole': needSelectRole,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'AUTH',
        '刷新当前用户信息失败',
        error: error,
        stackTrace: stackTrace,
      );
      if (fallbackUser == null) {
        await clearSession(reason: 'refresh_current_user_failed');
        return;
      }

      final needSelectRole =
          preferredNeedSelectRole ?? fallbackUser.role.trim().isEmpty;
      state = AuthSessionState(
        user: fallbackUser,
        isAuthenticated: true,
        isHydrating: false,
        needSelectRole: needSelectRole,
      );
      _syncShellRole(fallbackUser.role, needSelectRole: needSelectRole);
      AppLogger.instance.warn(
        'AUTH',
        '刷新失败，已回退到登录返回的用户快照',
        context: <String, Object?>{
          'userId': fallbackUser.userId,
          'role': fallbackUser.role,
          'needSelectRole': needSelectRole,
        },
      );
    }
  }

  /// 清空本地登录态，并输出清理原因，便于排查会话丢失问题。
  Future<void> clearSession({String reason = 'manual'}) async {
    ref.read(tokenStoreProvider).clear();
    state = const AuthSessionState();
    AppLogger.instance.warn(
      'AUTH',
      '登录态已清空',
      context: <String, Object?>{'reason': reason},
    );
  }

  /// 将服务端角色同步到壳层 Tab 结构，保持页面导航与身份一致。
  void _syncShellRole(String role, {required bool needSelectRole}) {
    if (needSelectRole || role.trim().isEmpty) {
      AppLogger.instance.debug(
        'AUTH',
        '当前角色尚未完成同步',
        context: <String, Object?>{
          'role': role,
          'needSelectRole': needSelectRole,
        },
      );
      return;
    }

    ref.read(shellRoleProvider.notifier).setRole(shellRoleFromApiRole(role));
  }
}
