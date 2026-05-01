import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateVisaPackageBO {
  const CreateVisaPackageBO({
    required this.name,
    required this.targetCountry,
    required this.visaType,
    required this.estimatedDays,
    required this.coverImageIds,
    required this.coverImages,
    required this.tiers,
    required this.isDraft,
  });

  final String name;
  final String targetCountry;
  final String visaType;
  final int estimatedDays;
  final List<int> coverImageIds;
  final List<String> coverImages;
  final List<TierBO> tiers;
  final bool isDraft;

  factory CreateVisaPackageBO.fromJson(JsonMap json) {
    return CreateVisaPackageBO(
      name: json['name'] as String? ?? '',
      targetCountry: json['targetCountry'] as String? ?? '',
      visaType: json['visaType'] as String? ?? '',
      estimatedDays: (json['estimatedDays'] as num?)?.toInt() ?? 0,
      coverImageIds: ((json['coverImageIds'] as List?) ?? const <dynamic>[])
          .map((item) => (item as num?)?.toInt() ?? 0)
          .toList(growable: false),
      coverImages: decodeStringList(json['coverImages'] ?? const <dynamic>[]),
      tiers: decodeModelList<TierBO>(
        json['tiers'] ?? const <dynamic>[],
        TierBO.fromJson,
      ),
      isDraft: json['isDraft'] as bool? ?? false,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'targetCountry': targetCountry,
      'visaType': visaType,
      'estimatedDays': estimatedDays,
      'coverImageIds': coverImageIds,
      'coverImages': coverImages,
      'tiers': tiers.map((item) => item.toJson()).toList(growable: false),
      'isDraft': isDraft,
    };
  }
}

class MaterialBO {
  const MaterialBO({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.sortOrder,
  });

  final String name;
  final String description;
  final bool isRequired;
  final int sortOrder;

  factory MaterialBO.fromJson(JsonMap json) {
    return MaterialBO(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'sortOrder': sortOrder,
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

class TierBO {
  const TierBO({
    required this.tierId,
    required this.name,
    required this.price,
    required this.services,
    required this.customServices,
    required this.description,
    required this.showMaterials,
    required this.sortOrder,
    required this.materials,
  });

  final int tierId;
  final String name;
  final double price;
  final List<String> services;
  final List<String> customServices;
  final String description;
  final bool showMaterials;
  final int sortOrder;
  final List<MaterialBO> materials;

  factory TierBO.fromJson(JsonMap json) {
    return TierBO(
      tierId: (json['tierId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      services: decodeStringList(json['services'] ?? const <dynamic>[]),
      customServices: decodeStringList(
        json['customServices'] ?? const <dynamic>[],
      ),
      description: json['description'] as String? ?? '',
      showMaterials: json['showMaterials'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      materials: decodeModelList<MaterialBO>(
        json['materials'] ?? const <dynamic>[],
        MaterialBO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'tierId': tierId,
      'name': name,
      'price': price,
      'services': services,
      'customServices': customServices,
      'description': description,
      'showMaterials': showMaterials,
      'sortOrder': sortOrder,
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
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

class UpdatePackageStatusBO {
  const UpdatePackageStatusBO({required this.status});

  final String status;

  factory UpdatePackageStatusBO.fromJson(JsonMap json) {
    return UpdatePackageStatusBO(status: json['status'] as String? ?? '');
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status};
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
