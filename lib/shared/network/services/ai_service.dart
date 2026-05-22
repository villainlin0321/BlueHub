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

  /// 建立 AI 对话的 SSE 流式连接。
  ///
  /// 服务端会通过事件流持续返回回复内容与中间状态。
  Stream<SseEvent> chat({required AiChatBO request}) {
    return _sseClient.connect('/ai/chat');
  }

  /// 获取指定 AI 会话的历史消息。
  ///
  /// `sessionId` 为会话主键，`limit` 用于控制单次返回条数。
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

  /// 获取岗位对应的 AI 人才推荐结果。
  ///
  /// `jobId` 为岗位主键，`limit` 用于控制推荐数量。
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
