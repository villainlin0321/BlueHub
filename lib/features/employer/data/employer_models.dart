import 'package:europepass/shared/network/api_decoders.dart';

class EmployerPublicVO {
  const EmployerPublicVO({
    required this.profileId,
    required this.companyName,
    required this.isVerified,
    required this.industry,
    required this.companySize,
    required this.logoUrl,
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.country,
    required this.city,
  });

  final int profileId;
  final String companyName;
  final bool isVerified;
  final String industry;
  final String companySize;
  final String logoUrl;
  final String description;
  final String website;
  final int foundedYear;
  final String country;
  final String city;

  factory EmployerPublicVO.fromJson(JsonMap json) {
    return EmployerPublicVO(
      profileId: readInt(json, 'profileId'),
      companyName: readString(json, 'companyName'),
      isVerified: readBool(json, 'isVerified'),
      industry: readString(json, 'industry'),
      companySize: readString(json, 'companySize'),
      logoUrl: readString(json, 'logoUrl'),
      description: readString(json, 'description'),
      website: readString(json, 'website'),
      foundedYear: readInt(json, 'foundedYear'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'profileId': profileId,
      'companyName': companyName,
      'isVerified': isVerified,
      'industry': industry,
      'companySize': companySize,
      'logoUrl': logoUrl,
      'description': description,
      'website': website,
      'foundedYear': foundedYear,
      'country': country,
      'city': city,
    };
  }
}

class EmployerProfileVO {
  const EmployerProfileVO({
    required this.profileId,
    required this.isVerified,
    required this.verifyStatus,
    this.verifyRejectReason,
    required this.companyName,
    required this.industry,
    required this.companySize,
    this.logoId,
    required this.logoUrl,
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.country,
    required this.city,
    required this.qualificationDocs,
  });

  final int profileId;
  final bool isVerified;
  final String verifyStatus;
  final String? verifyRejectReason;
  final String companyName;
  final String industry;
  final String companySize;
  final int? logoId;
  final String logoUrl;
  final String description;
  final String website;
  final int foundedYear;
  final String country;
  final String city;
  final List<QualificationDocVO> qualificationDocs;

  factory EmployerProfileVO.fromJson(JsonMap json) {
    return EmployerProfileVO(
      profileId: readInt(json, 'profileId'),
      isVerified: readBool(json, 'isVerified'),
      verifyStatus: readString(json, 'verifyStatus'),
      verifyRejectReason: _readNullableString(json['verifyRejectReason']),
      companyName: readString(json, 'companyName'),
      industry: readString(json, 'industry'),
      companySize: readString(json, 'companySize'),
      logoId: _readNullableInt(json['logoId']),
      logoUrl: readString(json, 'logoUrl'),
      description: readString(json, 'description'),
      website: readString(json, 'website'),
      foundedYear: readInt(json, 'foundedYear'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      qualificationDocs: readModelList<QualificationDocVO>(
        json,
        'qualificationDocs',
        QualificationDocVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'profileId': profileId,
      'isVerified': isVerified,
      'verifyStatus': verifyStatus,
      if (verifyRejectReason != null) 'verifyRejectReason': verifyRejectReason,
      'companyName': companyName,
      'industry': industry,
      'companySize': companySize,
      if (logoId != null) 'logoId': logoId,
      'logoUrl': logoUrl,
      'description': description,
      'website': website,
      'foundedYear': foundedYear,
      'country': country,
      'city': city,
      'qualificationDocs': qualificationDocs
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class QualificationDocVO {
  const QualificationDocVO({
    required this.docId,
    required this.docType,
    required this.docName,
    required this.fileUrl,
    this.fileId,
    required this.createdAt,
  });

  final int docId;
  final String docType;
  final String docName;
  final String fileUrl;
  final int? fileId;
  final String createdAt;

  factory QualificationDocVO.fromJson(JsonMap json) {
    return QualificationDocVO(
      docId: readInt(json, 'docId'),
      docType: readString(json, 'docType'),
      docName: readString(json, 'docName'),
      fileUrl: readString(json, 'fileUrl'),
      fileId: _readNullableInt(json['fileId']),
      createdAt: readString(json, 'createdAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'docId': docId,
      'docType': docType,
      'docName': docName,
      'fileUrl': fileUrl,
      if (fileId != null) 'fileId': fileId,
      'createdAt': createdAt,
    };
  }
}

class UpdateEmployerBO {
  const UpdateEmployerBO({
    required this.companyName,
    required this.industry,
    required this.companySize,
    this.logoId,
    this.logoUrl,
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.country,
    required this.city,
  });

  final String companyName;
  final String industry;
  final String companySize;
  final int? logoId;
  final String? logoUrl;
  final String description;
  final String website;
  final int foundedYear;
  final String country;
  final String city;

  factory UpdateEmployerBO.fromJson(JsonMap json) {
    return UpdateEmployerBO(
      companyName: readString(json, 'companyName'),
      industry: readString(json, 'industry'),
      companySize: readString(json, 'companySize'),
      logoId: _readNullableInt(json['logoId']),
      logoUrl: _readNullableString(json['logoUrl']),
      description: readString(json, 'description'),
      website: readString(json, 'website'),
      foundedYear: readInt(json, 'foundedYear'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'companyName': companyName,
      'industry': industry,
      'companySize': companySize,
      if (logoId != null) 'logoId': logoId,
      if (logoUrl != null && logoUrl!.trim().isNotEmpty) 'logoUrl': logoUrl,
      'description': description,
      'website': website,
      'foundedYear': foundedYear,
      'country': country,
      'city': city,
    };
  }
}

int? _readNullableInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}
