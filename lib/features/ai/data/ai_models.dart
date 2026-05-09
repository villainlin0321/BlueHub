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
      sessionId: readInt(json, 'sessionId'),
      message: readString(json, 'message'),
      contextType: readString(json, 'contextType'),
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
      aiMsgId: readInt(json, 'aiMsgId'),
      sessionId: readInt(json, 'sessionId'),
      role: readString(json, 'role'),
      content: readString(json, 'content'),
      extraData: readString(json, 'extraData'),
      tokensUsed: readInt(json, 'tokensUsed'),
      createdAt: readString(json, 'createdAt'),
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
