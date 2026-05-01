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
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      targetUser: TargetUserVO.fromJson(
        asJsonMap(json['targetUser'] ?? const <String, dynamic>{}),
      ),
      relatedOrder: RelatedOrderVO.fromJson(
        asJsonMap(json['relatedOrder'] ?? const <String, dynamic>{}),
      ),
      lastMessage: LastMessageVO.fromJson(
        asJsonMap(json['lastMessage'] ?? const <String, dynamic>{}),
      ),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
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
    required this.orderId,
  });

  final int targetUserId;
  final String targetUserRole;
  final int orderId;

  factory CreateConversationBO.fromJson(JsonMap json) {
    return CreateConversationBO(
      targetUserId: (json['targetUserId'] as num?)?.toInt() ?? 0,
      targetUserRole: json['targetUserRole'] as String? ?? '',
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'targetUserId': targetUserId,
      'targetUserRole': targetUserRole,
      'orderId': orderId,
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
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? '',
      sentAt: json['sentAt'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
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
      messageId: (json['messageId'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      senderId: (json['senderId'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      isRetracted: json['isRetracted'] as bool? ?? false,
      sentAt: json['sentAt'] as String? ?? '',
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
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      status: json['status'] as String? ?? '',
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
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
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
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
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
