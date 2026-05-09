import 'package:bluehub_app/shared/network/api_decoders.dart';

class EmployerProfileVO {
  const EmployerProfileVO({
    required this.profileId,
    required this.companyName,
    required this.industry,
    required this.companySize,
    required this.logoUrl,
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.country,
    required this.city,
    required this.isVerified,
  });

  final int profileId;
  final String companyName;
  final String industry;
  final String companySize;
  final String logoUrl;
  final String description;
  final String website;
  final int foundedYear;
  final String country;
  final String city;
  final bool isVerified;

  factory EmployerProfileVO.fromJson(JsonMap json) {
    return EmployerProfileVO(
      profileId: readInt(json, 'profileId'),
      companyName: readString(json, 'companyName'),
      industry: readString(json, 'industry'),
      companySize: readString(json, 'companySize'),
      logoUrl: readString(json, 'logoUrl'),
      description: readString(json, 'description'),
      website: readString(json, 'website'),
      foundedYear: readInt(json, 'foundedYear'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      isVerified: readBool(json, 'isVerified'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'profileId': profileId,
      'companyName': companyName,
      'industry': industry,
      'companySize': companySize,
      'logoUrl': logoUrl,
      'description': description,
      'website': website,
      'foundedYear': foundedYear,
      'country': country,
      'city': city,
      'isVerified': isVerified,
    };
  }
}

class UpdateEmployerBO {
  const UpdateEmployerBO({
    required this.companyName,
    required this.industry,
    required this.companySize,
    required this.logoId,
    required this.logoUrl,
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.country,
    required this.city,
  });

  final String companyName;
  final String industry;
  final String companySize;
  final int logoId;
  final String logoUrl;
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
      logoId: readInt(json, 'logoId'),
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
      'companyName': companyName,
      'industry': industry,
      'companySize': companySize,
      'logoId': logoId,
      'logoUrl': logoUrl,
      'description': description,
      'website': website,
      'foundedYear': foundedYear,
      'country': country,
      'city': city,
    };
  }
}
