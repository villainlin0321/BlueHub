import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/auth/application/login/login_form_state.dart';
import 'package:europepass/features/auth/presentation/widgets/login_phone_view.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  test('登录页测试登录按钮使用 kDebugMode 控制渲染', () {
    final sourceFile = File(
      'lib/features/auth/presentation/widgets/login_phone_view.dart',
    );

    final source = sourceFile.readAsStringSync();

    expect(source, contains('if (kDebugMode)'));
  });

  testWidgets('debug 构建显示测试登录服务商按钮', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: MaterialApp(
          home: Scaffold(
            body: LoginPhoneView(
              state: const LoginFormState(),
              isChineseSelected: true,
              phoneController: TextEditingController(),
              emailController: TextEditingController(),
              codeController: TextEditingController(),
              onRegionTap: () {},
              onLanguageChanged: (_) {},
              onLoginModeChanged: (_) {},
              onPhoneChanged: (_) {},
              onEmailChanged: (_) {},
              onCodeChanged: (_) {},
              onSendCode: () {},
              onLogin: () {},
              onTestWorkerLogin: () {},
              onTestServiceProviderLogin: () {},
              onTestEmployerLogin: () {},
              onAgreementChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppTestKeys.loginTestServiceProviderButton),
      kDebugMode ? findsOneWidget : findsNothing,
    );
  });
}
