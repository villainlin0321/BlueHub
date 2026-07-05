import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_page.dart';
import 'package:europepass/features/auth/presentation/qualification_certification_step_two_page.dart';
import 'package:europepass/features/auth/presentation/qualification_preview_resolver.dart';
import 'package:europepass/features/employer/data/employer_models.dart'
    as employer_models;
import 'package:europepass/features/visa/data/provider_models.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 验证资质认证流程在编辑历史资料时，能够正确回填证件图与预览来源。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  test('服务商资料会回填已有资质图片与身份证正反面', () {
    final QualificationCertificationDraft draft =
        QualificationCertificationDraft();

    draft.fillFromProviderProfile(
      VisaProviderProfileVO(
        profileId: 1,
        isVerified: true,
        verifyStatus: 'approved',
        verifyRejectReason: null,
        rating: 5,
        caseCount: 10,
        pendingOrderCount: 0,
        activePackageCount: 1,
        companyName: '欧路签证',
        unifiedCreditCode: '91310000123456789A',
        legalPerson: '张三',
        contactPerson: '李四',
        contactPhone: '13800138000',
        contactEmail: 'service@example.com',
        website: 'https://example.com',
        yearsOfService: 8,
        logoId: null,
        logoUrl: '',
        brief: '',
        servicePromise: '',
        serviceCountries: const <String>['DE'],
        qualificationDocs: const <QualificationDocVO>[
          QualificationDocVO(
            docId: 1,
            docType: 'business_license',
            docName: '营业执照',
            fileUrl: 'https://example.com/business-license.png',
            fileId: 101,
            createdAt: '2026-01-01T00:00:00Z',
          ),
          QualificationDocVO(
            docId: 2,
            docType: 'special_permit',
            docName: '特许经营许可',
            fileUrl: 'https://example.com/special-permit.png',
            fileId: 102,
            createdAt: '2026-01-01T00:00:00Z',
          ),
          QualificationDocVO(
            docId: 3,
            docType: 'id_card',
            docName: '法人身份证国徽面',
            fileUrl: 'https://example.com/id-emblem.png',
            fileId: 103,
            createdAt: '2026-01-01T00:00:00Z',
          ),
          QualificationDocVO(
            docId: 4,
            docType: 'id_card',
            docName: '法人身份证人像面',
            fileUrl: 'https://example.com/id-portrait.png',
            fileId: 104,
            createdAt: '2026-01-01T00:00:00Z',
          ),
        ],
      ),
    );

    expect(draft.businessLicenseDoc?.fileUrl, 'https://example.com/business-license.png');
    expect(draft.specialPermitDoc?.fileUrl, 'https://example.com/special-permit.png');
    expect(draft.idCardEmblemDoc?.fileUrl, 'https://example.com/id-emblem.png');
    expect(draft.idCardPortraitDoc?.fileUrl, 'https://example.com/id-portrait.png');
    expect(draft.idCardEmblemDoc?.localPath, isEmpty);
    expect(draft.idCardPortraitDoc?.localPath, isEmpty);
  });

  test('企业资料会回填已有资质图片', () {
    final QualificationCertificationDraft draft =
        QualificationCertificationDraft();

    draft.fillFromEmployerProfile(
      employer_models.EmployerProfileVO(
        profileId: 2,
        isVerified: true,
        verifyStatus: 'approved',
        verifyRejectReason: null,
        companyName: 'BlueHub',
        industry: '互联网',
        companySize: '100-499人',
        logoId: null,
        logoUrl: '',
        description: '',
        website: 'https://bluehub.example.com',
        foundedYear: 2020,
        country: 'DE',
        city: 'Berlin',
        qualificationDocs: const <employer_models.QualificationDocVO>[
          employer_models.QualificationDocVO(
            docId: 11,
            docType: 'business_license',
            docName: '营业执照',
            fileUrl: 'https://example.com/company-license.png',
            fileId: 201,
            createdAt: '2026-01-01T00:00:00Z',
          ),
          employer_models.QualificationDocVO(
            docId: 12,
            docType: 'special_permit',
            docName: '特许经营许可',
            fileUrl: 'https://example.com/company-permit.png',
            fileId: 202,
            createdAt: '2026-01-01T00:00:00Z',
          ),
        ],
      ),
    );

    expect(draft.businessLicenseDoc?.fileUrl, 'https://example.com/company-license.png');
    expect(draft.specialPermitDoc?.fileUrl, 'https://example.com/company-permit.png');
    expect(draft.businessLicenseDoc?.localPath, isEmpty);
  });

  test('预览解析器在缺少本地路径时会退回远端图片地址', () {
    const UploadedQualificationDoc document = UploadedQualificationDoc(
      docType: QualificationDocType.idCard,
      docName: '法人身份证国徽面',
      fileId: 301,
      fileUrl: 'https://example.com/id-emblem.png',
      localPath: '',
    );

    final String? previewPath = QualificationPreviewResolver.resolvePreviewPath(
      document,
    );

    expect(previewPath, 'https://example.com/id-emblem.png');
    expect(QualificationPreviewResolver.isNetworkPath(previewPath), isTrue);
  });

  testWidgets('第一页身份证远端图片使用 CachedNetworkImage 预览', (
    WidgetTester tester,
  ) async {
    final QualificationCertificationDraft draft =
        QualificationCertificationDraft()
          ..idCardEmblemDoc = const UploadedQualificationDoc(
            docType: QualificationDocType.idCard,
            docName: '法人身份证国徽面',
            fileId: 301,
            fileUrl: 'https://example.com/id-emblem.png',
            localPath: '',
          );

    await _pumpQualificationTestHost(
      tester,
      child: QualificationCertificationPage(
        args: QualificationCertificationPageArgs(draft: draft),
      ),
    );
    await tester.pump();

    final CachedNetworkImage preview = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(preview.imageUrl, 'https://example.com/id-emblem.png');
  });

  testWidgets('第二页营业执照远端图片使用 CachedNetworkImage 预览', (
    WidgetTester tester,
  ) async {
    final QualificationCertificationDraft draft =
        QualificationCertificationDraft()
          ..businessLicenseDoc = const UploadedQualificationDoc(
            docType: QualificationDocType.businessLicense,
            docName: '营业执照',
            fileId: 302,
            fileUrl: 'https://example.com/business-license.png',
            localPath: '',
          );

    await _pumpQualificationTestHost(
      tester,
      child: QualificationCertificationStepTwoPage(
        args: QualificationCertificationPageArgs(draft: draft),
      ),
    );
    await tester.pump();

    final CachedNetworkImage preview = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(preview.imageUrl, 'https://example.com/business-license.png');
  });

  testWidgets('第二页空态上传区只显示一层相机按钮', (WidgetTester tester) async {
    await _pumpQualificationTestHost(
      tester,
      child: QualificationCertificationStepTwoPage(
        args: QualificationCertificationPageArgs(
          draft: QualificationCertificationDraft(),
        ),
      ),
    );
    await tester.pump();

    expect(_qualificationCameraFinder(), findsNWidgets(2));
  });

  testWidgets('第二页文件预览失败后仍只显示一层相机按钮', (WidgetTester tester) async {
    final QualificationCertificationDraft draft =
        QualificationCertificationDraft()
          ..businessLicenseDoc = const UploadedQualificationDoc(
            docType: QualificationDocType.businessLicense,
            docName: '营业执照',
            fileId: 303,
            fileUrl: '',
            localPath: '/tmp/bluehub-missing-license.png',
          );

    await _pumpQualificationTestHost(
      tester,
      child: QualificationCertificationStepTwoPage(
        args: QualificationCertificationPageArgs(draft: draft),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_qualificationCameraFinder(), findsNWidgets(2));
  });
}

/// 挂载资质认证测试页面，并补齐本地化与 Riverpod 运行环境。
Future<void> _pumpQualificationTestHost(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: ProviderScope(
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: child,
            );
          },
        ),
      ),
    ),
  );
}

/// 只统计第二页上传区使用的相机图标，避免把返回按钮和步骤图标算进断言。
Finder _qualificationCameraFinder() {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is SvgPicture &&
        widget.bytesLoader.toString().contains('qualification_camera.svg'),
  );
}

/// 测试环境直接从仓库读取翻译文件，避免 widget test 无法加载 assets。
class _TestJsonFileAssetLoader extends AssetLoader {
  const _TestJsonFileAssetLoader();

  @override
  /// 读取指定语言的翻译 JSON，给测试宿主提供真实文案。
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final File file = File('${Directory.current.path}/$path/${locale.languageCode}.json');
    final String content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
