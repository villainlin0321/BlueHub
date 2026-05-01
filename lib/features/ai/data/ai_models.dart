import 'package:bluehub_app/shared/network/api_decoders.dart';

class AiChatBO {
  const AiChatBO({
    required this.sessionId,
    required this.message,
    required this.contextType,
  });

  final int sessionId;
  final String message;
  final String contextType;

  factory AiChatBO.fromJson(JsonMap json) {
    return AiChatBO(
      sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      contextType: json['contextType'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'message': message,
      'contextType': contextType,
    };
  }
}

class AiMessage {
  const AiMessage({
    required this.aiMsgId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.extraData,
    required this.tokensUsed,
    required this.createdAt,
  });

  final int aiMsgId;
  final int sessionId;
  final String role;
  final String content;
  final String extraData;
  final int tokensUsed;
  final String createdAt;

  factory AiMessage.fromJson(JsonMap json) {
    return AiMessage(
      aiMsgId: (json['aiMsgId'] as num?)?.toInt() ?? 0,
      sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
      extraData: json['extraData'] as String? ?? '',
      tokensUsed: (json['tokensUsed'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'aiMsgId': aiMsgId,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'extraData': extraData,
      'tokensUsed': tokensUsed,
      'createdAt': createdAt,
    };
  }
}
