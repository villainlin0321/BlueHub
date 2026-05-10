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
      docType: readString(json, 'docType'),
      docName: readString(json, 'docName'),
      fileId: readInt(json, 'fileId'),
      fileUrl: readString(json, 'fileUrl'),
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
      materialName: readString(json, 'materialName'),
      fileUrl: readString(json, 'fileUrl'),
      fileType: readString(json, 'fileType'),
      fileSize: readInt(json, 'fileSize'),
      uploadedAt: readString(json, 'uploadedAt'),
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
      packageId: readInt(json, 'packageId'),
      name: readString(json, 'name'),
      priceFrom: readDouble(json, 'priceFrom'),
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
      providerId: readInt(json, 'providerId'),
      name: readString(json, 'name'),
      logoUrl: readString(json, 'logoUrl'),
      isVerified: readBool(json, 'isVerified'),
      rating: readDouble(json, 'rating'),
      caseCount: readInt(json, 'caseCount'),
      servicePromise: readString(json, 'servicePromise'),
      brief: readString(json, 'brief'),
      serviceCountries: readStringList(json, 'serviceCountries'),
      yearsOfService: readInt(json, 'yearsOfService'),
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
      reviewId: readInt(json, 'reviewId'),
      user: UserSimpleVO.fromJson(readJsonMap(json, 'user')),
      rating: readInt(json, 'rating'),
      content: readString(json, 'content'),
      images: readStringList(json, 'images'),
      createdAt: readString(json, 'createdAt'),
      isExpanded: readBool(json, 'isExpanded'),
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
      summary: SummaryVO.fromJson(readJsonMap(json, 'summary')),
      list: readModelList<ReviewItemVO>(json, 'list', ReviewItemVO.fromJson),
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
      averageRating: readDouble(json, 'averageRating'),
      totalCount: readInt(json, 'totalCount'),
      label: readString(json, 'label'),
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
      tierId: readInt(json, 'tierId'),
      name: readString(json, 'name'),
      price: readDouble(json, 'price'),
      services: readStringList(json, 'services'),
      description: readString(json, 'description'),
      soldCount: readInt(json, 'soldCount'),
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
      companyName: readString(json, 'companyName'),
      unifiedCreditCode: readString(json, 'unifiedCreditCode'),
      legalPerson: readString(json, 'legalPerson'),
      contactPerson: readString(json, 'contactPerson'),
      contactPhone: readString(json, 'contactPhone'),
      contactEmail: readString(json, 'contactEmail'),
      website: readString(json, 'website'),
      yearsOfService: readInt(json, 'yearsOfService'),
      logoId: readInt(json, 'logoId'),
      logoUrl: readString(json, 'logoUrl'),
      brief: readString(json, 'brief'),
      servicePromise: readString(json, 'servicePromise'),
      serviceCountries: readStringList(json, 'serviceCountries'),
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
      docs: readModelList<DocItemBO>(json, 'docs', DocItemBO.fromJson),
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
      userId: readInt(json, 'userId'),
      phone: readString(json, 'phone'),
      countryCode: readString(json, 'countryCode'),
      role: readString(json, 'role'),
      avatarUrl: readString(json, 'avatarUrl'),
      nickname: readString(json, 'nickname'),
      email: readString(json, 'email'),
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
    required this.currency,
    required this.coverImages,
    required this.tiers,
    required this.requiredMaterials,
  });

  final int packageId;
  final String name;
  final String targetCountry;
  final String visaType;
  final int estimatedDays;
  final String currency;
  final List<String> coverImages;
  final List<TierVO> tiers;
  final List<MaterialVO> requiredMaterials;

  /// 安全解析服务商详情中的签证套餐，避免缺少币种时影响页面价格展示。
  factory VisaPackageVO.fromJson(JsonMap json) {
    return VisaPackageVO(
      packageId: readInt(json, 'packageId'),
      name: readString(json, 'name'),
      targetCountry: readString(json, 'targetCountry'),
      visaType: readString(json, 'visaType'),
      estimatedDays: readInt(json, 'estimatedDays'),
      currency: readString(json, 'currency', fallback: 'CNY'),
      coverImages: readStringList(json, 'coverImages'),
      tiers: readModelList<TierVO>(json, 'tiers', TierVO.fromJson),
      requiredMaterials: readModelList<MaterialVO>(
        json,
        'requiredMaterials',
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
      'currency': currency,
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
      provider: ProviderVO.fromJson(readJsonMap(json, 'provider')),
      packages: readModelList<VisaPackageVO>(
        json,
        'packages',
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
      providerId: readInt(json, 'providerId'),
      name: readString(json, 'name'),
      logoUrl: readString(json, 'logoUrl'),
      isVerified: readBool(json, 'isVerified'),
      rating: readDouble(json, 'rating'),
      caseCount: readInt(json, 'caseCount'),
      tags: readStringList(json, 'tags'),
      brief: readString(json, 'brief'),
      latestPackage: PackageSimpleVO.fromJson(
        readJsonMap(json, 'latestPackage'),
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
