import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/employer/data/employer_models.dart';
import 'package:europepass/features/employer/data/employer_providers.dart';
import 'package:europepass/features/me/data/dictionary_providers.dart';
import 'package:europepass/features/me/presentation/company_my_info_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/models/dictionary_models.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/services/employer_service.dart';
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

  testWidgets('企业资料页优先回显同类型资质中的最新有效图片', (WidgetTester tester) async {
    final EmployerProfileVO profile = EmployerProfileVO(
      profileId: 1,
      isVerified: true,
      verifyStatus: 'approved',
      verifyRejectReason: null,
      companyName: '测试企业',
      industry: '制造业',
      companySize: '50-100人',
      logoId: null,
      logoUrl: '',
      description: '',
      website: 'https://example.com',
      foundedYear: 2020,
      country: 'DE',
      city: 'Berlin',
      qualificationDocs: const <QualificationDocVO>[
        QualificationDocVO(
          docId: 1,
          docType: 'business_license',
          docName: '旧营业执照',
          fileUrl: '',
          fileId: 1,
          createdAt: '2026-07-01T10:00:00Z',
        ),
        QualificationDocVO(
          docId: 2,
          docType: 'business_license',
          docName: '新营业执照',
          fileUrl: 'https://example.com/business-new.png',
          fileId: 2,
          createdAt: '2026-07-05T10:00:00Z',
        ),
        QualificationDocVO(
          docId: 3,
          docType: 'special_permit',
          docName: '旧特许经验许可',
          fileUrl: '',
          fileId: 3,
          createdAt: '2026-07-01T10:00:00Z',
        ),
        QualificationDocVO(
          docId: 4,
          docType: 'special_permit',
          docName: '新特许经验许可',
          fileUrl: 'https://example.com/permit-new.png',
          fileId: 4,
          createdAt: '2026-07-05T10:00:00Z',
        ),
      ],
    );

    final ProviderContainer container = ProviderContainer(
      overrides: [
        employerServiceProvider.overrideWithValue(
          _FakeEmployerService(profile: profile),
        ),
        countrySearchProvider(const CountrySearchQuery()).overrideWith(
          (Ref ref) async => PageResult<CountryVO>(
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
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _buildCompanyMyInfoTestHost(container: container),
    );
    await tester.pumpAndSettle();

    final List<CachedNetworkImage> images = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .toList(growable: false);

    expect(images, hasLength(2));
    expect(
      images.map((CachedNetworkImage image) => image.imageUrl),
      containsAll(<String>[
        'https://example.com/business-new.png',
        'https://example.com/permit-new.png',
      ]),
    );
  });
}

/// 构建企业资料页测试宿主，统一接入本地化与 Riverpod 容器。
Widget _buildCompanyMyInfoTestHost({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: Builder(
        builder: (BuildContext context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const CompanyMyInfoPage(),
          );
        },
      ),
    ),
  );
}

/// 直接读取仓库翻译文件，避免测试环境缺少资源导致文案构建失败。
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

/// 企业资料接口测试替身：返回预置的企业资料，避免真正发起网络请求。
class _FakeEmployerService extends EmployerService {
  _FakeEmployerService({required this.profile}) : super(apiClient: ApiClient(Dio()));

  final EmployerProfileVO profile;

  @override
  Future<EmployerProfileVO> getEmployerProfile() async {
    return profile;
  }
}
