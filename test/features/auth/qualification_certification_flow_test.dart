import 'package:europepass/features/auth/presentation/qualification_certification_flow.dart';
import 'package:europepass/features/auth/presentation/qualification_preview_resolver.dart';
import 'package:europepass/features/employer/data/employer_models.dart'
    as employer_models;
import 'package:europepass/features/visa/data/provider_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证资质认证流程在编辑历史资料时，能够正确回填证件图与预览来源。
void main() {
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
    final ImageProvider<Object>? imageProvider =
        QualificationPreviewResolver.resolveImageProvider(previewPath);

    expect(previewPath, 'https://example.com/id-emblem.png');
    expect(imageProvider, isA<NetworkImage>());
  });
}
