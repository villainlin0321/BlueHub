import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateVisaOrderBO {
  const CreateVisaOrderBO({required this.packageId, required this.tierId});

  final int packageId;
  final int tierId;

  factory CreateVisaOrderBO.fromJson(JsonMap json) {
    return CreateVisaOrderBO(
      packageId: readInt(json, 'packageId'),
      tierId: readInt(json, 'tierId'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'packageId': packageId, 'tierId': tierId};
  }
}

class DocumentItemBO {
  const DocumentItemBO({
    required this.docName,
    required this.fileId,
    required this.fileUrl,
    required this.fileType,
  });

  final String docName;
  final int fileId;
  final String fileUrl;
  final String fileType;

  factory DocumentItemBO.fromJson(JsonMap json) {
    return DocumentItemBO(
      docName: readString(json, 'docName'),
      fileId: readInt(json, 'fileId'),
      fileUrl: readString(json, 'fileUrl'),
      fileType: readString(json, 'fileType'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'docName': docName,
      'fileId': fileId,
      'fileUrl': fileUrl,
      'fileType': fileType,
    };
  }
}

class MaterialItemBO {
  const MaterialItemBO({
    required this.materialName,
    required this.fileId,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
  });

  final String materialName;
  final int fileId;
  final String fileUrl;
  final String fileType;
  final int fileSize;

  factory MaterialItemBO.fromJson(JsonMap json) {
    return MaterialItemBO(
      materialName: readString(json, 'materialName'),
      fileId: readInt(json, 'fileId'),
      fileUrl: readString(json, 'fileUrl'),
      fileType: readString(json, 'fileType'),
      fileSize: readInt(json, 'fileSize'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materialName': materialName,
      'fileId': fileId,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
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

class PackageInfoVO {
  const PackageInfoVO({
    required this.packageName,
    required this.tierName,
    required this.amount,
    required this.currency,
  });

  final String packageName;
  final String tierName;
  final double amount;
  final String? currency;

  factory PackageInfoVO.fromJson(JsonMap json) {
    return PackageInfoVO(
      packageName: readString(json, 'packageName'),
      tierName: readString(json, 'tierName'),
      amount: readDouble(json, 'amount'),
      currency: _readNullableString(json['currency']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'packageName': packageName,
      'tierName': tierName,
      'amount': amount,
      'currency': currency,
    };
  }
}

class ProcessOrderBO {
  const ProcessOrderBO({
    required this.action,
    required this.remark,
    required this.nextStatus,
  });

  final String action;
  final String remark;
  final String nextStatus;

  factory ProcessOrderBO.fromJson(JsonMap json) {
    return ProcessOrderBO(
      action: readString(json, 'action'),
      remark: readString(json, 'remark'),
      nextStatus: readString(json, 'nextStatus'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'action': action,
      'remark': remark,
      'nextStatus': nextStatus,
    };
  }
}

class ProviderInfoVO {
  const ProviderInfoVO({required this.providerId, required this.name});

  const ProviderInfoVO.empty() : providerId = 0, name = '';

  final int providerId;
  final String name;

  factory ProviderInfoVO.fromJson(JsonMap json) {
    return ProviderInfoVO(
      providerId: readInt(json, 'providerId'),
      name: readString(json, 'name'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'providerId': providerId, 'name': name};
  }
}

class RequiredMaterialVO {
  const RequiredMaterialVO({
    required this.name,
    required this.description,
    required this.isRequired,
  });

  final String name;
  final String description;
  final bool isRequired;

  factory RequiredMaterialVO.fromJson(JsonMap json) {
    return RequiredMaterialVO(
      name: readString(json, 'name'),
      description: readString(json, 'description'),
      isRequired: readBool(json, 'isRequired'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'isRequired': isRequired,
    };
  }
}

class StepVO {
  const StepVO({required this.step, required this.label, required this.status});

  final int step;
  final String label;
  final String status;

  factory StepVO.fromJson(JsonMap json) {
    return StepVO(
      step: readInt(json, 'step'),
      label: readString(json, 'label'),
      status: readString(json, 'status'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'step': step, 'label': label, 'status': status};
  }
}

class UploadOrderMaterialsBO {
  const UploadOrderMaterialsBO({required this.materials});

  final List<MaterialItemBO> materials;

  factory UploadOrderMaterialsBO.fromJson(JsonMap json) {
    return UploadOrderMaterialsBO(
      materials: readModelList<MaterialItemBO>(json, 'materials', MaterialItemBO.fromJson),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class UploadVisaDocumentsBO {
  const UploadVisaDocumentsBO({required this.documents});

  final List<DocumentItemBO> documents;

  factory UploadVisaDocumentsBO.fromJson(JsonMap json) {
    return UploadVisaDocumentsBO(
      documents: readModelList<DocumentItemBO>(json, 'documents', DocumentItemBO.fromJson),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'documents': documents
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}

class VisaDocVO {
  const VisaDocVO({
    required this.docName,
    required this.fileUrl,
    required this.uploadedAt,
  });

  final String docName;
  final String fileUrl;
  final String uploadedAt;

  factory VisaDocVO.fromJson(JsonMap json) {
    return VisaDocVO(
      docName: readString(json, 'docName'),
      fileUrl: readString(json, 'fileUrl'),
      uploadedAt: readString(json, 'uploadedAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'docName': docName,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt,
    };
  }
}

class VisaOrderVO {
  const VisaOrderVO({
    required this.userId,
    required this.orderId,
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    required this.currentStep,
    required this.steps,
    required this.amount,
    required this.currency,
    required this.packageName,
    required this.tierName,
    required this.providerName,
    required this.packageInfo,
    required this.providerInfo,
    required this.requiredMaterials,
    required this.materials,
    required this.visaDocuments,
    required this.rejectReason,
    required this.isUrgent,
    required this.nickname,
    required this.avatarUrl,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentUrl,
  });

  final int userId;
  final int orderId;
  final String orderNo;
  final String status;
  final String statusLabel;
  final int currentStep;
  final List<StepVO> steps;
  final double amount;
  final String? currency;
  final String packageName;
  final String tierName;
  final String providerName;
  final PackageInfoVO packageInfo;
  final ProviderInfoVO providerInfo;
  final List<RequiredMaterialVO> requiredMaterials;
  final List<MaterialVO> materials;
  final List<VisaDocVO> visaDocuments;
  final String? rejectReason;
  final bool isUrgent;
  final String nickname;
  final String avatarUrl;
  final String country;
  final String createdAt;
  final String updatedAt;
  final String? paymentUrl;

  factory VisaOrderVO.fromJson(JsonMap json) {
    final JsonMap providerInfoJson = readJsonMap(json, 'providerInfo');
    return VisaOrderVO(
      userId: readInt(json, 'userId'),
      orderId: readInt(json, 'orderId'),
      orderNo: readString(json, 'orderNo'),
      status: readString(json, 'status'),
      statusLabel: readString(json, 'statusLabel'),
      currentStep: readInt(json, 'currentStep'),
      steps: readModelList<StepVO>(json, 'steps', StepVO.fromJson),
      amount: readDouble(json, 'amount'),
      currency: _readNullableString(json['currency']),
      packageName: readString(json, 'packageName'),
      tierName: readString(json, 'tierName'),
      providerName: readString(json, 'providerName'),
      packageInfo: PackageInfoVO.fromJson(
        readJsonMap(json, 'packageInfo'),
      ),
      providerInfo: providerInfoJson.isEmpty
          ? const ProviderInfoVO.empty()
          : ProviderInfoVO.fromJson(providerInfoJson),
      requiredMaterials: readModelList<RequiredMaterialVO>(
        json,
        'requiredMaterials',
        RequiredMaterialVO.fromJson,
      ),
      materials: readModelList<MaterialVO>(json, 'materials', MaterialVO.fromJson),
      visaDocuments: readModelList<VisaDocVO>(json, 'visaDocuments', VisaDocVO.fromJson),
      rejectReason: _readNullableString(json['rejectReason']),
      isUrgent: readBool(json, 'isUrgent'),
      nickname: readString(json, 'nickname'),
      avatarUrl: readString(json, 'avatarUrl'),
      country: readString(json, 'country'),
      createdAt: readString(json, 'createdAt'),
      updatedAt: readString(json, 'updatedAt'),
      paymentUrl: _readNullableString(json['paymentUrl']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'orderId': orderId,
      'orderNo': orderNo,
      'status': status,
      'statusLabel': statusLabel,
      'currentStep': currentStep,
      'steps': steps.map((item) => item.toJson()).toList(growable: false),
      'amount': amount,
      'currency': currency,
      'packageName': packageName,
      'tierName': tierName,
      'providerName': providerName,
      'packageInfo': packageInfo.toJson(),
      'providerInfo': providerInfo.toJson(),
      'requiredMaterials': requiredMaterials
          .map((item) => item.toJson())
          .toList(growable: false),
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
      'visaDocuments': visaDocuments
          .map((item) => item.toJson())
          .toList(growable: false),
      'rejectReason': rejectReason,
      'isUrgent': isUrgent,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'country': country,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentUrl': paymentUrl,
    };
  }
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
