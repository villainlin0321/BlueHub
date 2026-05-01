import 'package:bluehub_app/shared/network/api_decoders.dart';

class CollectionBO {
  const CollectionBO({required this.targetType, required this.targetId});

  final String targetType;
  final int targetId;

  factory CollectionBO.fromJson(JsonMap json) {
    return CollectionBO(
      targetType: json['targetType'] as String? ?? '',
      targetId: (json['targetId'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'targetType': targetType, 'targetId': targetId};
  }
}

class EmployerSimpleVO {
  const EmployerSimpleVO({
    required this.employerId,
    required this.name,
    required this.logoUrl,
  });

  final int employerId;
  final String name;
  final String logoUrl;

  factory EmployerSimpleVO.fromJson(JsonMap json) {
    return EmployerSimpleVO(
      employerId: (json['employerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'employerId': employerId,
      'name': name,
      'logoUrl': logoUrl,
    };
  }
}

class JobListVO {
  const JobListVO({
    required this.jobId,
    required this.title,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    required this.country,
    required this.city,
    required this.tags,
    required this.hasVisaSupport,
    required this.employer,
    required this.isUrgent,
    required this.isCollected,
    required this.publishedAt,
  });

  final int jobId;
  final String title;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final String country;
  final String city;
  final List<TagVO> tags;
  final bool hasVisaSupport;
  final EmployerSimpleVO employer;
  final bool isUrgent;
  final bool isCollected;
  final String publishedAt;

  factory JobListVO.fromJson(JsonMap json) {
    return JobListVO(
      jobId: (json['jobId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
      salaryPeriod: json['salaryPeriod'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      tags: decodeModelList<TagVO>(
        json['tags'] ?? const <dynamic>[],
        TagVO.fromJson,
      ),
      hasVisaSupport: json['hasVisaSupport'] as bool? ?? false,
      employer: EmployerSimpleVO.fromJson(
        asJsonMap(json['employer'] ?? const <String, dynamic>{}),
      ),
      isUrgent: json['isUrgent'] as bool? ?? false,
      isCollected: json['isCollected'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'title': title,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'salaryPeriod': salaryPeriod,
      'country': country,
      'city': city,
      'tags': tags.map((item) => item.toJson()).toList(growable: false),
      'hasVisaSupport': hasVisaSupport,
      'employer': employer.toJson(),
      'isUrgent': isUrgent,
      'isCollected': isCollected,
      'publishedAt': publishedAt,
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

class TagVO {
  const TagVO({required this.type, required this.label, required this.color});

  final String type;
  final String label;
  final String color;

  factory TagVO.fromJson(JsonMap json) {
    return TagVO(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'type': type, 'label': label, 'color': color};
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
