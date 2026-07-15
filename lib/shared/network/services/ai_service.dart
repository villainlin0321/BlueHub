import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:europepass/shared/network/sse_client.dart';
import 'package:europepass/shared/network/sse_models.dart';
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
    return _sseClient.connect(
      '/ai/chat',
      method: 'POST',
      data: request.toJson(),
    );
  }

  /// 获取指定 AI 会话的历史消息。
  ///
  /// `sessionId` 为会话主键，`limit` 用于控制单次返回条数。
  Future<List<AiMessageVO>> getChatHistory({
    required int sessionId,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{
      'session_id': sessionId,
      if (limit != null) 'limit': limit,
    };
    final response = await _apiClient.get<List<AiMessageVO>>(
      '/ai/chat/history',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) =>
          decodeModelList<AiMessageVO>(data, AiMessageVO.fromJson),
    );
    return response;
  }

  /// 获取当前角色下的 AI 会话列表。
  Future<List<AiSessionVO>> listSessions() async {
    final response = await _apiClient.get<List<AiSessionVO>>(
      '/ai/sessions',
      decode: (data) =>
          decodeModelList<AiSessionVO>(data, AiSessionVO.fromJson),
    );
    return response;
  }

  /// 重命名指定会话。
  Future<void> renameSession({required int id, required String title}) async {
    return _apiClient.putVoid(
      '/ai/sessions/$id/title',
      queryParameters: <String, dynamic>{'title': title},
    );
  }

  /// 软删除指定会话。
  Future<void> deleteSession({required int id}) async {
    return _apiClient.deleteVoid('/ai/sessions/$id');
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
