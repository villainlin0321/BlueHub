import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import 'package:bluehub_app/shared/network/sse_client.dart';
import 'package:bluehub_app/shared/network/sse_models.dart';
import '../../../features/messages/data/message_models.dart';

class MessageService {
  MessageService({required ApiClient apiClient, required SseClient sseClient})
    : _apiClient = apiClient,
      _sseClient = sseClient;

  final ApiClient _apiClient;
  final SseClient _sseClient;

  Future<PageResult<ConversationVO>> listConversations({
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<ConversationVO>>(
      '/conversations',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<ConversationVO>.fromJson(
        asJsonMap(data),
        fromJson: ConversationVO.fromJson,
      ),
    );
    return response;
  }

  Future<Map<String, dynamic>> createConversation({
    required CreateConversationBO request,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/conversations',
      data: request.toJson(),
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  Future<Map<String, dynamic>> listMessagesByTarget({
    required int targetUserId,
    required String targetRole,
    int? beforeId,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{
      'target_user_id': targetUserId,
      'target_role': targetRole,
      if (beforeId != null) 'before_id': beforeId,
      if (limit != null) 'limit': limit,
    };
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/messages',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  Stream<SseEvent> connectConversationStream() {
    return _sseClient.connect('/conversations/sse');
  }

  Future<void> closeConversationStream() async {
    return _apiClient.getVoid('/conversations/sse/close');
  }

  Future<Map<String, int>> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, int>>(
      '/conversations/unread-count',
      decode: (data) => decodeMapValues<int>(
        data ?? const <String, dynamic>{},
        (value) => (value as num?)?.toInt() ?? 0,
      ),
    );
    return response;
  }

  Future<Map<String, dynamic>> listMessages({
    required int conversationId,
    int? beforeId,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{
      if (beforeId != null) 'before_id': beforeId,
      if (limit != null) 'limit': limit,
    };
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

  Future<MessageVO> sendMessage({
    required int conversationId,
    required SendMessageBO request,
  }) async {
    final response = await _apiClient.post<MessageVO>(
      '/conversations/$conversationId/messages',
      data: request.toJson(),
      decode: (data) => MessageVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> markRead({required int conversationId}) async {
    return _apiClient.putVoid('/conversations/$conversationId/read');
  }
}
