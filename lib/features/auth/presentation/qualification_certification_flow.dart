import 'package:easy_localization/easy_localization.dart';

import '../../employer/data/employer_models.dart' as employer_models;
import '../../files/data/file_models.dart';
import '../../visa/data/provider_models.dart';

enum QualificationCertificationRole { serviceProvider, company }

enum QualificationDocType {
  businessLicense('business_license', '认证流程.营业执照', FileScene.cert),
  specialPermit('special_permit', '认证流程.特许经验许可', FileScene.cert),
  idCard('id_card', '认证流程.身份证', FileScene.idCard);

  const QualificationDocType(
    this.apiValue,
    this.defaultDocNameKey,
    this.uploadScene,
  );

  final String apiValue;
  final String defaultDocNameKey;
  final FileScene uploadScene;

  String get localizedDefaultDocName => defaultDocNameKey.tr();
}

String qualificationCountryLabel(QualificationCertificationRole role) {
  return role == QualificationCertificationRole.company
      ? tr('认证流程.主营国家')
      : tr('认证流程.期望国家地区');
}

class UploadedQualificationDoc {
  const UploadedQualificationDoc({
    required this.docType,
    required this.docName,
    required this.fileId,
    required this.fileUrl,
    required this.localPath,
  });

  final QualificationDocType docType;
  final String docName;
  final int fileId;
  final String fileUrl;
  final String localPath;

  DocItemBO toDocItemBO() {
    return DocItemBO(
      docType: docType.apiValue,
      docName: docName,
      fileId: fileId,
      fileUrl: fileUrl,
    );
  }
}

class QualificationCertificationDraft {
  String serviceProviderCompanyName = '';
  String unifiedCreditCode = '';
  String legalPerson = '';
  String contactPerson = '';
  String contactPhone = '';
  String contactEmail = '';
  String website = '';

  String companyName = '';
  String companyIndustry = '';
  String companySize = '';
  String companyWebsite = '';
  String companyFoundedYear = '';
  String companyCountryCode = '';
  String companyCountryLabel = '';
  String companyCity = '';
  String companyManagerName = '';
  String companyPhone = '';
  String companyEmail = '';

  List<String> serviceCountryLabels = <String>[];
  List<String> serviceCountryCodes = <String>[];
  int yearsOfService = 0;

  UploadedQualificationDoc? businessLicenseDoc;
  UploadedQualificationDoc? specialPermitDoc;
  UploadedQualificationDoc? idCardEmblemDoc;
  UploadedQualificationDoc? idCardPortraitDoc;

  /// 用服务商资料初始化认证流程草稿，并补齐历史上传的资质图片数据。
  void fillFromProviderProfile(
    VisaProviderProfileVO profile, {
    Map<String, String> countryLabelMap = const <String, String>{},
  }) {
    serviceProviderCompanyName = profile.companyName.trim();
    unifiedCreditCode = profile.unifiedCreditCode.trim();
    legalPerson = profile.legalPerson.trim();
    contactPerson = profile.contactPerson.trim();
    contactPhone = profile.contactPhone.trim();
    contactEmail = profile.contactEmail.trim();
    website = profile.website.trim();
    yearsOfService = profile.yearsOfService;
    serviceCountryCodes = _distinctNonEmptyStrings(profile.serviceCountries);
    serviceCountryLabels = serviceCountryCodes
        .map((code) => countryLabelMap[code] ?? code)
        .toList(growable: false);
    _fillQualificationDocsFromProvider(profile.qualificationDocs);
  }

  /// 用企业资料初始化认证流程草稿，并补齐历史上传的资质图片数据。
  void fillFromEmployerProfile(
    employer_models.EmployerProfileVO profile, {
    Map<String, String> countryLabelMap = const <String, String>{},
  }) {
    companyName = profile.companyName.trim();
    companyIndustry = profile.industry.trim();
    companySize = profile.companySize.trim();
    companyWebsite = profile.website.trim();
    companyFoundedYear = profile.foundedYear <= 0
        ? ''
        : profile.foundedYear.toString();
    companyCountryCode = profile.country.trim();
    companyCountryLabel =
        countryLabelMap[companyCountryCode] ?? companyCountryCode;
    companyCity = profile.city.trim();
    _fillQualificationDocsFromEmployer(profile.qualificationDocs);
  }

  List<DocItemBO> qualificationDocs() {
    return <DocItemBO>[
      if (businessLicenseDoc != null) businessLicenseDoc!.toDocItemBO(),
      if (specialPermitDoc != null) specialPermitDoc!.toDocItemBO(),
      if (idCardEmblemDoc != null) idCardEmblemDoc!.toDocItemBO(),
      if (idCardPortraitDoc != null) idCardPortraitDoc!.toDocItemBO(),
    ];
  }

  UpdateVisaProviderBO toProviderUpdateRequest() {
    return UpdateVisaProviderBO(
      companyName: serviceProviderCompanyName,
      unifiedCreditCode: unifiedCreditCode,
      legalPerson: legalPerson,
      contactPerson: contactPerson,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      website: website,
      yearsOfService: yearsOfService,
      brief: '',
      servicePromise: '',
      serviceCountries: serviceCountryCodes,
    );
  }

  employer_models.UpdateEmployerBO toEmployerUpdateRequest() {
    final int foundedYearValue = int.tryParse(companyFoundedYear.trim()) ?? 0;
    return employer_models.UpdateEmployerBO(
      companyName: companyName,
      industry: companyIndustry,
      companySize: companySize,
      description: '',
      website: companyWebsite,
      foundedYear: foundedYearValue,
      country: companyCountryCode,
      city: companyCity,
    );
  }

