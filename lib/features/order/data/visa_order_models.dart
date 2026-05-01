import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateVisaOrderBO {
  const CreateVisaOrderBO({required this.packageId, required this.tierId});

  final int packageId;
  final int tierId;

  factory CreateVisaOrderBO.fromJson(JsonMap json) {
    return CreateVisaOrderBO(
      packageId: (json['packageId'] as num?)?.toInt() ?? 0,
      tierId: (json['tierId'] as num?)?.toInt() ?? 0,
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
      docName: json['docName'] as String? ?? '',
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
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
      materialName: json['materialName'] as String? ?? '',
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
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

class PackageInfoVO {
  const PackageInfoVO({
    required this.packageName,
    required this.tierName,
    required this.amount,
  });

  final String packageName;
  final String tierName;
  final double amount;

  factory PackageInfoVO.fromJson(JsonMap json) {
    return PackageInfoVO(
      packageName: json['packageName'] as String? ?? '',
      tierName: json['tierName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'packageName': packageName,
      'tierName': tierName,
      'amount': amount,
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
      action: json['action'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      nextStatus: json['nextStatus'] as String? ?? '',
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

  final int providerId;
  final String name;

  factory ProviderInfoVO.fromJson(JsonMap json) {
    return ProviderInfoVO(
      providerId: (json['providerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'providerId': providerId, 'name': name};
  }
}

class StepVO {
  const StepVO({required this.step, required this.label, required this.status});

  final int step;
  final String label;
  final String status;

  factory StepVO.fromJson(JsonMap json) {
    return StepVO(
      step: (json['step'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      status: json['status'] as String? ?? '',
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
      materials: decodeModelList<MaterialItemBO>(
        json['materials'] ?? const <dynamic>[],
        MaterialItemBO.fromJson,
      ),
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
      documents: decodeModelList<DocumentItemBO>(
        json['documents'] ?? const <dynamic>[],
        DocumentItemBO.fromJson,
      ),
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
      docName: json['docName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      uploadedAt: json['uploadedAt'] as String? ?? '',
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
    required this.orderId,
    required this.orderNo,
    required this.status,
    required this.statusLabel,
    required this.currentStep,
    required this.steps,
    required this.amount,
    required this.packageName,
    required this.tierName,
    required this.providerName,
    required this.packageInfo,
    required this.providerInfo,
    required this.materials,
    required this.visaDocuments,
    required this.rejectReason,
    required this.isUrgent,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentUrl,
  });

  final int orderId;
  final String orderNo;
  final String status;
  final String statusLabel;
  final int currentStep;
  final List<StepVO> steps;
  final double amount;
  final String packageName;
  final String tierName;
  final String providerName;
  final PackageInfoVO packageInfo;
  final ProviderInfoVO providerInfo;
  final List<MaterialVO> materials;
  final List<VisaDocVO> visaDocuments;
  final String rejectReason;
  final bool isUrgent;
  final String createdAt;
  final String updatedAt;
  final String paymentUrl;

  factory VisaOrderVO.fromJson(JsonMap json) {
    return VisaOrderVO(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['statusLabel'] as String? ?? '',
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      steps: decodeModelList<StepVO>(
        json['steps'] ?? const <dynamic>[],
        StepVO.fromJson,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      packageName: json['packageName'] as String? ?? '',
      tierName: json['tierName'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      packageInfo: PackageInfoVO.fromJson(
        asJsonMap(json['packageInfo'] ?? const <String, dynamic>{}),
      ),
      providerInfo: ProviderInfoVO.fromJson(
        asJsonMap(json['providerInfo'] ?? const <String, dynamic>{}),
      ),
      materials: decodeModelList<MaterialVO>(
        json['materials'] ?? const <dynamic>[],
        MaterialVO.fromJson,
      ),
      visaDocuments: decodeModelList<VisaDocVO>(
        json['visaDocuments'] ?? const <dynamic>[],
        VisaDocVO.fromJson,
      ),
      rejectReason: json['rejectReason'] as String? ?? '',
      isUrgent: json['isUrgent'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'orderNo': orderNo,
      'status': status,
      'statusLabel': statusLabel,
      'currentStep': currentStep,
      'steps': steps.map((item) => item.toJson()).toList(growable: false),
      'amount': amount,
      'packageName': packageName,
      'tierName': tierName,
      'providerName': providerName,
      'packageInfo': packageInfo.toJson(),
      'providerInfo': providerInfo.toJson(),
      'materials': materials
          .map((item) => item.toJson())
          .toList(growable: false),
      'visaDocuments': visaDocuments
          .map((item) => item.toJson())
          .toList(growable: false),
      'rejectReason': rejectReason,
      'isUrgent': isUrgent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentUrl': paymentUrl,
    };
  }
}
