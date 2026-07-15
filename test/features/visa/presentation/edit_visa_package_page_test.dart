import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/visa/application/edit_visa_package/edit_visa_package_state.dart';
import 'package:europepass/features/config/data/config_models.dart';
import 'package:europepass/features/config/data/config_providers.dart';
import 'package:europepass/features/me/data/dictionary_providers.dart';
import 'package:europepass/features/visa/data/visa_package_models.dart';
import 'package:europepass/features/visa/data/visa_package_providers.dart';
import 'package:europepass/features/visa/presentation/edit_visa_package_page.dart';
import 'package:europepass/features/visa/presentation/widgets/edit_visa_package_form_widgets.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:europepass/shared/network/services/config_service.dart';
import 'package:europepass/shared/network/services/country_service.dart';
import 'package:europepass/shared/network/services/visa_package_service.dart';
import 'package:europepass/shared/network/models/dictionary_models.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:europepass/utils/upload_picker_utils.dart';

/// 验证签证套餐编辑页的未保存拦截、提交放行与快照覆盖逻辑。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('签证套餐编辑页修改服务名后返回会弹出确认框', (
    WidgetTester tester,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildEditVisaPackageTestApp(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldEditVisaPackageName),
      '新的套餐名',
    );
    await tester.tap(find.byKey(AppTestKeys.actionEditVisaPackageBack));
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
  });

  testWidgets('签证套餐编辑页通过系统返回确认离开后会真实退出页面', (
    WidgetTester tester,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final _RecordingNavigatorObserver navigatorObserver =
        _RecordingNavigatorObserver();

    await tester.pumpWidget(
      buildEditVisaPackageTestApp(
        preferences: preferences,
        navigatorObserver: navigatorObserver,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppTestKeys.fieldEditVisaPackageName),
      '新的套餐名',
    );

    // 通过系统返回触发 PopScope，再验证用户确认离开后页面已经真实弹栈。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('test-root-page'), findsOneWidget);
    expect(find.byKey(AppTestKeys.pageEditVisaPackage), findsNothing);
    expect(navigatorObserver.poppedRouteNames, contains('/edit-visa-package'));
  });

  testWidgets('签证套餐编辑页提交成功后不会被 PopScope 再次拦截', (
    WidgetTester tester,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final _FakeVisaPackageService visaPackageService =
        _FakeVisaPackageService.withEditDetail(_buildEditDetail());
    final _RecordingNavigatorObserver navigatorObserver =
        _RecordingNavigatorObserver();

    await tester.pumpWidget(
      buildEditVisaPackageTestApp(
        preferences: preferences,
        packageId: 42,
        visaPackageService: visaPackageService,
        navigatorObserver: navigatorObserver,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppTestKeys.actionEditVisaPackageSaveDraft));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(visaPackageService.updateCallCount, 1);
    expect(find.text('test-root-page'), findsOneWidget);
    expect(find.byKey(AppTestKeys.pageEditVisaPackage), findsNothing);
    expect(find.text('现在退出，内容将不会保存'), findsNothing);
    expect(navigatorObserver.poppedRouteNames, contains('/edit-visa-package'));

    // 提交成功会触发 Toast，补一拍让 EasyLoading 内部定时器正常收尾。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  test('构建快照时会覆盖影响提交结果的档位与材料关键字段', () {
    final Object baselineSnapshot = _buildSnapshotForTest();

    expect(
      _buildSnapshotForTest(showMaterials: false) == baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(
            selectedServiceTagCodes: <String>{'service_priority'},
          ) ==
          baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(customServices: <String>['加急办理', '材料翻译']) ==
          baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(materialName: '照片') == baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(materialDescription: '两寸白底照片') ==
          baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(materialIsRequired: false) == baselineSnapshot,
      isFalse,
    );
    expect(
      _buildSnapshotForTest(
            existingExampleFileIds: <int>[2001],
            uploadedExampleFileIds: <int>[3002],
          ) ==
          baselineSnapshot,
      isFalse,
    );
  });

  test('构建快照时会在隐藏材料时忽略材料内容差异避免误判', () {
    final Object hiddenBaselineSnapshot = _buildSnapshotForTest(
      showMaterials: false,
      materialName: '护照',
      materialDescription: '首页与签证页',
      materialIsRequired: true,
      existingExampleFileIds: <int>[2001],
      uploadedExampleFileIds: <int>[3001],
    );

    expect(
      _buildSnapshotForTest(
            showMaterials: false,
            materialName: '照片',
            materialDescription: '两寸白底照片',
            materialIsRequired: false,
            existingExampleFileIds: <int>[9001],
            uploadedExampleFileIds: <int>[9002],
          ) ==
          hiddenBaselineSnapshot,
      isTrue,
    );
  });

  test('构建快照时只统计会进入请求体的 success 封面状态', () {
    final Object baselineSnapshot = _buildSnapshotForTest();

    expect(
      _buildSnapshotForTest(
            coverImage: PickedUploadFile(
              id: 'cover_uploading',
              name: 'cover.jpg',
              path: '/mock/cover.jpg',
              sourceType: UploadSourceType.gallery,
              state: UploadItemState.uploading,
              isImage: true,
              progress: 0.5,
            ),
          ) ==
          baselineSnapshot,
      isTrue,
    );
    expect(
      _buildSnapshotForTest(
            coverImage: PickedUploadFile(
              id: 'cover_failed',
              name: 'cover.jpg',
              path: '/mock/cover.jpg',
              sourceType: UploadSourceType.gallery,
              state: UploadItemState.failure,
              isImage: true,
              progress: 0,
              errorMessage: '上传失败',
            ),
          ) ==
          baselineSnapshot,
      isTrue,
    );
    expect(
      _buildSnapshotForTest(
            coverImage: PickedUploadFile(
              id: 'cover_invalid_success',
              name: 'cover.jpg',
              path: '   ',
              sourceType: UploadSourceType.gallery,
              state: UploadItemState.success,
              isImage: true,
              progress: 1,
            ),
          ) ==
          baselineSnapshot,
      isTrue,
    );
    expect(
      _buildSnapshotForTest(
            coverImage: PickedUploadFile(
              id: 'cover_valid_success',
              name: 'cover.jpg',
              path: '/mock/cover.jpg',
              sourceType: UploadSourceType.gallery,
              state: UploadItemState.success,
              isImage: true,
              progress: 1,
              uploadedFileId: 9001,
              uploadedFileUrl: 'https://example.com/cover.jpg',
            ),
          ) ==
          baselineSnapshot,
      isFalse,
    );
  });
}