  /// 统一解析服务商与企业资料中的历史资质文档，供认证流程页面回显使用。
  void _fillQualificationDocsFromProvider(List<QualificationDocVO> docs) {
    _fillQualificationDocs(
      docs,
      docTypeOf: (QualificationDocVO doc) => doc.docType,
      docNameOf: (QualificationDocVO doc) => doc.docName,
      fileUrlOf: (QualificationDocVO doc) => doc.fileUrl,
      fileIdOf: (QualificationDocVO doc) => doc.fileId,
    );
  }

  /// 统一解析企业资料中的历史资质文档，供认证流程页面回显使用。
  void _fillQualificationDocsFromEmployer(
    List<employer_models.QualificationDocVO> docs,
  ) {
    _fillQualificationDocs(
      docs,
      docTypeOf: (employer_models.QualificationDocVO doc) => doc.docType,
      docNameOf: (employer_models.QualificationDocVO doc) => doc.docName,
      fileUrlOf: (employer_models.QualificationDocVO doc) => doc.fileUrl,
      fileIdOf: (employer_models.QualificationDocVO doc) => doc.fileId,
    );
  }

  /// 统一解析服务商与企业资料中的历史资质文档，供认证流程页面回显使用。
  void _fillQualificationDocs<T>(
    List<T> docs, {
    required String Function(T doc) docTypeOf,
    required String Function(T doc) docNameOf,
    required String Function(T doc) fileUrlOf,
    required int? Function(T doc) fileIdOf,
  }) {
    businessLicenseDoc = null;
    specialPermitDoc = null;
    idCardEmblemDoc = null;
    idCardPortraitDoc = null;
    final List<T> idCards = <T>[];

    for (final T doc in docs) {
      final UploadedQualificationDoc? uploadedDoc =
          _uploadedQualificationDocFromRaw(
            docType: docTypeOf(doc),
            docName: docNameOf(doc),
            fileUrl: fileUrlOf(doc),
            fileId: fileIdOf(doc),
          );
      if (uploadedDoc == null) {
        continue;
      }
      final String docType = docTypeOf(doc).trim();
      if (docType == QualificationDocType.businessLicense.apiValue) {
        businessLicenseDoc ??= uploadedDoc;
        continue;
      }
      if (docType == QualificationDocType.specialPermit.apiValue) {
        specialPermitDoc ??= uploadedDoc;
        continue;
      }
      if (docType == QualificationDocType.idCard.apiValue) {
        idCards.add(doc);
      }
    }

    for (final T doc in idCards) {
      final UploadedQualificationDoc? uploadedDoc =
          _uploadedQualificationDocFromRaw(
            docType: docTypeOf(doc),
            docName: docNameOf(doc),
            fileUrl: fileUrlOf(doc),
            fileId: fileIdOf(doc),
          );
      if (uploadedDoc == null) {
        continue;
      }
      final String name = docNameOf(doc).trim();
      if (idCardEmblemDoc == null && name.contains('国徽')) {
        idCardEmblemDoc = uploadedDoc;
        continue;
      }
      if (idCardPortraitDoc == null && name.contains('人像')) {
        idCardPortraitDoc = uploadedDoc;
      }
    }

    if (idCards.isNotEmpty) {
      idCardEmblemDoc ??= _uploadedQualificationDocFromRaw(
        docType: docTypeOf(idCards.first),
        docName: docNameOf(idCards.first),
        fileUrl: fileUrlOf(idCards.first),
        fileId: fileIdOf(idCards.first),
      );
      if (idCards.length > 1) {
        idCardPortraitDoc ??= _uploadedQualificationDocFromRaw(
          docType: docTypeOf(idCards[1]),
          docName: docNameOf(idCards[1]),
          fileUrl: fileUrlOf(idCards[1]),
          fileId: fileIdOf(idCards[1]),
        );
      }
    }
  }

  /// 将接口文档对象转换为流程草稿对象，保留远端地址用于历史图片回显。
  UploadedQualificationDoc? _uploadedQualificationDocFromRaw({
    required String docType,
    required String docName,
    required String fileUrl,
    required int? fileId,
  }) {
    final String normalizedFileUrl = fileUrl.trim();
    if (normalizedFileUrl.isEmpty || fileId == null) {
      return null;
    }
    return UploadedQualificationDoc(
      docType: _qualificationDocTypeFromApiValue(docType),
      docName: docName.trim(),
      fileId: fileId,
      fileUrl: normalizedFileUrl,
      localPath: '',
    );
  }
}

/// 将接口中的文档类型字符串转换为前端流程枚举。
QualificationDocType _qualificationDocTypeFromApiValue(String docType) {
  final String normalizedDocType = docType.trim();
  for (final QualificationDocType value in QualificationDocType.values) {
    if (value.apiValue == normalizedDocType) {
      return value;
    }
  }
  return QualificationDocType.idCard;
}

List<String> _distinctNonEmptyStrings(Iterable<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

class QualificationCertificationPageArgs {
  QualificationCertificationPageArgs({
    this.role = QualificationCertificationRole.serviceProvider,
    QualificationCertificationDraft? draft,
  }) : draft = draft ?? QualificationCertificationDraft();

  final QualificationCertificationRole role;
  final QualificationCertificationDraft draft;
}
