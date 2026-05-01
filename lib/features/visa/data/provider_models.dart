import 'package:bluehub_app/shared/network/api_decoders.dart';

class DocItemBO {
  const DocItemBO({
    required this.docType,
    required this.docName,
    required this.fileId,
    required this.fileUrl,
  });

  final String docType;
  final String docName;
  final int fileId;
  final String fileUrl;

  factory DocItemBO.fromJson(JsonMap json) {
    return DocItemBO(
      docType: json['docType'] as String? ?? '',
      docName: json['docName'] as String? ?? '',
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'docType': docType,
      'docName': docName,
      'fileId': fileId,
      'fileUrl': fileUrl,
    };
  }
}

class MaterialVO {
  const MaterialVO({
    required this.materialName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  final String materialName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedAt;

  factory MaterialVO.fromJson(JsonMap json) {
    return MaterialVO(
      materialName: json['materialName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      uploadedAt: json['uploadedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materialName': materialName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
    };
  }
}

class PackageSimpleVO {
  const PackageSimpleVO({
    required this.packageId,
    required this.name,
    required this.priceFrom,
  });

  final int packageId;
  final String name;
  final double priceFrom;

  factory PackageSimpleVO.fromJson(JsonMap json) {
    return PackageSimpleVO(
      packageId: (json['packageId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      priceFrom: (json['priceFrom'] as num?)?.toDouble() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'packageId': packageId,
      'name': name,
      'priceFrom': priceFrom,
    };
  }
}

class ProviderVO {
  const ProviderVO({
    required this.providerId,
    required this.name,
    required this.logoUrl,
    required this.isVerified,
    required this.rating,
    required this.caseCount,
    required this.servicePromise,
    required this.brief,
    required this.serviceCountries,
    required this.yearsOfService,
  });

  final int providerId;
  final String name;
  final String logoUrl;
  final bool isVerified;
  final double rating;
  final int caseCount;
  final String servicePromise;
  final String brief;
  final List<String> serviceCountries;
  final int yearsOfService;

  factory ProviderVO.fromJson(JsonMap json) {
    return ProviderVO(
      providerId: (json['providerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      caseCount: (json['caseCount'] as num?)?.toInt() ?? 0,
      servicePromise: json['servicePromise'] as String? ?? '',
      brief: json['brief'] as String? ?? '',
      serviceCountries: decodeStringList(
        json['serviceCountries'] ?? const <dynamic>[],
      ),
      yearsOfService: (json['yearsOfService'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'providerId': providerId,
      'name': name,
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'rating': rating,
      'caseCount': caseCount,
      'servicePromise': servicePromise,
      'brief': brief,
      'serviceCountries': serviceCountries,
      'yearsOfService': yearsOfService,
    };
  }
}

class ReviewItemVO {
  const ReviewItemVO({
    required this.reviewId,
    required this.user,
    required this.rating,
    required this.content,
    required this.images,
    required this.createdAt,
    required this.isExpanded,
  });

  final int reviewId;
  final UserSimpleVO user;
  final int rating;
  final String content;
  final List<String> images;
  final String createdAt;
  final bool isExpanded;

  factory ReviewItemVO.fromJson(JsonMap json) {
    return ReviewItemVO(
      reviewId: (json['reviewId'] as num?)?.toInt() ?? 0,
      user: UserSimpleVO.fromJson(
        asJsonMap(json['user'] ?? const <String, dynamic>{}),
      ),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      images: decodeStringList(json['images'] ?? const <dynamic>[]),
      createdAt: json['createdAt'] as String? ?? '',
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'reviewId': reviewId,
      'user': user.toJson(),
      'rating': rating,
      'content': content,
      'images': images,
      'createdAt': createdAt,
      'isExpanded': isExpanded,
    };
  }
}

class ReviewVO {
  const ReviewVO({required this.summary, required this.list});

  final SummaryVO summary;
  final List<ReviewItemVO> list;

  factory ReviewVO.fromJson(JsonMap json) {
    return ReviewVO(
      summary: SummaryVO.fromJson(
        asJsonMap(json['summary'] ?? const <String, dynamic>{}),
      ),
      list: decodeModelList<ReviewItemVO>(
        json['list'] ?? const <dynamic>[],
        ReviewItemVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'summary': summary.toJson(),
      'list': list.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class SummaryVO {
  const SummaryVO({
    required this.averageRating,
    required this.totalCount,
    required this.label,
  });

  final double averageRating;
  final int totalCount;
  final String label;

  factory SummaryVO.fromJson(JsonMap json) {
    return SummaryVO(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'averageRating': averageRating,
      'totalCount': totalCount,
      'label': label,
    };
  }
}

class TierVO {
  const TierVO({
    required this.tierId,
    required this.name,
    required this.price,
    required this.services,
    required this.description,
    required this.soldCount,
  });

  final int tierId;
  final String name;
  final double price;
  final List<String> services;
  final String description;
  final int soldCount;

  factory TierVO.fromJson(JsonMap json) {
    return TierVO(
      tierId: (json['tierId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      services: decodeStringList(json['services'] ?? const <dynamic>[]),
      description: json['description'] as String? ?? '',
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'tierId': tierId,
      'name': name,
      'price': price,
      'services': services,
      'description': description,
      'soldCount': soldCount,
    };
  }
}

class UpdateVisaProviderBO {
  const UpdateVisaProviderBO({
    required this.companyName,
    required this.unifiedCreditCode,
    required this.legalPerson,
    required this.contactPerson,
    required this.contactPhone,
    required this.contactEmail,
    required this.website,
    required this.yearsOfService,
    required this.logoId,
    required this.logoUrl,
    required this.brief,
    required this.servicePromise,
    required this.serviceCountries,
  });

  final String companyName;
  final String unifiedCreditCode;
  final String legalPerson;
  final String contactPerson;
  final String contactPhone;
  final String contactEmail;
  final String website;
  final int yearsOfService;
  final int logoId;
  final String logoUrl;
  final String brief;
  final String servicePromise;
  final List<String> serviceCountries;

  factory UpdateVisaProviderBO.fromJson(JsonMap json) {
    return UpdateVisaProviderBO(
      companyName: json['companyName'] as String? ?? '',
      unifiedCreditCode: json['unifiedCreditCode'] as String? ?? '',
      legalPerson: json['legalPerson'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      website: json['website'] as String? ?? '',
      yearsOfService: (json['yearsOfService'] as num?)?.toInt() ?? 0,
      logoId: (json['logoId'] as num?)?.toInt() ?? 0,
      logoUrl: json['logoUrl'] as String? ?? '',
      brief: json['brief'] as String? ?? '',
      servicePromise: json['servicePromise'] as String? ?? '',
      serviceCountries: decodeStringList(
        json['serviceCountries'] ?? const <dynamic>[],
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'companyName': companyName,
      'unifiedCreditCode': unifiedCreditCode,
      'legalPerson': legalPerson,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'website': website,
      'yearsOfService': yearsOfService,
      'logoId': logoId,
      'logoUrl': logoUrl,
      'brief': brief,
      'servicePromise': servicePromise,
      'serviceCountries': serviceCountries,
    };
  }
}

class UploadQualificationDocsBO {
  const UploadQualificationDocsBO({required this.docs});

  final List<DocItemBO> docs;

  factory UploadQualificationDocsBO.fromJson(JsonMap json) {
    return UploadQualificationDocsBO(
      docs: decodeModelList<DocItemBO>(
        json['docs'] ?? const <dynamic>[],
        DocItemBO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'docs': docs.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class UserSimpleVO {
  const UserSimpleVO({
    required this.userId,
    required this.phone,
    required this.countryCode,
    required this.role,
    required this.avatarUrl,
    required this.nickname,
    required this.email,
  });

  final int userId;
  final String phone;
  final String countryCode;
  final String role;
  final String avatarUrl;
  final String nickname;
  final String email;

  factory UserSimpleVO.fromJson(JsonMap json) {
    return UserSimpleVO(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      role: json['role'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'phone': phone,
      'countryCode': countryCode,
      'role': role,
      'avatarUrl': avatarUrl,
      'nickname': nickname,
      'email': email,
    };
  }
}

class VisaPackageVO {
  const VisaPackageVO({
    required this.packageId,
    required this.name,
    required this.targetCountry,
    required this.visaType,
    required this.estimatedDays,
    required this.coverImages,
    required this.tiers,
    required this.requiredMaterials,
  });

  final int packageId;
  final String name;
  final String targetCountry;
  final String visaType;
  final int estimatedDays;
  final List<String> coverImages;
  final List<TierVO> tiers;
  final List<MaterialVO> requiredMaterials;

  factory VisaPackageVO.fromJson(JsonMap json) {
    return VisaPackageVO(
      packageId: (json['packageId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      targetCountry: json['targetCountry'] as String? ?? '',
      visaType: json['visaType'] as String? ?? '',
      estimatedDays: (json['estimatedDays'] as num?)?.toInt() ?? 0,
      coverImages: decodeStringList(json['coverImages'] ?? const <dynamic>[]),
      tiers: decodeModelList<TierVO>(
        json['tiers'] ?? const <dynamic>[],
        TierVO.fromJson,
      ),
      requiredMaterials: decodeModelList<MaterialVO>(
        json['requiredMaterials'] ?? const <dynamic>[],
        MaterialVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'packageId': packageId,
      'name': name,
      'targetCountry': targetCountry,
      'visaType': visaType,
      'estimatedDays': estimatedDays,
      'coverImages': coverImages,
      'tiers': tiers.map((item) => item.toJson()).toList(growable: false),
      'requiredMaterials': requiredMaterials
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class VisaProviderDetailVO {
  const VisaProviderDetailVO({required this.provider, required this.packages});

  final ProviderVO provider;
  final List<VisaPackageVO> packages;

  factory VisaProviderDetailVO.fromJson(JsonMap json) {
    return VisaProviderDetailVO(
      provider: ProviderVO.fromJson(
        asJsonMap(json['provider'] ?? const <String, dynamic>{}),
      ),
      packages: decodeModelList<VisaPackageVO>(
        json['packages'] ?? const <dynamic>[],
        VisaPackageVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'provider': provider.toJson(),
      'packages': packages.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class VisaProviderListVO {
  const VisaProviderListVO({
    required this.providerId,
    required this.name,
    required this.logoUrl,
    required this.isVerified,
    required this.rating,
    required this.caseCount,
    required this.tags,
    required this.brief,
    required this.latestPackage,
  });

  final int providerId;
  final String name;
  final String logoUrl;
  final bool isVerified;
  final double rating;
  final int caseCount;
  final List<String> tags;
  final String brief;
  final PackageSimpleVO latestPackage;

  factory VisaProviderListVO.fromJson(JsonMap json) {
    return VisaProviderListVO(
      providerId: (json['providerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      caseCount: (json['caseCount'] as num?)?.toInt() ?? 0,
      tags: decodeStringList(json['tags'] ?? const <dynamic>[]),
      brief: json['brief'] as String? ?? '',
      latestPackage: PackageSimpleVO.fromJson(
        asJsonMap(json['latestPackage'] ?? const <String, dynamic>{}),
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'providerId': providerId,
      'name': name,
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'rating': rating,
      'caseCount': caseCount,
      'tags': tags,
      'brief': brief,
      'latestPackage': latestPackage.toJson(),
    };
  }
}