/// 构建签证套餐编辑页测试宿主，并注入最小依赖避免触发真实网络请求。
Widget buildEditVisaPackageTestApp({
  required SharedPreferences preferences,
  int? packageId,
  VisaPackageService? visaPackageService,
  NavigatorObserver? navigatorObserver,
}) {
  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    assetLoader: const _TestJsonFileAssetLoader(),
    fallbackLocale: AppLocales.chinese,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    child: ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        configServiceProvider.overrideWithValue(_FakeConfigService()),
        countryServiceProvider.overrideWithValue(_FakeCountryService()),
        if (visaPackageService != null)
          visaPackageServiceProvider.overrideWithValue(visaPackageService),
      ],
      child: MaterialApp(
        initialRoute: '/edit-visa-package',
        builder: EasyLoading.init(),
        navigatorObservers: navigatorObserver == null
            ? const <NavigatorObserver>[]
            : <NavigatorObserver>[navigatorObserver],
        routes: <String, WidgetBuilder>{
          '/': (_) => const Scaffold(body: Center(child: Text('test-root-page'))),
          '/edit-visa-package': (_) => EditVisaPackagePage(packageId: packageId),
        },
      ),
    ),
  );
}

/// 测试环境直接从仓库读取翻译文件，避免资源 Bundle 未挂载导致文案缺失。
class _TestJsonFileAssetLoader extends AssetLoader {
  const _TestJsonFileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final File file = File(
      '${Directory.current.path}/$path/${locale.languageCode}.json',
    );
    final String content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// 返回最小标签字典，确保页面初始化与签证类型展示都能正常构建。
class _FakeConfigService extends ConfigService {
  _FakeConfigService() : super(apiClient: ApiClient(Dio()));

  @override
  Future<TagDictVO> getTags({TagCategory? category}) async {
    return TagDictVO(
      tags: <String, List<TagItemVO>>{
        TagCategory.service.value: const <TagItemVO>[
          TagItemVO(
            tagCode: 'service_consult',
            tagNameZh: '材料咨询',
            tagNameEn: 'Consulting',
            sortOrder: 1,
          ),
        ],
        TagCategory.visaType.value: const <TagItemVO>[
          TagItemVO(
            tagCode: 'work_visa',
            tagNameZh: '工作签',
            tagNameEn: 'Work Visa',
            sortOrder: 1,
          ),
        ],
        TagCategory.materialType.value: const <TagItemVO>[
          TagItemVO(
            tagCode: 'passport',
            tagNameZh: '护照',
            tagNameEn: 'Passport',
            sortOrder: 1,
          ),
        ],
      },
    );
  }
}

/// 返回最小国家列表，避免页面构建时国家名称映射读取失败。
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
        CountryVO(countryCode: 'JP', nameZh: '日本', nameEn: 'Japan'),
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

/// 记录页面级路由弹栈结果，避免把弹窗路由误判成页面已经退出。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> poppedRoutes = <Route<dynamic>>[];

