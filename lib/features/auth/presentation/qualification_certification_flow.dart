import 'package:easy_localization/easy_localization.dart';

import '../../employer/data/employer_models.dart';
import '../../files/data/file_models.dart';
import '../../visa/data/provider_models.dart';

enum QualificationCertificationRole { serviceProvider, company }

enum QualificationDocType {
  businessLicense('business_license', '营业执照', FileScene.cert),
  specialPermit('special_permit', '特许经验许可', FileScene.cert),
  idCard('id_card', '身份证', FileScene.idCard);

  const QualificationDocType(
    this.apiValue,
    this.defaultDocName,
    this.uploadScene,
  );

  final String apiValue;
  final String defaultDocName;
  final FileScene uploadScene;
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
  }

  void fillFromEmployerProfile(
    EmployerProfileVO profile, {
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

  UpdateEmployerBO toEmployerUpdateRequest() {
    final int foundedYearValue =
        int.tryParse(companyFoundedYear.trim()) ?? 0;
    return UpdateEmployerBO(
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
