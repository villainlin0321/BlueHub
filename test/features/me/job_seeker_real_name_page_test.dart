import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';
import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
import 'package:europepass/features/home/data/home_models.dart';
import 'package:europepass/features/home/data/home_providers.dart';
import 'package:europepass/features/me/presentation/job_seeker_real_name_verification_page.dart';
import 'package:europepass/features/me/presentation/role_pages/job_seeker_me_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('未实名用户会从我的页看到最终提示文案并跳转到实名认证页', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _createAuthenticatedContainer(
      isVerified: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final Finder realNameEntry = find.text('您还未实名，点击去实名认证');
    expect(realNameEntry, findsOneWidget);

    // 关键验收路径：从“我的”页真实入口点击进入实名认证占位页。
    await tester.tap(realNameEntry);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('实名认证'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('已实名用户会从我的页看到最终提示文案并可进入实名认证页', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _createAuthenticatedContainer(
      isVerified: true,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final Finder realNameEntry = find.text('已完成实名认证');
    expect(realNameEntry, findsOneWidget);
    expect(find.text('您还未实名，点击去实名认证'), findsNothing);

    // 已实名场景仍需保持入口可达，避免状态切换后丢失跳转能力。
    await tester.tap(realNameEntry);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('实名认证'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('实名页缺少必填项时会提示并阻止提交', (WidgetTester tester) async {
    final ProviderContainer container = _createAuthenticatedContainer(
      isVerified: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('您还未实名，点击去实名认证'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('同意并提交'));
    await tester.pump();

    expect(find.text('请填写姓名'), findsOneWidget);
    expect(find.text('请填写身份证号'), findsOneWidget);
    expect(find.text('请上传身份证国徽面'), findsOneWidget);
    expect(find.text('请上传身份证人像面'), findsOneWidget);
  });

  testWidgets('实名页在长屏下会把说明文案压到固定提交区上方', (WidgetTester tester) async {
    final TestFlutterView view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(375, 1000);
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final ProviderContainer container = _createAuthenticatedContainer(
      isVerified: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('您还未实名，点击去实名认证'));
    await tester.pumpAndSettle();

    final Finder instructionText = find.text(
      '本平台将采集和保存您的身份证照片，并将身份证照片提供至实名核验服务商，用于对您进行身份核验和资质审核',
    );
    final Finder submitButton = find.byKey(const Key('real-name-submit-button'));

    expect(find.text('姓名'), findsOneWidget);
    expect(find.text('身份证号'), findsOneWidget);
    expect(find.text('身份证验证'), findsOneWidget);
    expect(find.text('上传国徽面'), findsOneWidget);
    expect(find.text('上传人像面'), findsOneWidget);
    expect(instructionText, findsOneWidget);
    expect(submitButton, findsOneWidget);

    final Rect instructionRect = tester.getRect(instructionText);
    final Rect submitButtonRect = tester.getRect(submitButton);
    final double verticalGap = submitButtonRect.top - instructionRect.bottom;

    // 关键布局回归保护：长屏下说明文案要贴近固定底部按钮区，而不是停留在表单卡片下方。
    expect(instructionRect.bottom, lessThan(submitButtonRect.top));
    expect(verticalGap, lessThanOrEqualTo(48));
  });
}

/// 创建已登录的求职者测试容器，确保“我的”页读取到真实入口所需的用户态。
ProviderContainer _createAuthenticatedContainer({required bool isVerified}) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      homeDashboardStatsProvider.overrideWith(
        (Ref ref) => const HomeDashboardStatsVO(
          monthlyIncome: '0',
          incomeCurrency: 'CNY',
        ),
      ),
    ],
  );
  container.read(authSessionProvider.notifier).state = AuthSessionState(
    user: AuthUser(
      userId: 1001,
      phone: '13812345678',
      countryCode: '+86',
      email: 'jobseeker@example.com',
      nickname: '测试求职者',
      avatarUrl: '',
      role: 'job_seeker',
      gender: 'male',
      birthday: '1990-01-01',
      currentLocation: 'Shanghai',
      isVerified: isVerified,
    ),
    isAuthenticated: true,
    isHydrating: false,
    needSelectRole: false,
  );
  return container;
}

/// 构建带 EasyLocalization、Riverpod 与真实页面跳转的测试宿主。
Widget _buildRealNameTestHost({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: const _RealNameTestApp(),
    ),
  );
}

/// 测试环境直接从仓库读取翻译文件，避免 widget test 里资源 Bundle 未挂起导致空白页。
class _TestJsonFileAssetLoader extends AssetLoader {
  const _TestJsonFileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final File file = File('${Directory.current.path}/$path/${locale.languageCode}.json');
    final String content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// 提供最小可运行的页面宿主，覆盖“我的”页入口到实名认证占位页的真实跳转链路。
class _RealNameTestApp extends StatelessWidget {
  const _RealNameTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: Scaffold(
        body: JobSeekerMePage(
          onRealNameEntryTapOverride: (BuildContext context) {
            // 关键路径：测试中使用真实 Navigator 承接页面跳转，稳定验证落页标题。
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const JobSeekerRealNameVerificationPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
