import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluehub_app/app/app.dart';
import 'package:bluehub_app/features/auth/presentation/login_phone_page.dart';
import 'package:bluehub_app/shared/localization/app_locales.dart';

/// Widget 测试入口
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('基础渲染：进入首页', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: const ProviderScope(child: App()),
      ),
    );
    await tester.pumpAndSettle();

    // 关键点：只做冒烟测试，确保路由与首页 UI 能正常渲染。
    expect(find.byType(LoginPhonePage), findsOneWidget);
  });
}
