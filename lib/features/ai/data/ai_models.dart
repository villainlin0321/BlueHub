import 'package:bluehub_app/shared/network/api_decoders.dart';

class AiChatBO {
  const AiChatBO({
    this.sessionId,
    required this.message,
    this.contextType = 'general',
    this.language,
  });

  final int? sessionId;
  final String message;
  final String contextType;
  final String? language;

  factory AiChatBO.fromJson(JsonMap json) {
    return AiChatBO(
      sessionId: _readNullableInt(json['sessionId']),
      message: readString(json, 'message'),
      contextType: readString(json, 'contextType', fallback: 'general'),
      language: _readNullableString(json['language']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      if (sessionId != null) 'sessionId': sessionId,
      'message': message,
      'contextType': contextType,
      if (language != null && language!.trim().isNotEmpty) 'language': language,
    };
  }
}

class AiSessionVO {
  const AiSessionVO({
    required this.sessionId,
    required this.title,
    required this.role,
    required this.contextType,
    required this.createdAt,
    required this.updatedAt,
  });

  final int sessionId;
  final String title;
  final String role;
  final String contextType;
  final String createdAt;
  final String updatedAt;

  factory AiSessionVO.fromJson(JsonMap json) {
    return AiSessionVO(
      sessionId: readInt(json, 'sessionId'),
      title: readString(json, 'title'),
      role: readString(json, 'role'),
      contextType: readString(json, 'contextType'),
      createdAt: readString(json, 'createdAt'),
      updatedAt: readString(json, 'updatedAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'title': title,
      'role': role,
      'contextType': contextType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class AiCardEvent {
  const AiCardEvent({required this.type, required this.items});

  final String type;
  final List<JsonMap> items;

  factory AiCardEvent.fromJson(JsonMap json) {
    return AiCardEvent(
      type: readString(json, 'type'),
      items: asJsonMapList(json['items']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'type': type, 'items': items};
  }
}

class AiMessageVO {
  const AiMessageVO({
    required this.aiMsgId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.cards,
    required this.tokensUsed,
    required this.createdAt,
  });

  final int aiMsgId;
  final int sessionId;
  final String role;
  final String content;
  final List<AiCardEvent> cards;
  final int? tokensUsed;
  final String createdAt;

  factory AiMessageVO.fromJson(JsonMap json) {
    return AiMessageVO(
      aiMsgId: readInt(json, 'aiMsgId'),
      sessionId: readInt(json, 'sessionId'),
      role: readString(json, 'role'),
      content: readString(json, 'content'),
      cards: readModelList<AiCardEvent>(json, 'cards', AiCardEvent.fromJson),
      tokensUsed: _readNullableInt(json['tokensUsed']),
      createdAt: readString(json, 'createdAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'aiMsgId': aiMsgId,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'cards': cards.map((AiCardEvent item) => item.toJson()).toList(),
      'tokensUsed': tokensUsed,
      'createdAt': createdAt,
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
  if (value == null) {
    return null;
  }
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
