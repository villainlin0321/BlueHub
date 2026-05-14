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

class QualificationCountryOption {
  const QualificationCountryOption({required this.code, required this.label});

  final String code;
  final String label;
}

const List<QualificationCountryOption> qualificationCountryOptions =
    <QualificationCountryOption>[
      QualificationCountryOption(code: 'DE', label: '德国'),
      QualificationCountryOption(code: 'FR', label: '法国'),
      QualificationCountryOption(code: 'CH', label: '瑞士'),
      QualificationCountryOption(code: 'GB', label: '英国'),
      QualificationCountryOption(code: 'IT', label: '意大利'),
      QualificationCountryOption(code: 'ES', label: '西班牙'),
      QualificationCountryOption(code: 'NL', label: '荷兰'),
    ];

String qualificationCountryLabel(QualificationCertificationRole role) {
  return role == QualificationCertificationRole.company ? '主营国家' : '期望国家/地区';
}

String qualificationCountryCodeFromLabel(String label) {
  for (final QualificationCountryOption option in qualificationCountryOptions) {
    if (option.label == label) {
      return option.code;
    }
  }
  return label;
}

String qualificationCountryLabelFromCode(String code) {
  for (final QualificationCountryOption option in qualificationCountryOptions) {
    if (option.code == code) {
      return option.label;
    }
  }
  return code;
}

List<String> qualificationCountryCodesFromLabels(Iterable<String> labels) {
  return labels
      .map(qualificationCountryCodeFromLabel)
      .toSet()
      .toList(growable: false);
}

List<String> qualificationCountryLabelsFromCodes(Iterable<String> codes) {
  return codes.map(qualificationCountryLabelFromCode).toList(growable: false);
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
  String companyCountryCode = '';
  String companyCountryLabel = '';
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
      logoId: 0,
      logoUrl: '',
      brief: '',
      servicePromise: '',
      serviceCountries: serviceCountryCodes,
    );
  }

  UpdateEmployerBO toEmployerUpdateRequest() {
    return UpdateEmployerBO(
      companyName: companyName,
      industry: '',
      companySize: '',
      logoId: 0,
      logoUrl: '',
      description: '',
      website: '',
      foundedYear: 0,
      country: companyCountryCode,
      city: '',
    );
  }
}

class QualificationCertificationPageArgs {
  QualificationCertificationPageArgs({
    this.role = QualificationCertificationRole.serviceProvider,
    QualificationCertificationDraft? draft,
  }) : draft = draft ?? QualificationCertificationDraft();

  final QualificationCertificationRole role;
  final QualificationCertificationDraft draft;
}
