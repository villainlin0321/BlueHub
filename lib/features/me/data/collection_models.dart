import 'package:bluehub_app/shared/network/api_decoders.dart';

class CollectionBO {
  const CollectionBO({required this.targetType, required this.targetId});

  final String targetType;
  final int targetId;

  factory CollectionBO.fromJson(JsonMap json) {
    return CollectionBO(
      targetType: readString(json, 'targetType'),
      targetId: readInt(json, 'targetId'),
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
      employerId: readInt(json, 'employerId'),
      name: readString(json, 'name'),
      logoUrl: readString(json, 'logoUrl'),
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
      jobId: readInt(json, 'jobId'),
      title: readString(json, 'title'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
      salaryPeriod: readString(json, 'salaryPeriod'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      tags: readModelList<TagVO>(json, 'tags', TagVO.fromJson),
      hasVisaSupport: readBool(json, 'hasVisaSupport'),
      employer: EmployerSimpleVO.fromJson(
        readJsonMap(json, 'employer'),
      ),
      isUrgent: readBool(json, 'isUrgent'),
      isCollected: readBool(json, 'isCollected'),
      publishedAt: readString(json, 'publishedAt'),
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

class TagVO {
  const TagVO({required this.type, required this.label, required this.color});

  final String type;
  final String label;
  final String color;

  factory TagVO.fromJson(JsonMap json) {
    return TagVO(
      type: readString(json, 'type'),
      label: readString(json, 'label'),
      color: readString(json, 'color'),
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
      packageId: readInt(json, 'packageId'),
      name: readString(json, 'name'),
      targetCountry: readString(json, 'targetCountry'),
      visaType: readString(json, 'visaType'),
      estimatedDays: readInt(json, 'estimatedDays'),
      coverImages: readStringList(json, 'coverImages'),
      tiers: readModelList<TierVO>(json, 'tiers', TierVO.fromJson),
      requiredMaterials: readModelList<MaterialVO>(json, 'requiredMaterials', MaterialVO.fromJson),
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
