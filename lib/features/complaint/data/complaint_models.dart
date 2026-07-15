import 'package:easy_localization/easy_localization.dart';

import 'package:europepass/shared/network/api_decoders.dart';

enum ComplaintStatus {
  pending('pending', '投诉.待处理'),
  processing('processing', '投诉.处理中'),
  resolved('resolved', '投诉.已解决'),
  rejected('rejected', '投诉.已驳回');

  const ComplaintStatus(this.value, this.fallbackLabelKey);

  final String value;
  final String fallbackLabelKey;

  String get localizedFallbackLabel => fallbackLabelKey.tr();

  static ComplaintStatus? fromValue(String raw) {
    final String normalized = raw.trim().toLowerCase();
    for (final ComplaintStatus status in ComplaintStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    return null;
  }
}

class ComplaintListQuery {
  const ComplaintListQuery({this.page = 1, this.pageSize = 20});

  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintListQuery &&
            runtimeType == other.runtimeType &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(page, pageSize);
}

class CreateComplaintBO {
  const CreateComplaintBO({
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.content,
    this.attachmentFileIds = const <int>[],
  });

  final String targetType;
  final int targetId;
  final String title;
  final String content;
  final List<int> attachmentFileIds;

  factory CreateComplaintBO.fromJson(JsonMap json) {
    return CreateComplaintBO(
      targetType: readString(json, 'targetType'),
      targetId: readInt(json, 'targetId'),
      title: readString(json, 'title'),
      content: readString(json, 'content'),
      attachmentFileIds: readIntList(json, 'attachmentFileIds'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'targetType': targetType,
      'targetId': targetId,
      'title': title,
      'content': content,
      if (attachmentFileIds.isNotEmpty) 'attachmentFileIds': attachmentFileIds,
    };
  }
}

class ComplaintVO {
  const ComplaintVO({
    required this.complaintId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.title,
    required this.content,
    required this.attachmentUrls,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final int complaintId;
  final String targetType;
  final int targetId;
  final String targetName;
  final String title;
  final String content;
  final List<String> attachmentUrls;
  final String status;
  final String statusLabel;
  final String createdAt;
  final String updatedAt;

  ComplaintStatus? get statusEnum => ComplaintStatus.fromValue(status);
  String get displayStatusLabel => statusLabel.trim().isNotEmpty
      ? statusLabel.trim()
      : (statusEnum?.localizedFallbackLabel ?? status.trim());

  factory ComplaintVO.fromJson(JsonMap json) {
    return ComplaintVO(
      complaintId: readInt(json, 'complaintId'),
      targetType: readString(json, 'targetType'),
      targetId: readInt(json, 'targetId'),
      targetName: readString(json, 'targetName'),
      title: readString(json, 'title'),
      content: readString(json, 'content'),
      attachmentUrls: readStringList(json, 'attachmentUrls'),
      status: readString(json, 'status'),
      statusLabel: readString(json, 'statusLabel'),
      createdAt: readString(json, 'createdAt'),
      updatedAt: readString(json, 'updatedAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'complaintId': complaintId,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'title': title,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'status': status,
      'statusLabel': statusLabel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
