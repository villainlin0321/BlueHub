import 'package:bluehub_app/shared/network/api_decoders.dart';

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
  final RelatedOrderVO relatedOrder;
  final LastMessageVO lastMessage;
  final int unreadCount;

  factory ConversationVO.fromJson(JsonMap json) {
    return ConversationVO(
      conversationId: readInt(json, 'conversationId'),
      targetUser: TargetUserVO.fromJson(
        readJsonMap(json, 'targetUser'),
      ),
      relatedOrder: RelatedOrderVO.fromJson(
        readJsonMap(json, 'relatedOrder'),
      ),
      lastMessage: LastMessageVO.fromJson(
        readJsonMap(json, 'lastMessage'),
      ),
      unreadCount: readInt(json, 'unreadCount'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'conversationId': conversationId,
      'targetUser': targetUser.toJson(),
      'relatedOrder': relatedOrder.toJson(),
      'lastMessage': lastMessage.toJson(),
      'unreadCount': unreadCount,
    };
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
    required this.isRead,
    required this.isRetracted,
    required this.sentAt,
  });

  final int messageId;
  final int conversationId;
  final int senderId;
  final String type;
  final String content;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final bool isRead;
  final bool isRetracted;
  final String sentAt;

  factory MessageVO.fromJson(JsonMap json) {
    return MessageVO(
      messageId: readInt(json, 'messageId'),
      conversationId: readInt(json, 'conversationId'),
      senderId: readInt(json, 'senderId'),
      type: readString(json, 'type'),
      content: readString(json, 'content'),
      fileUrl: readString(json, 'fileUrl'),
      fileName: readString(json, 'fileName'),
      fileSize: readInt(json, 'fileSize'),
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
}

class SendMessageBO {
  const SendMessageBO({
    required this.type,
    required this.content,
    required this.fileId,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
  });

  final String type;
  final String content;
  final int fileId;
  final String fileUrl;
  final String fileName;
  final int fileSize;

  factory SendMessageBO.fromJson(JsonMap json) {
    return SendMessageBO(
      type: readString(json, 'type'),
      content: readString(json, 'content'),
      fileId: readInt(json, 'fileId'),
      fileUrl: readString(json, 'fileUrl'),
      fileName: readString(json, 'fileName'),
      fileSize: readInt(json, 'fileSize'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'type': type,
      'content': content,
      'fileId': fileId,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }
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
