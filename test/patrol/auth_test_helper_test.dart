import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/helpers/auth_test_helper.dart';

/// 覆盖服务商登录态判断，避免 Patrol 误复用到其他角色会话。
void main() {
  test('服务商已登录且无需选角色时返回 true', () {
    final authSession = AuthSessionState(
      user: _buildAuthUser(role: 'visa_provider'),
      isAuthenticated: true,
      needSelectRole: false,
    );

    expect(isServiceProviderAuthenticatedSession(authSession), isTrue);
  });

  test('企业角色不会被识别为服务商登录态', () {
    final authSession = AuthSessionState(
      user: _buildAuthUser(role: 'employer'),
      isAuthenticated: true,
      needSelectRole: false,
    );

    expect(isServiceProviderAuthenticatedSession(authSession), isFalse);
  });

  test('待选角色会话不会被识别为服务商登录态', () {
    final authSession = AuthSessionState(
      user: _buildAuthUser(role: ''),
      isAuthenticated: true,
      needSelectRole: true,
    );

    expect(isServiceProviderAuthenticatedSession(authSession), isFalse);
  });
}

/// 构造测试用登录用户，减少每个用例重复拼装字段。
AuthUser _buildAuthUser({required String role}) {
  return AuthUser(
    userId: 1,
    phone: '',
    countryCode: '',
    email: 'tester@example.com',
    nickname: 'tester',
    avatarUrl: '',
    role: role,
    gender: '',
    birthday: '',
    currentLocation: '',
    isVerified: false,
  );
}
