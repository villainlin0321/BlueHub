import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_page.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_step_two_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/ui/test_keys.dart';

/// 验证认证第一页的必填身份证图片校验与未保存返回拦截。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('认证第一页未选择身份证图片时不能进入下一步', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepOneRouterTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppTestKeys.actionQualificationStepOneNext));
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepOne),
      findsOneWidget,
    );
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsNothing,
    );
    expect(find.text('请上传身份证国徽面'), findsOneWidget);
  });

  testWidgets('认证第一页选择身份证正反面后可以进入下一步', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepOneRouterTestApp());
    await tester.pumpAndSettle();

    final dynamic state = tester.state(
      find.byType(QualificationCertificationPage),
    );
    state.debugSetIdentityImagesForTest(
      emblemPath: 'mock-path/id-emblem.png',
      portraitPath: 'mock-path/id-portrait.png',
    );
    await tester.pump();

    await tester.tap(find.byKey(AppTestKeys.actionQualificationStepOneNext));
    await tester.pumpAndSettle();

    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepTwo),
      findsOneWidget,
    );
  });

  testWidgets('认证第一页存在未保存改动时通过系统返回会弹出确认框', (WidgetTester tester) async {
    await tester.pumpWidget(buildQualificationStepOneRouterTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldQualificationCompanyName),
      '欧路签证',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepOne),
      findsOneWidget,
    );
  });
}

/// 构建带 GoRouter 的第一页测试环境，便于验证“下一步”导航行为。
Widget buildQualificationStepOneRouterTestApp() {
  final QualificationCertificationPageArgs args =
      QualificationCertificationPageArgs();
  final GoRouter router = GoRouter(
    initialLocation: RoutePaths.qualificationCertification,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('test-root-page'))),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertification,
        builder: (_, __) => QualificationCertificationPage(args: args),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertificationStepTwo,
        builder: (_, __) => QualificationCertificationStepTwoPage(args: args),
      ),
    ],
  );

  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    fallbackLocale: AppLocales.english,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    useOnlyLangCode: true,
    child: ProviderScope(
      child: Builder(
        builder: (BuildContext context) {
          return MaterialApp.router(
            builder: EasyLoading.init(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: router,
          );
        },
      ),
    ),
  );
}