  /// 只保留带名字的页面路由，便于断言真实页面返回结果。
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

/// 提供编辑态详情与提交结果的最小假实现，便于验证页面放行时序。
class _FakeVisaPackageService extends VisaPackageService {
  _FakeVisaPackageService.withEditDetail(this.editDetail)
    : super(apiClient: ApiClient(Dio()));

  final VisaPackageEditVO editDetail;
  int updateCallCount = 0;
  CreateVisaPackageBO? lastUpdateRequest;

  @override
  Future<VisaPackageEditVO> getPackageEditDetail({required int packageId}) async {
    return editDetail;
  }

  @override
  Future<void> updatePackage({
    required int packageId,
    required CreateVisaPackageBO request,
  }) async {
    updateCallCount += 1;
    lastUpdateRequest = request;
  }
}

/// 构造一个可直接提交的编辑态详情，避免测试中依赖额外表单交互。
VisaPackageEditVO _buildEditDetail() {
  return const VisaPackageEditVO(
    packageId: 42,
    name: '日本工作签套餐',
    targetCountry: 'JP',
    visaType: 'work_visa',
    estimatedDays: 7,
    currency: 'CNY',
    coverImageIds: <int>[],
    coverImages: <String>[],
    status: 'draft',
    tiers: <VisaPackageEditTierVO>[
      VisaPackageEditTierVO(
        tierId: 101,
        name: '基础套餐',
        price: 1999,
        services: <String>['service_consult'],
        customServices: <String>['材料翻译'],
        description: '适合首次申请用户',
        showMaterials: true,
        sortOrder: 1,
        soldCount: 0,
        materials: <VisaPackageEditMaterialVO>[
          VisaPackageEditMaterialVO(
            name: '护照',
            description: '提供有效护照首页',
            isRequired: true,
            sortOrder: 1,
            exampleFileIds: <int>[2001],
            exampleFileUrls: <String>['https://example.com/passport.pdf'],
          ),
        ],
      ),
    ],
  );
}

/// 构建快照测试入参，并直接返回可比较的快照对象。
Object _buildSnapshotForTest({
  bool showMaterials = true,
  Set<String>? selectedServiceTagCodes,
  List<String>? customServices,
  PickedUploadFile? coverImage,
  String materialName = '护照',
  String materialDescription = '首页与签证页',
  bool materialIsRequired = true,
  List<int>? existingExampleFileIds,
  List<int>? uploadedExampleFileIds,
}) {
  final TextEditingController serviceNameController = TextEditingController(
    text: '日本工作签套餐',
  );
  final TextEditingController durationController = TextEditingController(
    text: '7',
  );
  final EditVisaPackageMaterialViewDraft material = EditVisaPackageMaterialViewDraft(
    titleController: TextEditingController(text: materialName),
    descriptionController: TextEditingController(text: materialDescription),
    isRequired: materialIsRequired,
    existingExampleFileIds:
        existingExampleFileIds ?? const <int>[2001],
    exampleFiles: (uploadedExampleFileIds ?? const <int>[3001])
        .map(
          (int fileId) => PickedUploadFile(
            id: 'file_$fileId',
            name: 'example_$fileId.pdf',
            path: '/mock/example_$fileId.pdf',
            sourceType: UploadSourceType.file,
            state: UploadItemState.success,
            uploadedFileId: fileId,
            uploadedFileUrl: 'https://example.com/$fileId.pdf',
            isImage: false,
            progress: 1,
          ),
        )
        .toList(growable: false),
  );
  final EditVisaPackageTierViewDraft tier = EditVisaPackageTierViewDraft(
    tierId: 101,
    nameController: TextEditingController(text: '基础套餐'),
    priceController: TextEditingController(text: '1999'),
    descriptionController: TextEditingController(text: '适合首次申请用户'),
    showMaterials: showMaterials,
    selectedServiceTagCodes:
        selectedServiceTagCodes ?? <String>{'service_consult'},
    customServices: customServices ?? <String>['材料翻译'],
    materials: <EditVisaPackageMaterialViewDraft>[material],
    deletable: false,
  );

  try {
    return buildEditVisaPackageSnapshotForTest(
      state: const EditVisaPackageState(
        selectedCountryCode: 'JP',
        selectedVisaTypeCode: 'work_visa',
      ),
      serviceNameController: serviceNameController,
      durationController: durationController,
      coverImage: coverImage,
      tiers: <EditVisaPackageTierViewDraft>[tier],
    );
  } finally {
    serviceNameController.dispose();
    durationController.dispose();
    tier.dispose();
  }
}
