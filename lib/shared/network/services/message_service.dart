import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import 'package:bluehub_app/shared/network/sse_client.dart';
import 'package:bluehub_app/shared/network/sse_models.dart';
import '../../logging/app_logger.dart';
import '../../../features/messages/data/message_models.dart';

/// 消息模块网络服务。
///
/// 统一封装会话列表、消息列表、发送消息、已读同步以及 SSE 实时订阅能力，
/// 供消息中心、会话详情和发起聊天等场景复用。
class MessageService {
  MessageService({required ApiClient apiClient, required SseClient sseClient})
    : _apiClient = apiClient,
      _sseClient = sseClient;

  final ApiClient _apiClient;
  final SseClient _sseClient;

  /// 获取当前登录用户的会话分页列表。
  ///
  /// - [page] 为页码，从 1 开始；
  /// - [pageSize] 为单页条数；
  /// - 返回值包含会话列表和分页信息，可直接用于消息中心“聊天”列表渲染。
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

  /// 创建一个新的聊天会话。
  ///
  /// 通常用于在岗位详情、服务详情等页面点击“立即沟通”时发起会话。
  /// [request] 中包含目标用户、目标角色以及可选的关联订单信息。
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

  /// 按目标用户查询或拉起对应会话的历史消息。
  ///
  /// 适用于“尚未拿到 conversationId，但已知目标用户和角色”的场景。
  /// [beforeId] 用于向上翻页加载更早消息；
  /// [limit] 控制单次返回的消息条数。
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

  /// 建立会话实时消息 SSE 连接。
  ///
  /// 订阅后可持续接收新消息、已读回执等服务端推送事件。
  Stream<SseEvent> connectConversationStream() {
    return _sseClient.connect('/conversations/sse').map((event) {
      AppLogger.instance.info(
        'MESSAGE_SSE',
        '收到会话 SSE 消息',
        context: <String, Object?>{
          'id': event.id,
          'event': event.event,
          'retry': event.retry,
          'data': event.data,
        },
      );
      return event;
    });
  }

  /// 主动关闭会话 SSE 长连接。
  ///
  /// 页面销毁、切换账号或需要重建订阅时调用，避免服务端保留无效连接。
  Future<void> closeConversationStream() async {
    return _apiClient.getVoid('/conversations/sse/close');
  }

  /// 获取当前用户所有会话的未读统计。
  ///
  /// 返回值通常包含不同维度的未读数量，可用于顶部红点或消息入口角标展示。
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

  /// 根据会话 ID 拉取消息列表。
  ///
  /// [conversationId] 为目标会话主键；
  /// [beforeId] 传入后返回该消息之前的更早记录；
  /// [limit] 控制单次拉取条数，适合聊天详情页做分页加载。
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

  /// 向指定会话发送消息。
  ///
  /// [conversationId] 为目标会话主键；
  /// [request] 支持 `text / image / file / audio / system` 等不同类型消息体，
  /// 其中发送语音时由调用方额外提供 `fileId / fileUrl / fileName / fileSize / duration`。
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

  /// 将指定会话标记为已读。
  ///
  /// 常用于进入聊天详情页或在消息中心点击某条会话后同步未读状态。
  Future<void> markRead({required int conversationId}) async {
    return _apiClient.putVoid('/conversations/$conversationId/read');
  }
}
