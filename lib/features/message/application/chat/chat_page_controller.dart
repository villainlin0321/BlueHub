import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/application/auth_session_provider.dart';
import '../../../../features/files/data/file_models.dart';
import '../../../../features/files/data/file_providers.dart';
import '../../../../shared/network/api_decoders.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/services/file_service.dart';
import '../../../../shared/network/services/message_service.dart';
import '../../../../shared/network/sse_models.dart';
import '../../../../utils/upload_picker_utils.dart';
import '../../../messages/data/message_models.dart';
import '../../../messages/data/message_providers.dart';
import 'chat_page_args.dart';
import 'chat_page_state.dart';

final chatPageControllerProvider =
    NotifierProvider.autoDispose.family<
      ChatPageController,
      ChatPageState,
      ChatPageArgs
    >(
      ChatPageController.new,
    );

class ChatPageController extends Notifier<ChatPageState> {
  static const int _pageSize = 50;

  ChatPageController(this.arg);

  final ChatPageArgs arg;
  late final MessageService _messageService;
  late final FileService _fileService;
  late final int _currentUserId;
  bool _isDisposed = false;
  int _nextTemporaryMessageId = -1;

  @override
  ChatPageState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
    _messageService = ref.read(messageServiceProvider);
    _fileService = ref.read(fileServiceProvider);
    _currentUserId = ref.read(authSessionProvider).user?.userId ?? 0;
    return ChatPageState(conversationId: arg.conversationId);
  }

  Future<void> loadInitialData() async {
    _updateState(
      (ChatPageState current) => current.copyWith(
        isInitialLoading: true,
        loadErrorMessage: null,
        feedbackMessage: null,
      ),
    );

    try {
      final _MessageHistoryPayload payload = await _loadHistory();
      _updateState(
        (ChatPageState current) => current.copyWith(
          conversationId: payload.conversationId,
          messages: payload.messages,
          hasMore: payload.hasMore,
          isInitialLoading: false,
          newestMessageToken: current.newestMessageToken + 1,
        ),
      );
      await _markCurrentConversationRead();
    } catch (error) {
      _updateState(
        (ChatPageState current) => current.copyWith(
          isInitialLoading: false,
          loadErrorMessage: _resolveErrorMessage(error),
        ),
      );
    }
  }

  Future<void> retry() => loadInitialData();

  Future<void> loadMoreMessages() async {
    if (state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.messages.isEmpty) {
      return;
    }

    final int beforeId = state.messages.last.messageId;
    _updateState(
      (ChatPageState current) => current.copyWith(isLoadingMore: true),
    );

    try {
      final _MessageHistoryPayload payload = await _loadHistory(
        beforeId: beforeId,
      );
      final List<MessageVO> merged = _mergeMessages(
        state.messages,
        payload.messages,
      );
      _updateState(
        (ChatPageState current) => current.copyWith(
          conversationId: payload.conversationId,
          messages: merged,
          hasMore: payload.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      _updateState(
        (ChatPageState current) => current.copyWith(
          isLoadingMore: false,
          feedbackMessage: _resolveErrorMessage(error),
          feedbackId: current.feedbackId + 1,
        ),
      );
    }
  }

  Future<void> sendTextMessage(String rawText) async {
    final String text = rawText.trim();
    if (text.isEmpty || state.isSending) {
      return;
    }

    _updateState(
      (ChatPageState current) => current.copyWith(
        isSending: true,
        feedbackMessage: null,
      ),
    );
    try {
      final int conversationId = await _ensureConversationId();
      final MessageVO message = await _messageService.sendMessage(
        conversationId: conversationId,
        request: SendMessageBO(
          type: 'text',
          content: text,
        ),
      );
      final List<MessageVO> merged = _mergeMessages(state.messages, <MessageVO>[
        message,
      ]);
      _updateState(
        (ChatPageState current) => current.copyWith(
          conversationId: conversationId,
          messages: merged,
          isSending: false,
          newestMessageToken: current.newestMessageToken + 1,
          clearComposerToken: current.clearComposerToken + 1,
        ),
      );
    } catch (error) {
      _updateState(
        (ChatPageState current) => current.copyWith(
          isSending: false,
          feedbackMessage: _resolveErrorMessage(error),
          feedbackId: current.feedbackId + 1,
        ),
      );
    }
  }

  Future<void> sendPickedFiles(List<PickedUploadFile> files) async {
    if (files.isEmpty) {
      return;
    }

    final List<PickedUploadFile> imageFiles = files
        .where((PickedUploadFile file) => file.isImage)
        .toList(growable: false);
    final List<PickedUploadFile> regularFiles = files
        .where((PickedUploadFile file) => !file.isImage)
        .toList(growable: false);

    if (imageFiles.isNotEmpty) {
      final List<MessageVO> temporaryMessages = imageFiles
          .map(_buildTemporaryImageMessage)
          .toList(growable: false);
      _updateState(
        (ChatPageState current) => current.copyWith(
          messages: _mergeMessages(current.messages, temporaryMessages),
          feedbackMessage: null,
          newestMessageToken: current.newestMessageToken + 1,
        ),
      );
      unawaited(_uploadTemporaryImages(imageFiles, temporaryMessages));
    }

    if (regularFiles.isNotEmpty) {
      await _sendRegularFiles(regularFiles);
    }
  }

  Future<void> _uploadTemporaryImages(
    List<PickedUploadFile> files,
    List<MessageVO> temporaryMessages,
  ) async {
    try {
      final int conversationId = await _ensureConversationId();
      for (int index = 0; index < files.length; index++) {
        final PickedUploadFile file = files[index];
        final MessageVO temporaryMessage = temporaryMessages[index];
        try {
          final FilePresignVO uploaded = await _fileService.uploadFile(
            path: file.path,
            scene: FileScene.chat,
            errorMessage: '上传.图片上传失败'.tr(),
          );
          final MessageVO response = await _messageService.sendMessage(
            conversationId: conversationId,
            request: SendMessageBO(
              type: 'image',
              fileId: uploaded.fileId,
              fileUrl: uploaded.fileUrl,
              fileName: file.name,
              fileSize: UploadPickerUtils.readFileSize(file.path),
            ),
          );
          _replaceTemporaryMessage(
            temporaryMessageId: temporaryMessage.messageId,
            message: response,
            conversationId: conversationId,
          );
        } catch (error) {
          _removeTemporaryMessage(
            temporaryMessageId: temporaryMessage.messageId,
            feedbackMessage: _resolveErrorMessage(error),
          );
        }
      }
    } catch (error) {
      final String feedbackMessage = _resolveErrorMessage(error);
      for (final MessageVO temporaryMessage in temporaryMessages) {
        _removeTemporaryMessage(
          temporaryMessageId: temporaryMessage.messageId,
          feedbackMessage: null,
        );
      }
      _updateState(
        (ChatPageState current) => current.copyWith(
          feedbackMessage: feedbackMessage,
          feedbackId: current.feedbackId + 1,
        ),
      );
    }
  }

  Future<void> _sendRegularFiles(List<PickedUploadFile> files) async {
    if (files.isEmpty || state.isSending) {
      return;
    }

    _updateState(
      (ChatPageState current) => current.copyWith(
        isSending: true,
        feedbackMessage: null,
      ),
    );

    try {
      final int conversationId = await _ensureConversationId();
      final List<MessageVO> sentMessages = <MessageVO>[];

      for (final PickedUploadFile file in files) {
        final FilePresignVO uploaded = await _fileService.uploadFile(
          path: file.path,
          scene: FileScene.chat,
          errorMessage: '消息.选择文件失败'.tr(),
        );
        final MessageVO response = await _messageService.sendMessage(
          conversationId: conversationId,
          request: SendMessageBO(
            type: 'file',
            content: file.name,
            fileId: uploaded.fileId,
            fileUrl: uploaded.fileUrl,
            fileName: file.name,
            fileSize: UploadPickerUtils.readFileSize(file.path),
          ),
        );
        sentMessages.add(response);
      }

      _updateState(
        (ChatPageState current) => current.copyWith(
          conversationId: conversationId,
          messages: _mergeMessages(current.messages, sentMessages),
          isSending: false,
          newestMessageToken: current.newestMessageToken + 1,
        ),
      );
    } catch (error) {
      _updateState(
        (ChatPageState current) => current.copyWith(
          isSending: false,
          feedbackMessage: _resolveErrorMessage(error),
          feedbackId: current.feedbackId + 1,
        ),
      );
    }
  }

  Future<void> markConversationRead() => _markCurrentConversationRead();

  void handleSseEvent(SseEvent event) {
    if (_isDisposed) {
      return;
    }
    if (!event.hasData) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(event.data);
      final JsonMap root = asJsonMap(decoded);
      JsonMap payload = asJsonMap(root['data']);
      if (payload.isEmpty) {
        payload = root;
      }
      if (payload.isEmpty) {
        return;
      }

      final JsonMap messageJson = _extractMessageJson(payload);
      if (messageJson.isEmpty || messageJson['messageId'] == null) {
        return;
      }

      final MessageVO message = MessageVO.fromJson(messageJson);
      if (!_isCurrentConversationMessage(message)) {
        return;
      }

      final int resolvedConversationId = message.conversationId > 0
          ? message.conversationId
          : state.conversationId;
      _updateState(
        (ChatPageState current) => current.copyWith(
          conversationId: resolvedConversationId,
          messages: _mergeMessages(current.messages, <MessageVO>[message]),
          newestMessageToken: current.newestMessageToken + 1,
        ),
      );
    } catch (_) {
      // 忽略不属于当前页面的数据格式，避免影响实时消息消费。
    }
  }

  void clearFeedback() {
    if (state.feedbackMessage == null) {
      return;
    }
    _updateState(
      (ChatPageState current) => current.copyWith(feedbackMessage: null),
    );
  }

  Future<_MessageHistoryPayload> _loadHistory({int? beforeId}) async {
    final Map<String, dynamic> raw;
    if (state.conversationId > 0) {
      raw = await _messageService.listMessages(
        conversationId: state.conversationId,
        beforeId: beforeId,
        limit: _pageSize,
      );
    } else {
      raw = await _messageService.listMessagesByTarget(
        targetUserId: arg.targetUserId,
        targetRole: arg.targetUserRole,
        beforeId: beforeId,
        limit: _pageSize,
      );
    }

    final List<MessageVO> messages = _extractMessages(raw);
    final int resolvedConversationId = _extractConversationId(
      raw,
      fallback: state.conversationId,
      messages: messages,
    );
    final bool hasMore = _extractHasMore(raw, messages.length);
    return _MessageHistoryPayload(
      conversationId: resolvedConversationId,
      messages: messages,
      hasMore: hasMore,
    );
  }

  Future<int> _ensureConversationId() async {
    if (state.conversationId > 0) {
      return state.conversationId;
    }

    final Map<String, dynamic> response = await _messageService
        .createConversation(
          request: CreateConversationBO(
            targetUserId: arg.targetUserId,
            targetUserRole: arg.targetUserRole,
            orderId: arg.relatedOrderId > 0 ? arg.relatedOrderId : null,
          ),
        );
    final int conversationId = _extractConversationId(
      response,
      fallback: state.conversationId,
    );
    if (conversationId <= 0) {
      throw ApiException.parse('conversationId missing');
    }
    _updateState(
      (ChatPageState current) =>
          current.copyWith(conversationId: conversationId),
    );
    return conversationId;
  }

  Future<void> _markCurrentConversationRead() async {
    if (_isDisposed) {
      return;
    }
    if (state.conversationId <= 0) {
      return;
    }
    try {
      await _messageService.markRead(conversationId: state.conversationId);
    } catch (_) {
      // 已读失败不阻断消息展示。
    }
  }

  List<MessageVO> _extractMessages(Map<String, dynamic> raw) {
    final List<MessageVO> directList = decodeModelList<MessageVO>(
      raw['list'],
      MessageVO.fromJson,
    );
    if (directList.isNotEmpty) {
      return _sortMessages(directList);
    }

    final List<MessageVO> messageList = decodeModelList<MessageVO>(
      raw['messages'],
      MessageVO.fromJson,
    );
    if (messageList.isNotEmpty) {
      return _sortMessages(messageList);
    }

    final List<MessageVO> recordList = decodeModelList<MessageVO>(
      raw['records'],
      MessageVO.fromJson,
    );
    if (recordList.isNotEmpty) {
      return _sortMessages(recordList);
    }

    final JsonMap conversation = asJsonMap(raw['conversation']);
    final List<MessageVO> nestedMessages = decodeModelList<MessageVO>(
      conversation['messages'],
      MessageVO.fromJson,
    );
    return _sortMessages(nestedMessages);
  }

  int _extractConversationId(
    Map<String, dynamic> raw, {
    required int fallback,
    List<MessageVO>? messages,
  }) {
    final int conversationId = readInt(raw, 'conversationId');
    if (conversationId > 0) {
      return conversationId;
    }

    final int snakeConversationId = readInt(raw, 'conversation_id');
    if (snakeConversationId > 0) {
      return snakeConversationId;
    }

    final JsonMap conversation = asJsonMap(raw['conversation']);
    final int nestedConversationId = readInt(conversation, 'conversationId');
    if (nestedConversationId > 0) {
      return nestedConversationId;
    }

    final JsonMap dataConversation = asJsonMap(raw['data']);
    final int dataConversationId = readInt(dataConversation, 'conversationId');
    if (dataConversationId > 0) {
      return dataConversationId;
    }

    final List<MessageVO> candidates = messages ?? const <MessageVO>[];
    for (final MessageVO message in candidates) {
      if (message.conversationId > 0) {
        return message.conversationId;
      }
    }

    return fallback;
  }

  bool _extractHasMore(Map<String, dynamic> raw, int loadedCount) {
    if (raw['hasMore'] is bool ||
        raw['hasMore'] is num ||
        raw['hasMore'] is String) {
      return readBool(raw, 'hasMore');
    }

    final JsonMap pagination = asJsonMap(raw['pagination']);
    if (pagination.isNotEmpty) {
      return readBool(pagination, 'has_next');
    }

    return loadedCount >= _pageSize;
  }

  List<MessageVO> _mergeMessages(
    List<MessageVO> current,
    List<MessageVO> incoming,
  ) {
    final Map<int, MessageVO> byId = <int, MessageVO>{};
    for (final MessageVO message in <MessageVO>[...current, ...incoming]) {
      byId[message.messageId] = message;
    }
    return _sortMessages(byId.values.toList(growable: false));
  }

  MessageVO _buildTemporaryImageMessage(PickedUploadFile file) {
    return MessageVO(
      messageId: _nextTemporaryMessageId--,
      conversationId: state.conversationId,
      senderId: _currentUserId,
      type: 'image',
      content: '',
      fileUrl: file.path,
      fileName: file.name,
      fileSize: UploadPickerUtils.readFileSize(file.path),
      isRead: true,
      isRetracted: false,
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  void _replaceTemporaryMessage({
    required int temporaryMessageId,
    required MessageVO message,
    required int conversationId,
  }) {
    _updateState((ChatPageState current) {
      final List<MessageVO> retained = current.messages
          .where((MessageVO item) => item.messageId != temporaryMessageId)
          .toList(growable: false);
      return current.copyWith(
        conversationId: conversationId,
        messages: _mergeMessages(retained, <MessageVO>[message]),
      );
    });
  }

  void _removeTemporaryMessage({
    required int temporaryMessageId,
    String? feedbackMessage,
  }) {
    _updateState((ChatPageState current) {
      final List<MessageVO> retained = current.messages
          .where((MessageVO item) => item.messageId != temporaryMessageId)
          .toList(growable: false);
      return current.copyWith(
        messages: retained,
        feedbackMessage: feedbackMessage ?? current.feedbackMessage,
        feedbackId: feedbackMessage == null
            ? current.feedbackId
            : current.feedbackId + 1,
      );
    });
  }

  List<MessageVO> _sortMessages(List<MessageVO> messages) {
    final List<MessageVO> sorted = List<MessageVO>.from(messages);
    sorted.sort((MessageVO left, MessageVO right) {
      final DateTime? leftTime = DateTime.tryParse(left.sentAt);
      final DateTime? rightTime = DateTime.tryParse(right.sentAt);
      if (leftTime != null && rightTime != null) {
        final int byTime = rightTime.compareTo(leftTime);
        if (byTime != 0) {
          return byTime;
        }
      }
      return right.messageId.compareTo(left.messageId);
    });
    return sorted;
  }

  JsonMap _extractMessageJson(JsonMap payload) {
    if (payload['messageId'] != null) {
      return payload;
    }

    final JsonMap message = asJsonMap(payload['message']);
    if (message.isNotEmpty) {
      return message;
    }

    return asJsonMap(payload['data']);
  }

  bool _isCurrentConversationMessage(MessageVO message) {
    if (state.conversationId > 0 && message.conversationId > 0) {
      return message.conversationId == state.conversationId;
    }

    return message.senderId == _currentUserId ||
        message.senderId == arg.targetUserId;
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '消息.消息加载失败'.tr();
  }

  void _updateState(ChatPageState Function(ChatPageState current) updater) {
    if (_isDisposed) {
      return;
    }
    state = updater(state);
  }
}

class _MessageHistoryPayload {
  const _MessageHistoryPayload({
    required this.conversationId,
    required this.messages,
    required this.hasMore,
  });

  final int conversationId;
  final List<MessageVO> messages;
  final bool hasMore;
}
