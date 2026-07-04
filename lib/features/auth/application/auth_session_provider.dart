import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../me/data/user_providers.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../../shared/auth/token_store.dart';
import '../../../shared/logging/app_log_event.dart';
import '../../../shared/logging/app_log_facade.dart';
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
      // 关键日志：记录恢复链路已被调度，便于解释启动阶段为什么进入 hydrating。
      AppLogger.instance.info(
        'AUTH',
        '检测到本地 token，准备恢复会话',
        context: _buildTokenPresenceContext(tokenStore),
      );
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
      StateLog.transition(
        event: 'AUTH_RESTORE_FAIL',
        message: '恢复会话失败，未发现可用 token',
        level: AppLogLevel.warn,
        result: AppLogResult.fail,
        context: _buildTokenPresenceContext(tokenStore),
      );
      return;
    }

    final previousState = state;
    state = state.copyWith(isHydrating: true);
    final hydratingState = state;
    StateLog.transition(
      event: 'AUTH_RESTORE_START',
      message: '开始恢复会话',
      from: _describeState(previousState),
      to: _describeState(hydratingState),
      result: AppLogResult.pending,
      context: _buildTokenPresenceContext(tokenStore),
    );

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
      StateLog.transition(
        event: 'AUTH_RESTORE_SUCCESS',
        message: '恢复会话成功',
        // 成功事件必须承接启动中的 hydrating 态，才能真实回放完整迁移链路。
        from: _describeState(hydratingState),
        to: _describeState(state),
        result: AppLogResult.success,
        context: _buildUserContext(
          user: user,
          needSelectRole: needSelectRole,
          tokenStore: tokenStore,
        ),
      );
    } catch (error, stackTrace) {
      StateLog.transition(
        event: 'AUTH_RESTORE_FAIL',
        message: '恢复会话失败，准备清理登录态',
        // 失败事件同样要从 hydrating 出发，避免看起来像是直接从旧态跳到终态。
        from: _describeState(hydratingState),
        to: _describeState(const AuthSessionState()),
        level: AppLogLevel.error,
        result: AppLogResult.fail,
        context: <String, Object?>{
          ..._buildTokenPresenceContext(tokenStore),
          'clearReason': 'restore_session_failed',
        },
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
    final tokenStore = ref.read(tokenStoreProvider);
    final previousState = state;
    state = state.copyWith(isHydrating: true);
    final hydratingState = state;
    StateLog.transition(
      event: 'AUTH_REFRESH_START',
      message: '开始刷新当前用户信息',
      from: _describeState(previousState),
      to: _describeState(hydratingState),
      result: AppLogResult.pending,
      context: <String, Object?>{
        ..._buildTokenPresenceContext(tokenStore),
        'hasFallbackUser': fallbackUser != null,
      },
    );

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
      StateLog.transition(
        event: 'AUTH_REFRESH_SUCCESS',
        message: '刷新当前用户信息成功',
        // 成功事件需要基于当前 hydrating 态记录，避免丢失中间过渡节点。
        from: _describeState(hydratingState),
        to: _describeState(state),
        result: AppLogResult.success,
        context: _buildUserContext(
          user: user,
          needSelectRole: needSelectRole,
          tokenStore: tokenStore,
        ),
      );
    } catch (error, stackTrace) {
      if (fallbackUser == null) {
        StateLog.transition(
          event: 'AUTH_REFRESH_FAIL',
          message: '刷新当前用户信息失败，准备清理登录态',
          from: _describeState(hydratingState),
          to: _describeState(const AuthSessionState()),
          level: AppLogLevel.error,
          result: AppLogResult.fail,
          context: <String, Object?>{
            ..._buildTokenPresenceContext(tokenStore),
            'hasFallbackUser': false,
            'clearReason': 'refresh_current_user_failed',
          },
          error: error,
          stackTrace: stackTrace,
        );
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
      StateLog.transition(
        event: 'AUTH_REFRESH_FAIL',
        message: '刷新失败，已回退到登录返回的用户快照',
        from: _describeState(hydratingState),
        to: _describeState(state),
        level: AppLogLevel.error,
        result: AppLogResult.fail,
        context: <String, Object?>{
          ..._buildUserContext(
            user: fallbackUser,
            needSelectRole: needSelectRole,
            tokenStore: tokenStore,
          ),
          'hasFallbackUser': true,
          'fallbackApplied': true,
        },
        error: error,
        stackTrace: stackTrace,
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

  /// 构建鉴权日志的 token 存在性上下文，只记录布尔值避免泄露敏感内容。
  Map<String, Object?> _buildTokenPresenceContext(TokenStore tokenStore) {
    return <String, Object?>{
      'hasSessionCredential': (tokenStore.accessToken ?? '').isNotEmpty,
      'hasRefreshCredential': (tokenStore.refreshToken ?? '').isNotEmpty,
    };
  }

  /// 构建鉴权成功或失败后的关键用户上下文，供日志回放时快速定位身份状态。
  Map<String, Object?> _buildUserContext({
    required AuthUser user,
    required bool needSelectRole,
    required TokenStore tokenStore,
  }) {
    return <String, Object?>{
      ..._buildTokenPresenceContext(tokenStore),
      'userId': user.userId,
      'role': user.role,
      'needSelectRole': needSelectRole,
      'isVerified': user.isVerified,
    };
  }

  /// 将当前鉴权状态压缩成稳定标签，便于在日志里回放状态切换方向。
  String _describeState(AuthSessionState currentState) {
    if (currentState.isHydrating) {
      return 'hydrating';
    }
    if (!currentState.isAuthenticated) {
      return 'anonymous';
    }
    if (currentState.needSelectRole) {
      return 'authenticated_role_pending';
    }
    return 'authenticated_ready';
  }
}
