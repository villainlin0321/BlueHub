import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/sse_client.dart';
import 'package:bluehub_app/shared/network/sse_models.dart';
import '../../../features/ai/data/ai_models.dart';

class AiService {
  AiService({required ApiClient apiClient, required SseClient sseClient})
    : _apiClient = apiClient,
      _sseClient = sseClient;

  final ApiClient _apiClient;
  final SseClient _sseClient;

  Stream<SseEvent> chat({required AiChatBO request}) {
    return _sseClient.connect('/ai/chat');
  }

  Future<List<AiMessage>> getChatHistory({
    required int sessionId,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{
      'session_id': sessionId,
      if (limit != null) 'limit': limit,
    };
    final response = await _apiClient.get<List<AiMessage>>(
      '/ai/chat/history',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => decodeModelList<AiMessage>(data, AiMessage.fromJson),
    );
    return response;
  }

  Future<dynamic> talentRecommend({required int jobId, int? limit}) async {
    final queryParameters = <String, dynamic>{
      'job_id': jobId,
      if (limit != null) 'limit': limit,
    };
    final response = await _apiClient.get<dynamic>(
      '/ai/talent-recommend',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => data,
    );
    return response;
  }
}
