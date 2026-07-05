import 'dart:convert';
import 'dart:io';

import 'package:europepass/app/router/route_paths.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/auth/application/auth_session_provider.dart';
import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
import 'package:europepass/features/home/data/home_models.dart';
import 'package:europepass/features/home/data/home_providers.dart';
import 'package:europepass/features/files/data/file_models.dart';
import 'package:europepass/features/files/data/file_providers.dart';
import 'package:europepass/features/me/data/user_models.dart';
import 'package:europepass/features/me/data/user_providers.dart';
import 'package:europepass/features/me/presentation/job_seeker_real_name_verification_page.dart';
import 'package:europepass/features/me/presentation/role_pages/job_seeker_me_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_exception.dart';
import 'package:europepass/shared/network/services/file_service.dart';
import 'package:europepass/shared/network/services/user_service.dart';
import 'package:europepass/shared/widgets/app_toast.dart';
import 'package:europepass/utils/upload_picker_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  testWidgets('未实名用户点击实名认证入口会通过真实 GoRouter 进入已注册实名页', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _createAuthenticatedContainer(
      isVerified: false,
    );
    final GoRouter router = _buildRealNameTestRouter();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      _buildGoRouterRealNameTestHost(
        container: container,
        router: router,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final Finder realNameEntry = find.text('您还未实名，点击去实名认证');
    expect(realNameEntry, findsOneWidget);

    await tester.tap(realNameEntry);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('实名认证'),
      ),
      findsOneWidget,
    );
    expect(
      router.state.uri.toString(),
      RoutePaths.jobSeekerRealNameVerification,
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

  testWidgets('实名表单完整提交时会按后端契约提交人像面 front 与国徽面 back', (
    WidgetTester tester,
  ) async {
    final _FakeRealNameUserService userService = _FakeRealNameUserService();
    final _FakeRealNameFileService fileService = _FakeRealNameFileService(
      uploadedUrlsByPath: <String, String>{
        '/tmp/emblem.png': 'https://example.com/emblem-uploaded.png',
        '/tmp/portrait.png': 'https://example.com/portrait-uploaded.png',
      },
    );
    final _FakeImagePicker imagePicker = _FakeImagePicker(
      files: <PickedUploadFile>[
        _buildPickedUploadFile(name: 'emblem.png', path: '/tmp/emblem.png'),
        _buildPickedUploadFile(name: 'portrait.png', path: '/tmp/portrait.png'),
      ],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        homeDashboardStatsProvider.overrideWith(
          (Ref ref) => const HomeDashboardStatsVO(
            monthlyIncome: '0',
            incomeCurrency: 'CNY',
          ),
        ),
        userServiceProvider.overrideWithValue(userService),
        fileServiceProvider.overrideWithValue(fileService),
      ],
    );
    container.read(authSessionProvider.notifier).state = AuthSessionState(
      user: const AuthUser(
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
        isVerified: false,
      ),
      isAuthenticated: true,
      isHydrating: false,
      needSelectRole: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
        verificationPageBuilder: () => JobSeekerRealNameVerificationPage(
          pickImages:
              (BuildContext context) async => imagePicker.pickImages(context),
          showToast: (String message) async {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('您还未实名，点击去实名认证'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('real-name-input')), '张三');
    await tester.enterText(find.byKey(const Key('id-card-input')), '110101199003047777');
    await tester.tap(find.byKey(const Key('id-card-emblem-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('id-card-portrait-upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('real-name-submit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(userService.lastRealNameRequest?.realName, '张三');
    expect(
      userService.lastRealNameRequest?.idCardNumber,
      '110101199003047777',
    );
    expect(
      userService.lastRealNameRequest?.idCardFrontUrl,
      'https://example.com/portrait-uploaded.png',
    );
    expect(
      userService.lastRealNameRequest?.idCardBackUrl,
      'https://example.com/emblem-uploaded.png',
    );
    expect(fileService.uploadedPaths, <String>['/tmp/emblem.png', '/tmp/portrait.png']);
    expect(container.read(authSessionProvider).user?.isVerified, isTrue);
    expect(find.text('已完成实名认证'), findsOneWidget);
  });

  testWidgets('实名提交成功后即使刷新 `/users/me` 失败也会返回并提示真实语义', (
    WidgetTester tester,
  ) async {
    final _FakeRealNameUserService userService = _FakeRealNameUserService(
      failGetMeAfterRealNameVerify: true,
    );
    final _FakeRealNameFileService fileService = _FakeRealNameFileService(
      uploadedUrlsByPath: <String, String>{
        '/tmp/emblem.png': 'https://example.com/emblem-uploaded.png',
        '/tmp/portrait.png': 'https://example.com/portrait-uploaded.png',
      },
    );
    final _FakeImagePicker imagePicker = _FakeImagePicker(
      files: <PickedUploadFile>[
        _buildPickedUploadFile(name: 'emblem.png', path: '/tmp/emblem.png'),
        _buildPickedUploadFile(name: 'portrait.png', path: '/tmp/portrait.png'),
      ],
    );
    final List<String> toastMessages = <String>[];
    final ProviderContainer container = ProviderContainer(
      overrides: [
        homeDashboardStatsProvider.overrideWith(
          (Ref ref) => const HomeDashboardStatsVO(
            monthlyIncome: '0',
            incomeCurrency: 'CNY',
          ),
        ),
        userServiceProvider.overrideWithValue(userService),
        fileServiceProvider.overrideWithValue(fileService),
      ],
    );
    container.read(authSessionProvider.notifier).state = AuthSessionState(
      user: const AuthUser(
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
        isVerified: false,
      ),
      isAuthenticated: true,
      isHydrating: false,
      needSelectRole: false,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildRealNameTestHost(
        container: container,
        verificationPageBuilder: () => JobSeekerRealNameVerificationPage(
          pickImages:
              (BuildContext context) async => imagePicker.pickImages(context),
          showToast: (String message) async {
            toastMessages.add(message);
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('您还未实名，点击去实名认证'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('real-name-input')), '张三');
    await tester.enterText(find.byKey(const Key('id-card-input')), '110101199003047777');
    await tester.tap(find.byKey(const Key('id-card-emblem-upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('id-card-portrait-upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('real-name-submit-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider).isAuthenticated, isTrue);
    expect(container.read(authSessionProvider).user?.isVerified, isFalse);
    expect(find.byKey(const Key('real-name-submit-button')), findsNothing);
    expect(find.text('已完成实名认证'), findsNothing);
    expect(toastMessages, isNotEmpty);
    expect(toastMessages.last, '实名认证提交成功，但资料刷新失败，请稍后重新进入查看');
    expect(toastMessages, isNot(contains('实名认证提交失败，请稍后重试')));
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
Widget _buildRealNameTestHost({
  required ProviderContainer container,
  Widget Function()? verificationPageBuilder,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: _RealNameTestApp(
        verificationPageBuilder: verificationPageBuilder,
      ),
    ),
  );
}

/// 构建使用真实 `GoRouter` 的测试宿主，覆盖入口点击到路由注册的完整链路。
Widget _buildGoRouterRealNameTestHost({
  required ProviderContainer container,
  required GoRouter router,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: _GoRouterRealNameTestApp(router: router),
    ),
  );
}

/// 构建测试专用 GoRouter，避免手动 push 绕过求职者“我的”页到实名页的真实跳转链。
GoRouter _buildRealNameTestRouter() {
  return GoRouter(
    initialLocation: RoutePaths.me,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.me,
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          body: JobSeekerMePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.jobSeekerRealNameVerification,
        builder: (BuildContext context, GoRouterState state) =>
            const JobSeekerRealNameVerificationPage(),
      ),
    ],
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

/// 通过真实 `GoRouter` 渲染应用外壳，避免测试宿主手动 push 绕过路由注册链。
class _GoRouterRealNameTestApp extends StatelessWidget {
  const _GoRouterRealNameTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    AppToast.configure();
    return MaterialApp.router(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        final TransitionBuilder easyLoadingBuilder = EasyLoading.init();
        return easyLoadingBuilder(context, child ?? const SizedBox.shrink());
      },
    );
  }
}

/// 提供最小可运行的页面宿主，覆盖“我的”页入口到实名认证占位页的真实跳转链路。
class _RealNameTestApp extends StatelessWidget {
  const _RealNameTestApp({this.verificationPageBuilder});

  final Widget Function()? verificationPageBuilder;

  @override
  Widget build(BuildContext context) {
    AppToast.configure();
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: (BuildContext context, Widget? child) {
        final TransitionBuilder easyLoadingBuilder = EasyLoading.init();
        return easyLoadingBuilder(context, child ?? const SizedBox.shrink());
      },
      home: Scaffold(
        body: JobSeekerMePage(
          onRealNameEntryTapOverride: (BuildContext context) {
            // 关键路径：测试中使用真实 Navigator 承接页面跳转，稳定验证落页标题。
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    verificationPageBuilder?.call() ??
                    const JobSeekerRealNameVerificationPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 生成测试用上传文件，统一复用实名成功场景中的本地/远端图片数据。
PickedUploadFile _buildPickedUploadFile({
  required String name,
  required String path,
  String? uploadedFileUrl,
}) {
  return PickedUploadFile(
    id: name,
    name: name,
    path: path,
    sourceType: UploadSourceType.gallery,
    state: UploadItemState.success,
    isImage: true,
    uploadedFileUrl: uploadedFileUrl,
  );
}

/// 实名提交测试替身：记录请求体，并在提交成功后让 `getMe()` 返回已实名资料。
class _FakeRealNameUserService extends UserService {
  _FakeRealNameUserService({
    this.failGetMeAfterRealNameVerify = false,
  })
    : _profile = _buildFakeUserProfile(isVerified: false),
      super(apiClient: ApiClient(Dio()));

  UserVO _profile;
  final bool failGetMeAfterRealNameVerify;
  bool _hasSubmittedRealName = false;
  RealNameVerifyBO? lastRealNameRequest;

  @override
  /// 返回当前模拟的 `/users/me` 数据，供实名成功后的会话刷新读取。
  Future<UserVO> getMe() async {
    if (failGetMeAfterRealNameVerify && _hasSubmittedRealName) {
      throw ApiException.unknown('get me failed');
    }
    return _profile;
  }

  @override
  /// 记录实名请求，并把后续 `getMe()` 结果切换为已实名状态。
  Future<void> realNameVerify({required RealNameVerifyBO request}) async {
    _hasSubmittedRealName = true;
    lastRealNameRequest = request;
    _profile = _buildFakeUserProfile(isVerified: true);
  }
}

/// 文件上传测试替身：记录上传路径，并返回预置的远端文件地址。
class _FakeRealNameFileService extends FileService {
  _FakeRealNameFileService({
    required this.uploadedUrlsByPath,
  }) : super(apiClient: ApiClient(Dio()));

  final Map<String, String> uploadedUrlsByPath;
  final List<String> uploadedPaths = <String>[];

  @override
  /// 模拟身份证图片上传，确保测试覆盖“先上传再提交”的真实生产分支。
  Future<FilePresignVO> uploadFile({
    required String path,
    required FileScene scene,
    String accessType = 'PUBLIC',
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    uploadedPaths.add(path);
    onSendProgress?.call(1, 1);
    return FilePresignVO(
      uploadUrl: 'https://upload.example.com/${uploadedPaths.length}',
      fileUrl: uploadedUrlsByPath[path] ?? 'https://example.com/unknown.png',
      expireIn: 3600,
      objectKey: 'object-${uploadedPaths.length}',
      fileId: uploadedPaths.length,
    );
  }
}

/// 图片选择测试替身：按顺序返回预置图片，模拟用户先后选择身份证正反面。
class _FakeImagePicker {
  _FakeImagePicker({required List<PickedUploadFile> files})
    : _files = List<PickedUploadFile>.from(files);

  final List<PickedUploadFile> _files;

  /// 按点击顺序出队图片，保证两次上传操作拿到不同的远端地址。
  Future<List<PickedUploadFile>> pickImages(BuildContext context) async {
    if (_files.isEmpty) {
      return const <PickedUploadFile>[];
    }
    return <PickedUploadFile>[_files.removeAt(0)];
  }
}

/// 生成测试用户资料，确保“我的”页与会话刷新共用同一份实名状态来源。
UserVO _buildFakeUserProfile({required bool isVerified}) {
  return UserVO(
    userId: 1001,
    phone: '13812345678',
    email: 'jobseeker@example.com',
    nickname: '测试求职者',
    avatarUrl: '',
    gender: 'male',
    birthday: '1990-01-01',
    role: 'job_seeker',
    currentLocation: 'Shanghai',
    isVerified: isVerified,
    blacklistCount: 0,
    createdAt: '2026-01-01T00:00:00Z',
  );
}
