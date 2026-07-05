import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_step_two_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/ui/test_keys.dart';

/// 验证认证第二步页面在返回时会按是否存在未保存改动决定是否拦截。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('认证第二步未改动时返回会直接离开页面', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepTwoTestApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsOneWidget,
    );

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(find.text('test-root-page'), findsOneWidget);
    expect(find.text('现在退出，内容将不会保存'), findsNothing);
  });

  testWidgets('认证第二步存在已选资质图片时点击页面返回按钮会弹出确认框', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepTwoTestApp());
    await tester.pumpAndSettle();

    final dynamic state = tester.state(
      find.byType(QualificationCertificationStepTwoPage),
    );
    await state.debugSetBusinessLicenseForTest('mock-path/image.png');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 通过 AppBar 返回按钮触发页面内返回链路，补齐与系统返回并列的回归入口。
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsOneWidget,
    );
    expect(find.text('test-root-page'), findsNothing);
  });

  testWidgets('认证第二步存在已选资质图片时通过系统返回会弹出确认框', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepTwoTestApp());
    await tester.pumpAndSettle();

    final dynamic state = tester.state(
      find.byType(QualificationCertificationStepTwoPage),
    );
    await state.debugSetBusinessLicenseForTest('mock-path/image.png');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 通过系统返回链路触发 PopScope，验证页面级返回按钮之外的真实拦截入口。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsOneWidget,
    );
    expect(find.text('test-root-page'), findsNothing);
  });

  testWidgets('认证第二步存在已选资质图片时通过系统返回后点击确定会真实离开页面', (WidgetTester tester) async {
    final _RecordingNavigatorObserver navigatorObserver =
        _RecordingNavigatorObserver();

    await tester.pumpWidget(
      buildQualificationStepTwoTestApp(navigatorObserver: navigatorObserver),
    );
    await tester.pumpAndSettle();

    final dynamic state = tester.state(
      find.byType(QualificationCertificationStepTwoPage),
    );
    await state.debugSetBusinessLicenseForTest('mock-path/image.png');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 通过系统返回链路先弹出未保存确认框，再验证确认后的真实弹栈结果。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('test-root-page'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsNothing,
    );
    expect(navigatorObserver.poppedRouteNames, contains('/step-two'));
  });
}

/// 构建带导航栈的第二步页面测试环境，便于验证返回拦截行为。
Widget buildQualificationStepTwoTestApp({
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
        initialRoute: '/step-two',
        navigatorObservers: navigatorObserver == null
            ? const <NavigatorObserver>[]
            : <NavigatorObserver>[navigatorObserver],
        routes: <String, WidgetBuilder>{
          '/': (_) => const Scaffold(body: Center(child: Text('test-root-page'))),
          '/step-two': (_) => QualificationCertificationStepTwoPage(
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
