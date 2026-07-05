import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/auth/data/auth_models.dart';
import 'package:europepass/features/auth/data/auth_providers.dart';
import 'package:europepass/features/auth/presentation/login_phone_page.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/auth_service.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:europepass/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';

/// 验证登录页测试直登按钮会按真实链路先发码再登录。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('测试登录服务商会先获取验证码再登录', (WidgetTester tester) async {
    final _RecordingAuthService authService = _RecordingAuthService(
      failEmailLogin: true,
    );

    await pumpLoginPhonePage(tester, authService: authService);
    await tester.pumpAndSettle();

    final dynamic serviceProviderButton = tester.widget(
      find.byKey(AppTestKeys.loginTestServiceProviderButton),
    );
    (serviceProviderButton.onPressed as VoidCallback).call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      authService.events,
      <String>[
        'sendEmailCode:oulu@example.com:login',
        'emailLogin:oulu@example.com:123456',
      ],
    );
  });

  testWidgets('测试登录服务商在获取验证码失败后不会继续登录', (
    WidgetTester tester,
  ) async {
    final _RecordingAuthService authService = _RecordingAuthService(
      failSendEmailCode: true,
    );

    await pumpLoginPhonePage(tester, authService: authService);
    await tester.pumpAndSettle();

    final dynamic serviceProviderButton = tester.widget(
      find.byKey(AppTestKeys.loginTestServiceProviderButton),
    );
    (serviceProviderButton.onPressed as VoidCallback).call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      authService.events,
      <String>['sendEmailCode:oulu@example.com:login'],
    );
  });
}

/// 挂载登录页测试场景，并按需注入假的鉴权服务。
Future<void> pumpLoginPhonePage(
  WidgetTester tester, {
  AuthService? authService,
}) async {
  AppToast.configure();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      fallbackLocale: AppLocales.english,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          if (authService != null)
            authServiceProvider.overrideWithValue(authService),
        ],
        child: MaterialApp(
          builder: (BuildContext context, Widget? child) {
            final TransitionBuilder easyLoadingBuilder = EasyLoading.init();
            return easyLoadingBuilder(
              context,
              child ?? const SizedBox.shrink(),
            );
          },
          home: const LoginPhonePage(),
        ),
      ),
    ),
  );
}

class _RecordingAuthService extends AuthService {
  _RecordingAuthService({
    this.failSendEmailCode = false,
    this.failEmailLogin = false,
  }) : super(apiClient: ApiClient(Dio()), tokenStore: TokenStore.inMemory());

  final bool failSendEmailCode;
  final bool failEmailLogin;
  final List<String> events = <String>[];

  @override
  /// 记录测试登录按钮触发的邮箱发码行为，便于断言调用顺序。
  Future<Map<String, int>> sendEmailCode({required SendEmailBO request}) async {
    events.add('sendEmailCode:${request.email}:${request.scene}');
    if (failSendEmailCode) {
      throw Exception('send-email-code-failed');
    }
    return <String, int>{'cooldown': 60};
  }

  @override
  /// 记录邮箱验证码登录行为，并按测试需要控制成功或失败。
  Future<LoginVO> emailLogin({required EmailLoginBO request}) async {
    events.add('emailLogin:${request.email}:${request.code}');
    if (failEmailLogin) {
      throw Exception('email-login-failed');
    }
    return LoginVO(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresIn: 3600,
      isNewUser: false,
      needSelectRole: false,
      user: const UserSimpleVO(
        userId: 1,
        phone: '',
        countryCode: '+86',
        role: 'service_provider',
        avatarUrl: '',
        nickname: 'tester',
        email: 'oulu@example.com',
      ),
    );
  }
}
