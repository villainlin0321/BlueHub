import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_step_three_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/ui/test_keys.dart';

/// 验证认证第三步页面在返回时会按是否存在未保存改动决定是否拦截。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('认证第三步未改动时返回会直接离开页面', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepThreeTestApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepThree),
      findsOneWidget,
    );

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(find.text('test-root-page'), findsOneWidget);
    expect(find.text('现在退出，内容将不会保存'), findsNothing);
  });

  testWidgets('认证第三步修改从业年限后通过系统返回会弹出确认框', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepThreeTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldQualificationYearsOfService),
      '3',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepThree),
      findsOneWidget,
    );
    expect(find.text('test-root-page'), findsNothing);
  });

  testWidgets('认证第三步修改从业年限后点击确定会真实离开页面', (WidgetTester tester) async {
    final _RecordingNavigatorObserver navigatorObserver =
        _RecordingNavigatorObserver();

    await tester.pumpWidget(
      buildQualificationStepThreeTestApp(navigatorObserver: navigatorObserver),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldQualificationYearsOfService),
      '3',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('test-root-page'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepThree),
      findsNothing,
    );
    expect(navigatorObserver.poppedRouteNames, contains('/step-three'));
  });
}

/// 构建带导航栈的第三步页面测试环境，便于验证返回拦截行为。
Widget buildQualificationStepThreeTestApp({
  NavigatorObserver? navigatorObserver,
}) {
  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    fallbackLocale: AppLocales.english,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    useOnlyLangCode: true,
    child: ProviderScope(
      child: MaterialApp(
        initialRoute: '/step-three',
        navigatorObservers: navigatorObserver == null
            ? const <NavigatorObserver>[]
            : <NavigatorObserver>[navigatorObserver],
        routes: <String, WidgetBuilder>{
          '/': (_) => const Scaffold(body: Center(child: Text('test-root-page'))),
          '/step-three': (_) => QualificationCertificationStepThreePage(
                args: QualificationCertificationPageArgs(),
              ),
        },
      ),
    ),
  );
}

/// 记录页面级路由弹栈结果，便于断言当前页是否已经真实离开导航栈。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> poppedRoutes = <Route<dynamic>>[];

  /// 提取带名字的已弹出路由，避免把无名弹窗路由当成页面路由。
  List<String> get poppedRouteNames => poppedRoutes
      .map((Route<dynamic> route) => route.settings.name)
      .whereType<String>()
      .toList(growable: false);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.didPop(route, previousRoute);
  }
}
