import 'package:europepass/shared/network/api_decoders.dart';

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
    required this.materialId,
    required this.materialName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.rejectReason,
  });

  final int materialId;
  final String materialName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedAt;
  final String? rejectReason;

  factory MaterialVO.fromJson(JsonMap json) {
    return MaterialVO(
      materialId: readInt(json, 'materialId'),
      materialName: readString(json, 'materialName'),
      fileUrl: readString(json, 'fileUrl'),
      fileType: readString(json, 'fileType'),
      fileSize: readInt(json, 'fileSize'),
      uploadedAt: readString(json, 'uploadedAt'),
      rejectReason: _readNullableString(json['rejectReason']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materialId': materialId,
      'materialName': materialName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'rejectReason': rejectReason,
    };
  }
}

class OrderMaterialRejectionBO {
  const OrderMaterialRejectionBO({
    required this.materialId,
    required this.reason,
  });

  final int materialId;
  final String reason;

  factory OrderMaterialRejectionBO.fromJson(JsonMap json) {
    return OrderMaterialRejectionBO(
      materialId: readInt(json, 'materialId'),
      reason: readString(json, 'reason'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'materialId': materialId, 'reason': reason};
  }
}

class OrderRejectItemVO {
  const OrderRejectItemVO({
    required this.materialId,
    required this.materialName,
    required this.fileUrl,
    required this.reason,
  });

  final int materialId;
  final String materialName;
  final String fileUrl;
  final String reason;

  factory OrderRejectItemVO.fromJson(JsonMap json) {
    return OrderRejectItemVO(
      materialId: readInt(json, 'materialId'),
      materialName: readString(json, 'materialName'),
      fileUrl: readString(json, 'fileUrl'),
      reason: readString(json, 'reason'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'materialId': materialId,
      'materialName': materialName,
      'fileUrl': fileUrl,
      'reason': reason,
    };
  }
}

class OrderRejectRecordVO {
  const OrderRejectRecordVO({
    required this.rejectId,
    required this.remark,
    required this.rejectedAt,
    required this.items,
  });

  final int rejectId;
  final String? remark;
  final String rejectedAt;
  final List<OrderRejectItemVO> items;

  factory OrderRejectRecordVO.fromJson(JsonMap json) {
    return OrderRejectRecordVO(
      rejectId: readInt(json, 'rejectId'),
      remark: _readNullableString(json['remark']),
      rejectedAt: readString(json, 'rejectedAt'),
      items: readModelList<OrderRejectItemVO>(
        json,
        'items',
        OrderRejectItemVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'rejectId': rejectId,
      'remark': remark,
      'rejectedAt': rejectedAt,
      'items': items.map((item) => item.toJson()).toList(growable: false),
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
    this.remark,
    this.materialRejections,
    this.nextStatus,
  });

  final String action;
  final String? remark;
  final List<OrderMaterialRejectionBO>? materialRejections;
  final String? nextStatus;

  factory ProcessOrderBO.fromJson(JsonMap json) {
    return ProcessOrderBO(
      action: readString(json, 'action'),
      remark: _readNullableString(json['remark']),
      materialRejections: _readNullableModelList<OrderMaterialRejectionBO>(
        json['materialRejections'],
        OrderMaterialRejectionBO.fromJson,
      ),
      nextStatus: _readNullableString(json['nextStatus']),
    );
  }

  JsonMap toJson() {
    final JsonMap result = <String, dynamic>{'action': action};
    if ((remark ?? '').trim().isNotEmpty) {
      result['remark'] = remark!.trim();
    }
    final List<OrderMaterialRejectionBO>? rejections = materialRejections;
    if (rejections != null && rejections.isNotEmpty) {
      result['materialRejections'] = rejections
          .map((item) => item.toJson())
          .toList(growable: false);
    }
    if ((nextStatus ?? '').trim().isNotEmpty) {
      result['nextStatus'] = nextStatus!.trim();
    }
    return result;
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
    required this.exampleFileUrls,
  });

  final String name;
  final String description;
  final bool isRequired;
  final List<String> exampleFileUrls;

