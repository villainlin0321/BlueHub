import 'package:dio/dio.dart';
import 'package:europepass/features/auth/application/login/login_form_controller.dart';
import 'package:europepass/features/auth/data/auth_models.dart';
import 'package:europepass/features/auth/data/auth_providers.dart';
import 'package:europepass/features/auth/data/login_account_store.dart';
import 'package:europepass/features/me/data/user_models.dart';
import 'package:europepass/features/me/data/user_providers.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:europepass/shared/network/services/auth_service.dart';
import 'package:europepass/shared/network/services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('登录页重新进入后不保留上次验证码倒计时', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(_FakeAuthService())],
    );
    addTearDown(container.dispose);

    final ProviderSubscription<dynamic> subscription = container.listen(
      loginFormControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );

    final LoginFormController controller = container.read(
      loginFormControllerProvider.notifier,
    );

    controller.setAgreement(true);
    controller.updatePhone('13800138000');
    await controller.sendCode();

    expect(
      container.read(loginFormControllerProvider).resendCountdownSeconds,
      60,
    );

    subscription.close();
    await container.pump();

    final ProviderSubscription<dynamic> nextSubscription = container.listen(
      loginFormControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(nextSubscription.close);

    expect(
      container.read(loginFormControllerProvider).resendCountdownSeconds,
      0,
    );
  });

  test('邮箱登录成功后会缓存最近一次账号与登录方式', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(_FakeLoginAuthService()),
        userServiceProvider.overrideWithValue(_FakeUserService()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final LoginFormController controller = container.read(
      loginFormControllerProvider.notifier,
    );
    controller.setLoginMode(false);
    controller.setAgreement(true);
    controller.updateEmail('cached@example.com');
    controller.updateCode('123456');

    final LoginVO? result = await controller.submitLogin();

    expect(result, isNotNull);
    expect(
      container.read(loginAccountStoreProvider).load(),
      isA<CachedLoginAccount>()
          .having(
            (CachedLoginAccount account) => account.mode,
            'mode',
            LoginAccountMode.email,
          )
          .having(
            (CachedLoginAccount account) => account.account,
            'account',
            'cached@example.com',
          ),
    );
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
    : super(apiClient: ApiClient(Dio()), tokenStore: TokenStore.inMemory());

  @override
  Future<Map<String, int>> sendSms({required SendSmsBO request}) async {
    return <String, int>{'cooldown': 60};
  }
}

class _FakeLoginAuthService extends AuthService {
  _FakeLoginAuthService()
    : super(apiClient: ApiClient(Dio()), tokenStore: TokenStore.inMemory());

  @override
  Future<LoginVO> emailLogin({required EmailLoginBO request}) async {
    return LoginVO(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 3600,
      isNewUser: false,
      needSelectRole: false,
      user: UserSimpleVO(
        userId: 7,
        phone: '',
        countryCode: '+86',
        role: 'worker',
        avatarUrl: '',
        nickname: 'tester',
        email: request.email,
      ),
    );
  }
}

class _FakeUserService extends UserService {
  _FakeUserService() : super(apiClient: ApiClient(Dio()));

  @override
  Future<UserVO> getMe() async {
    return const UserVO(
      userId: 7,
      phone: '',
      email: 'cached@example.com',
      nickname: 'tester',
      avatarUrl: '',
      gender: '',
      birthday: '',
      role: 'worker',
      currentLocation: '',
      isVerified: false,
      blacklistCount: 0,
      createdAt: '2026-07-05T00:00:00Z',
    );
  }
}
