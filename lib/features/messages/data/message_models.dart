import 'package:europepass/shared/network/api_decoders.dart';

class ConversationVO {
  const ConversationVO({
    required this.conversationId,
    required this.targetUser,
    required this.relatedOrder,
    required this.lastMessage,
    required this.unreadCount,
  });

  final int conversationId;
  final TargetUserVO targetUser;
  final RelatedOrderVO? relatedOrder;
  final LastMessageVO lastMessage;
  final int unreadCount;

  factory ConversationVO.fromJson(JsonMap json) {
    return ConversationVO(
      conversationId: readInt(json, 'conversationId'),
      targetUser: TargetUserVO.fromJson(readJsonMap(json, 'targetUser')),
      // 0510 接口文档标注该字段可能为 null，需避免强解析导致列表页崩溃。
      relatedOrder: json['relatedOrder'] == null
          ? null
          : RelatedOrderVO.fromJson(readJsonMap(json, 'relatedOrder')),
      lastMessage: LastMessageVO.fromJson(readJsonMap(json, 'lastMessage')),
      unreadCount: readInt(json, 'unreadCount'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'conversationId': conversationId,
      'targetUser': targetUser.toJson(),
      'relatedOrder': relatedOrder?.toJson(),
      'lastMessage': lastMessage.toJson(),
      'unreadCount': unreadCount,
    };
  }

  ConversationVO copyWith({
    int? conversationId,
    TargetUserVO? targetUser,
    RelatedOrderVO? relatedOrder,
    LastMessageVO? lastMessage,
    int? unreadCount,
  }) {
    return ConversationVO(
      conversationId: conversationId ?? this.conversationId,
      targetUser: targetUser ?? this.targetUser,
      relatedOrder: relatedOrder ?? this.relatedOrder,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationVO {
  const NotificationVO({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.content,
    required this.bizType,
    required this.bizId,
    required this.isRead,
    required this.createdAt,
  });

  final int notificationId;
  final String type;
  final String title;
  final String content;
  final String bizType;
  final int bizId;
  final bool isRead;
  final String createdAt;

  factory NotificationVO.fromJson(JsonMap json) {
    return NotificationVO(
      notificationId: readInt(json, 'notificationId'),
      type: readString(json, 'type'),
      title: readString(json, 'title'),
      content: readString(json, 'content'),
      bizType: readString(json, 'bizType'),
      bizId: readInt(json, 'bizId'),
      isRead: readBool(json, 'isRead'),
      createdAt: readString(json, 'createdAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'notificationId': notificationId,
      'type': type,
      'title': title,
      'content': content,
      'bizType': bizType,
      'bizId': bizId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  NotificationVO copyWith({
    int? notificationId,
    String? type,
    String? title,
    String? content,
    String? bizType,
    int? bizId,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationVO(
      notificationId: notificationId ?? this.notificationId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      bizType: bizType ?? this.bizType,
      bizId: bizId ?? this.bizId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CreateConversationBO {
  const CreateConversationBO({
    required this.targetUserId,
    required this.targetUserRole,
    this.orderId,
  });

  final int targetUserId;
  final String targetUserRole;
  final int? orderId;

  /// 安全解析创建会话请求，兼容可选的关联订单 ID。
  factory CreateConversationBO.fromJson(JsonMap json) {
    return CreateConversationBO(
      targetUserId: readInt(json, 'targetUserId'),
      targetUserRole: readString(json, 'targetUserRole'),
      orderId: readInt(json, 'orderId'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'targetUserId': targetUserId,
      'targetUserRole': targetUserRole,
      if (orderId != null) 'orderId': orderId,
    };
  }
}

class LastMessageVO {
  const LastMessageVO({
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isRead,
  });

  final String content;
  final String type;
  final String sentAt;
  final bool isRead;

  factory LastMessageVO.fromJson(JsonMap json) {
    return LastMessageVO(
      content: readString(json, 'content'),
      type: readString(json, 'type'),
      sentAt: readString(json, 'sentAt'),
      isRead: readBool(json, 'isRead'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'content': content,
      'type': type,
      'sentAt': sentAt,
      'isRead': isRead,
    };
  }

  LastMessageVO copyWith({
    String? content,
    String? type,
    String? sentAt,
    bool? isRead,
  }) {
    return LastMessageVO(
      content: content ?? this.content,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class MessageVO {
  const MessageVO({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.isRead,
    required this.isRetracted,
    required this.sentAt,
  });

  final int messageId;
  final int? conversationId;
  final int senderId;
  final String type;
  final String content;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final int? duration;
  final bool isRead;
  final bool isRetracted;
  final String sentAt;

  factory MessageVO.fromJson(JsonMap json) {
    return MessageVO(
      messageId: readInt(json, 'messageId'),
      conversationId: _readNullableInt(json['conversationId']),
      senderId: readInt(json, 'senderId'),
      type: readString(json, 'type'),
      content: readString(json, 'content'),
      fileUrl: readString(json, 'fileUrl'),
      fileName: readString(json, 'fileName'),
      fileSize: readInt(json, 'fileSize'),
      duration: _readNullableInt(json['duration']),
      isRead: readBool(json, 'isRead'),
      isRetracted: readBool(json, 'isRetracted'),
      sentAt: readString(json, 'sentAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'type': type,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'isRead': isRead,
      'isRetracted': isRetracted,
      'sentAt': sentAt,
    };
  }
}

class RelatedOrderVO {
  const RelatedOrderVO({
    required this.orderId,
    required this.orderNo,
    required this.packageName,
    required this.status,
  });

  final int orderId;
  final String orderNo;
  final String packageName;
  final String status;

  factory RelatedOrderVO.fromJson(JsonMap json) {
    return RelatedOrderVO(
      orderId: readInt(json, 'orderId'),
      orderNo: readString(json, 'orderNo'),
      packageName: readString(json, 'packageName'),
      status: readString(json, 'status'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'orderNo': orderNo,
      'packageName': packageName,
      'status': status,
    };
  }

  RelatedOrderVO copyWith({
    int? orderId,
    String? orderNo,
    String? packageName,
    String? status,
  }) {
    return RelatedOrderVO(
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      packageName: packageName ?? this.packageName,
      status: status ?? this.status,
    );
  }
}

class SendMessageBO {
  const SendMessageBO({
    required this.type,
    this.content,
    this.fileId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.duration,
  });

  final String type;
  final String? content;
  final int? fileId;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration;

  factory SendMessageBO.fromJson(JsonMap json) {
    return SendMessageBO(
      type: readString(json, 'type'),
      content: _readNullableString(json['content']),
      fileId: _readNullableInt(json['fileId']),
      fileUrl: _readNullableString(json['fileUrl']),
      fileName: _readNullableString(json['fileName']),
      fileSize: _readNullableInt(json['fileSize']),
      duration: _readNullableInt(json['duration']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'type': type,
      if (content != null) 'content': content,
      if (fileId != null) 'fileId': fileId,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (duration != null) 'duration': duration,
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

class TargetUserVO {
  const TargetUserVO({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.role,
    required this.isOnline,
  });

  final int userId;
  final String nickname;
  final String avatarUrl;
  final String role;
  final bool isOnline;

  factory TargetUserVO.fromJson(JsonMap json) {
    return TargetUserVO(
      userId: readInt(json, 'userId'),
      nickname: readString(json, 'nickname'),
      avatarUrl: readString(json, 'avatarUrl'),
      role: readString(json, 'role'),
      isOnline: readBool(json, 'isOnline'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'role': role,
      'isOnline': isOnline,
    };
  }
}