  factory RequiredMaterialVO.fromJson(JsonMap json) {
    return RequiredMaterialVO(
      name: readString(json, 'name'),
      description: readString(json, 'description'),
      isRequired: readBool(json, 'isRequired'),
      exampleFileUrls: readStringList(json, 'exampleFileUrls'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'isRequired': isRequired,
      'exampleFileUrls': exampleFileUrls,
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
      materials: readModelList<MaterialItemBO>(
        json,
        'materials',
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
      documents: readModelList<DocumentItemBO>(
        json,
        'documents',
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

class ApplicantInfoVO {
  const ApplicantInfoVO({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.type,
    required this.profileId,
  });

  const ApplicantInfoVO.empty()
    : userId = 0,
      nickname = '',
      avatarUrl = '',
      type = '',
      profileId = null;

  final int userId;
  final String nickname;
  final String avatarUrl;
  final String type;
  final int? profileId;

  factory ApplicantInfoVO.fromJson(JsonMap json) {
    return ApplicantInfoVO(
      userId: readInt(json, 'userId'),
      nickname: readString(json, 'nickname'),
      avatarUrl: readString(json, 'avatarUrl'),
      type: readString(json, 'type'),
      profileId: _readNullableInt(json['profileId']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'type': type,
      'profileId': profileId,
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
    required this.applicant,
    required this.rejectReason,
    required this.latestReject,
    required this.isUrgent,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentUrl,
    this.country = '',
  });

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
  final ApplicantInfoVO applicant;
  final String? rejectReason;
  final OrderRejectRecordVO? latestReject;
  final bool isUrgent;
  final String country;
  final String createdAt;
  final String updatedAt;
  final String? paymentUrl;

  int get userId => applicant.userId;
  String get nickname => applicant.nickname;
  String get avatarUrl => applicant.avatarUrl;
  String get applicantType => applicant.type;
  int? get applicantProfileId => applicant.profileId;

  int get contactTargetUserId {
    final String normalizedRole = applicant.type.trim().toLowerCase();
    if (normalizedRole == 'worker') {
      return applicant.userId;
    }
    if ((applicant.profileId ?? 0) > 0) {
      return applicant.profileId!;
    }
    return applicant.userId;
  }

  String get contactTargetUserRole {
    final String normalizedRole = applicant.type.trim();
    return normalizedRole.isEmpty ? 'worker' : normalizedRole;
  }

  factory VisaOrderVO.fromJson(JsonMap json) {
    final JsonMap providerInfoJson = readJsonMap(json, 'providerInfo');
    final JsonMap applicantJson = readJsonMap(json, 'applicant');
    return VisaOrderVO(
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
      packageInfo: PackageInfoVO.fromJson(readJsonMap(json, 'packageInfo')),
      providerInfo: providerInfoJson.isEmpty
          ? const ProviderInfoVO.empty()
          : ProviderInfoVO.fromJson(providerInfoJson),
      requiredMaterials: readModelList<RequiredMaterialVO>(
        json,
        'requiredMaterials',
        RequiredMaterialVO.fromJson,
      ),
      materials: readModelList<MaterialVO>(
        json,
        'materials',
        MaterialVO.fromJson,
      ),
      visaDocuments: readModelList<VisaDocVO>(
        json,
        'visaDocuments',
        VisaDocVO.fromJson,
      ),
      applicant: applicantJson.isEmpty
          ? ApplicantInfoVO(
              userId: readInt(json, 'userId'),
              nickname: readString(json, 'nickname'),
              avatarUrl: readString(json, 'avatarUrl'),
              type: _readNullableString(json['type']) ?? 'worker',
              profileId: _readNullableInt(json['profileId']),
            )
          : ApplicantInfoVO.fromJson(applicantJson),
      rejectReason: _readNullableString(json['rejectReason']),
      latestReject: _readNullableModel<OrderRejectRecordVO>(
        json['latestReject'],
        OrderRejectRecordVO.fromJson,
      ),
      isUrgent: readBool(json, 'isUrgent'),
      country: _readNullableString(json['country']) ?? '',
      createdAt: readString(json, 'createdAt'),
      updatedAt: readString(json, 'updatedAt'),
      paymentUrl: _readNullableString(json['paymentUrl']),
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
      'applicant': applicant.toJson(),
      'rejectReason': rejectReason,
      'latestReject': latestReject?.toJson(),
      'isUrgent': isUrgent,
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

T? _readNullableModel<T>(dynamic raw, T Function(JsonMap json) fromJson) {
  if (raw == null) {
    return null;
  }
  final JsonMap map = asJsonMap(raw);
  if (map.isEmpty) {
    return null;
  }
  return fromJson(map);
}

List<T>? _readNullableModelList<T>(
  dynamic raw,
  T Function(JsonMap json) fromJson,
) {
  if (raw == null) {
    return null;
  }
  return decodeModelList<T>(raw, fromJson);
}
