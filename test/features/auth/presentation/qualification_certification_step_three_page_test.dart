import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_step_three_page.dart';
import 'package:europepass/features/files/data/file_models.dart';
import 'package:europepass/features/files/data/file_providers.dart';
import 'package:europepass/features/me/data/dictionary_providers.dart';
import 'package:europepass/features/visa/data/provider_models.dart';
import 'package:europepass/features/visa/data/provider_providers.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/models/dictionary_models.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/services/country_service.dart';
import 'package:europepass/shared/network/services/file_service.dart';
import 'package:europepass/shared/network/services/provider_service.dart';
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

  testWidgets('认证第三步提交时会先上传图片和资质，再提交基础资料', (WidgetTester tester) async {
    final List<String> events = <String>[];
    final _RecordingFileService fileService = _RecordingFileService(events);
    final _RecordingProviderService providerService = _RecordingProviderService(
      events,
    );

    await tester.pumpWidget(
      buildQualificationStepThreeTestApp(
        args: QualificationCertificationPageArgs(
          draft: QualificationCertificationDraft()
            ..serviceCountryLabels = <String>['德国']
            ..businessLicenseDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.businessLicense,
              docName: '营业执照',
              localPath: 'mock-path/business-license.png',
            )
            ..idCardEmblemDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.idCard,
              docName: '法人身份证国徽面',
              localPath: 'mock-path/id-emblem.png',
            )
            ..idCardPortraitDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.idCard,
              docName: '法人身份证人像面',
              localPath: 'mock-path/id-portrait.png',
            ),
        ),
        overrides: <dynamic>[
          fileServiceProvider.overrideWithValue(fileService),
          providerServiceProvider.overrideWithValue(providerService),
          countryServiceProvider.overrideWithValue(_FakeCountryService()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldQualificationYearsOfService),
      '3',
    );
    final dynamic state = tester.state(
      find.byType(QualificationCertificationStepThreePage),
    );
    await state.debugSubmitForTest();
    await tester.pump();

    expect(events, <String>[
      'file:cert:mock-path/business-license.png',
      'file:id_card:mock-path/id-emblem.png',
      'file:id_card:mock-path/id-portrait.png',
      'docs:3',
      'profile',
    ]);
  });

  testWidgets('认证第三步在资质提交失败时不会继续提交基础资料', (WidgetTester tester) async {
    final List<String> events = <String>[];
    final _RecordingFileService fileService = _RecordingFileService(events);
    final _RecordingProviderService providerService = _RecordingProviderService(
      events,
      failDocs: true,
    );

    await tester.pumpWidget(
      buildQualificationStepThreeTestApp(
        args: QualificationCertificationPageArgs(
          draft: QualificationCertificationDraft()
            ..serviceCountryLabels = <String>['德国']
            ..businessLicenseDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.businessLicense,
              docName: '营业执照',
              localPath: 'mock-path/business-license.png',
            )
            ..idCardEmblemDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.idCard,
              docName: '法人身份证国徽面',
              localPath: 'mock-path/id-emblem.png',
            )
            ..idCardPortraitDoc = const UploadedQualificationDoc(
              docType: QualificationDocType.idCard,
              docName: '法人身份证人像面',
              localPath: 'mock-path/id-portrait.png',
            ),
        ),
        overrides: <dynamic>[
          fileServiceProvider.overrideWithValue(fileService),
          providerServiceProvider.overrideWithValue(providerService),
          countryServiceProvider.overrideWithValue(_FakeCountryService()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldQualificationYearsOfService),
      '3',
    );
    final dynamic state = tester.state(
      find.byType(QualificationCertificationStepThreePage),
    );
    await state.debugSubmitForTest();
    await tester.pump(const Duration(seconds: 3));

    expect(events, isNot(contains('profile')));
    expect(events.last, 'docs:3');
    expect(
      find.byKey(AppTestKeys.pageQualificationCertificationStepThree),
      findsOneWidget,
    );
  });
}

/// 构建带导航栈的第三步页面测试环境，便于验证返回拦截行为。
Widget buildQualificationStepThreeTestApp({
  NavigatorObserver? navigatorObserver,
  QualificationCertificationPageArgs? args,
  List<dynamic> overrides = const <dynamic>[],
}) {
  final QualificationCertificationPageArgs resolvedArgs =
      args ?? QualificationCertificationPageArgs();
  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    fallbackLocale: AppLocales.english,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    useOnlyLangCode: true,
    child: ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        builder: EasyLoading.init(),
        initialRoute: '/step-three',
        navigatorObservers: navigatorObserver == null
            ? const <NavigatorObserver>[]
            : <NavigatorObserver>[navigatorObserver],
        routes: <String, WidgetBuilder>{
          '/': (_) =>
              const Scaffold(body: Center(child: Text('test-root-page'))),
          '/step-three': (_) =>
              QualificationCertificationStepThreePage(args: resolvedArgs),
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

/// 记录第三步最终提交阶段的文件上传顺序，避免依赖真实文件系统和网络。
class _RecordingFileService extends FileService {
  _RecordingFileService(this.events) : super(apiClient: ApiClient(Dio()));

  final List<String> events;
  int _nextFileId = 1;

  @override
  Future<FilePresignVO> uploadFile({
    required String path,
    required FileScene scene,
    String accessType = 'PUBLIC',
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    events.add('file:${scene.value}:$path');
    final int fileId = _nextFileId++;
    return FilePresignVO(
      uploadUrl: 'https://upload.example.com/$fileId',
      fileUrl: 'https://cdn.example.com/$fileId.png',
      expireIn: 300,
      objectKey: 'object-$fileId',
      fileId: fileId,
    );
  }
}

/// 记录资质接口与资料接口的调用顺序，确保最终提交流程满足“先 docs，后 profile”。
class _RecordingProviderService extends ProviderService {
  _RecordingProviderService(this.events, {this.failDocs = false})
    : super(apiClient: ApiClient(Dio()));

  final List<String> events;
  final bool failDocs;

  @override
  Future<void> uploadQualifications({
    required UploadQualificationDocsBO request,
  }) async {
    events.add('docs:${request.docs.length}');
    if (failDocs) {
      throw Exception('docs failed');
    }
  }

  @override
  Future<void> updateMyProfile({required UpdateVisaProviderBO request}) async {
    events.add('profile');
  }
}

/// 为第三步测试提供稳定的国家字典数据，避免提交时依赖真实接口。
class _FakeCountryService extends CountryService {
  _FakeCountryService() : super(apiClient: ApiClient(Dio()));

  @override
  Future<PageResult<CountryVO>> searchCountries({
    String? keyword,
    int? page,
    int? pageSize,
  }) async {
    return PageResult<CountryVO>(
      list: const <CountryVO>[
        CountryVO(countryCode: 'DE', nameZh: '德国', nameEn: 'Germany'),
      ],
      pagination: const Pagination(
        page: 1,
        total: 1,
        pageSize: 50,
        totalPages: 1,
        hasNext: false,
      ),
    );
  }
}
