import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/auth/presentation/login_phone_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';

/// 验证登录页测试直登场景会默认填入统一的测试验证码。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('登录页默认测试验证码为 123456', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: const ProviderScope(
          child: MaterialApp(home: LoginPhonePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 关键断言：直接读取验证码输入框控制器，避免文本未渲染到可见节点时误判。
    final TextField codeField = tester.widgetList<TextField>(
      find.byType(TextField),
    ).last;

    expect(codeField.controller?.text, '123456');
  });
}
