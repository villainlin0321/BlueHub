import 'auth_user.dart';

const Object _authUserSentinel = Object();

class AuthSessionState {
  const AuthSessionState({
    this.user,
    this.isAuthenticated = false,
    this.isHydrating = false,
    this.needSelectRole = false,
  });

  final AuthUser? user;
  final bool isAuthenticated;
  final bool isHydrating;
  final bool needSelectRole;

  AuthSessionState copyWith({
    Object? user = _authUserSentinel,
    bool? isAuthenticated,
    bool? isHydrating,
    bool? needSelectRole,
  }) {
    return AuthSessionState(
      user: identical(user, _authUserSentinel) ? this.user : user as AuthUser?,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isHydrating: isHydrating ?? this.isHydrating,
      needSelectRole: needSelectRole ?? this.needSelectRole,
    );
  }
}
