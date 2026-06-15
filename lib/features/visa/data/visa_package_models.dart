import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateVisaPackageBO {
  const CreateVisaPackageBO({
    required this.name,
    required this.targetCountry,
    required this.visaType,
    required this.estimatedDays,
    required this.currency,
    required this.coverImageIds,
    required this.coverImages,
    required this.tiers,
    required this.isDraft,
  });

  final String name;
  final String targetCountry;
  final String visaType;
  final int estimatedDays;
  final String currency;
  final List<int> coverImageIds;
  final List<String> coverImages;
  final List<TierBO> tiers;
  final bool isDraft;

  factory CreateVisaPackageBO.fromJson(JsonMap json) {
    return CreateVisaPackageBO(
      name: readString(json, 'name'),
      targetCountry: readString(json, 'targetCountry'),
      visaType: readString(json, 'visaType'),
      estimatedDays: readInt(json, 'estimatedDays'),
      currency: readString(json, 'currency'),
      coverImageIds: readIntList(json, 'coverImageIds'),
      coverImages: readStringList(json, 'coverImages'),
      tiers: readModelList<TierBO>(json, 'tiers', TierBO.fromJson),
      isDraft: readBool(json, 'isDraft'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'targetCountry': targetCountry,
      'visaType': visaType,
      'estimatedDays': estimatedDays,
      'currency': currency,
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
    this.exampleFileIds = const <int>[],
  });

  final String name;
  final String description;
  final bool isRequired;
  final int sortOrder;
  final List<int> exampleFileIds;

  factory MaterialBO.fromJson(JsonMap json) {
    return MaterialBO(
      name: readString(json, 'name'),
      description: readString(json, 'description'),
      isRequired: readBool(json, 'isRequired'),
      sortOrder: readInt(json, 'sortOrder'),
      exampleFileIds: readIntList(json, 'exampleFileIds'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'sortOrder': sortOrder,
      if (exampleFileIds.isNotEmpty) 'exampleFileIds': exampleFileIds,
    };
  }
}

class MaterialVO {
  const MaterialVO({
    required this.materialName,
    required this.description,
    required this.isRequired,
    required this.sortOrder,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.exampleFileUrls = const <String>[],
  });

  final String materialName;
  final String description;
  final bool isRequired;
  final int sortOrder;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedAt;
  final List<String> exampleFileUrls;

  factory MaterialVO.fromJson(JsonMap json) {
    return MaterialVO(
      materialName: readString(
        json,
        'materialName',
        fallback: readString(json, 'name'),
      ),
      description: readString(json, 'description'),
      isRequired: readBool(json, 'isRequired'),
      sortOrder: readInt(json, 'sortOrder'),
      fileUrl: readString(json, 'fileUrl'),
      fileType: readString(json, 'fileType'),
      fileSize: readInt(json, 'fileSize'),
      uploadedAt: readString(json, 'uploadedAt'),
      exampleFileUrls: readStringList(json, 'exampleFileUrls'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materialName': materialName,
      'name': materialName,
      'description': description,
      'isRequired': isRequired,
      'sortOrder': sortOrder,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'exampleFileUrls': exampleFileUrls,
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
      tierId: readInt(json, 'tierId'),
      name: readString(json, 'name'),
      price: readDouble(json, 'price'),
      services: readStringList(json, 'services'),
      customServices: readStringList(json, 'customServices'),
      description: readString(json, 'description'),
      showMaterials: readBool(json, 'showMaterials'),
      sortOrder: readInt(json, 'sortOrder'),
      materials: readModelList<MaterialBO>(
        json,
        'materials',
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
    required this.customServices,
    required this.description,
    required this.showMaterials,
    required this.materials,
    required this.soldCount,
  });

  final int tierId;
  final String name;
  final double price;
  final List<String> services;
  final List<String> customServices;
  final String description;
  final bool showMaterials;
  final List<MaterialBO> materials;
  final int soldCount;

  factory TierVO.fromJson(JsonMap json) {
    return TierVO(
      tierId: readInt(json, 'tierId'),
      name: readString(json, 'name'),
      price: readDouble(json, 'price'),
      services: readStringList(json, 'services'),
      customServices: readStringList(json, 'customServices'),
      description: readString(json, 'description'),
      showMaterials: readBool(json, 'showMaterials'),
      materials: readModelList<MaterialBO>(
        json,
        'materials',
        MaterialBO.fromJson,
      ),
      soldCount: readInt(json, 'soldCount'),
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
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
      'soldCount': soldCount,
    };
  }
}

class UpdatePackageStatusBO {
  const UpdatePackageStatusBO({required this.status});

  final String status;

  factory UpdatePackageStatusBO.fromJson(JsonMap json) {
    return UpdatePackageStatusBO(status: readString(json, 'status'));
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status};
  }
}

class VisaPackageVO {
  const VisaPackageVO({
    required this.providerId,
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

  final int providerId;
  final int packageId;
  final String name;
  final String targetCountry;
  final String visaType;
  final int estimatedDays;
  final String currency;
  final List<String> coverImages;
  final List<TierVO> tiers;
  final List<MaterialVO> requiredMaterials;

  /// 安全解析签证套餐详情，兼容后端返回币种和材料字段的类型波动。
  factory VisaPackageVO.fromJson(JsonMap json) {
    return VisaPackageVO(
      providerId: readInt(json, 'providerId'),
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
      'providerId': providerId,
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
