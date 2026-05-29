import 'dart:async';

import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/network/sse_models.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../messages/data/message_models.dart';
import '../../messages/data/message_providers.dart';
import '../application/chat/chat_page_args.dart';
import '../application/chat/chat_page_controller.dart';
import '../application/chat/chat_page_state.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.args});

  final ChatPageArgs args;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const Color _pageBackground = Color(0xFFF5F7FA);
  static const Color _titleColor = Color(0xFF171A1D);
  static const Color _subtleTextColor = Color(0xFF8C8C8C);
  static const Color _brandBlue = Color(0xFF2781FF);
  static const Color _onlineGreen = Color(0xFF64BF3F);
  static const double _chatContentMaxWidth = 720;
  static const String _backAsset = 'assets/images/chat_page_back.svg';
  static const String _fileAsset = 'assets/images/chat_page_file.svg';
  static const String _orderArrowAsset =
      'assets/images/chat_page_order_arrow.svg';
  static const String _voiceAsset = 'assets/images/chat_page_voice.svg';
  static const String _addAsset = 'assets/images/chat_page_add.svg';

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ChatBottomPanelContainerController<_ChatPanelType>
  _bottomPanelController = ChatBottomPanelContainerController<_ChatPanelType>();
  StreamSubscription<SseEvent>? _sseSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatPageControllerProvider(widget.args).notifier)
          .loadInitialData();
      _subscribeRealtimeStream();
    });
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    unawaited(ref.read(messageServiceProvider).closeConversationStream());
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      ref
          .read(chatPageControllerProvider(widget.args).notifier)
          .loadMoreMessages();
    }
  }

  void _subscribeRealtimeStream() {
    _sseSubscription?.cancel();
    _sseSubscription = ref
        .read(messageServiceProvider)
        .connectConversationStream()
        .listen((SseEvent event) {
          ref
              .read(chatPageControllerProvider(widget.args).notifier)
              .handleSseEvent(event);
        }, onError: (_) {});
  }

  Future<void> _handleFileAction() async {
    if (_bottomPanelController.currentPanelType == ChatBottomPanelType.other &&
        _bottomPanelController.data == _ChatPanelType.attachment) {
      _hideBottomPanel();
      return;
    }
    _bottomPanelController.updatePanelType(
      ChatBottomPanelType.other,
      data: _ChatPanelType.attachment,
    );
  }

  void _hideBottomPanel() {
    _inputFocusNode.unfocus();
    if (_bottomPanelController.currentPanelType == ChatBottomPanelType.none) {
      return;
    }
    _bottomPanelController.updatePanelType(ChatBottomPanelType.none);
  }

  Future<void> _handleCameraPick() async {
    await _pickAndSendFiles(
      picker: UploadPickerUtils.pickFromCamera,
      errorMessage: '打开相机失败，请稍后重试',
      emptyMessage: null,
    );
  }

  Future<void> _handleGalleryPick() async {
    await _pickAndSendFiles(
      picker: UploadPickerUtils.pickFromGallery,
      errorMessage: '打开相册失败，请稍后重试',
      emptyMessage: null,
    );
  }

  Future<void> _handleLocalFilePick() async {
    await _pickAndSendFiles(
      picker: UploadPickerUtils.pickFromFiles,
      errorMessage: '选择文件失败，请稍后重试',
      emptyMessage: '未能读取所选文件',
    );
  }

  Future<void> _pickAndSendFiles({
    required Future<List<PickedUploadFile>> Function() picker,
    required String errorMessage,
    required String? emptyMessage,
  }) async {
    try {
      final List<PickedUploadFile> pickedFiles = await picker();
      if (!mounted) {
        return;
      }
      if (pickedFiles.isEmpty) {
        if (emptyMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(emptyMessage)));
        }
        return;
      }

      final controller = ref.read(
        chatPageControllerProvider(widget.args).notifier,
      );
      await controller.sendPickedFiles(pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }
  }

  void _handleVoiceTap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('语音消息功能开发中')));
  }

  void _handleOrderCardTap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('订单详情功能开发中')));
  }

  Future<void> _handleFileMessageTap(MessageVO message) async {
    final String label = message.type == 'image' ? '图片预览功能开发中' : '文件预览功能开发中';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _scrollToLatest({required bool animated}) async {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final ChatPageState state = ref.watch(
      chatPageControllerProvider(widget.args),
    );
    final chatController = ref.read(
      chatPageControllerProvider(widget.args).notifier,
    );
    final authUser = ref.watch(authSessionProvider).user;

    ref.listen<ChatPageState>(chatPageControllerProvider(widget.args), (
      previous,
      next,
    ) {
      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.feedbackMessage!)));
        chatController.clearFeedback();
      }

      if (previous?.clearComposerToken != next.clearComposerToken) {
        _inputController.clear();
      }

      if (previous?.newestMessageToken != next.newestMessageToken) {
        final bool animated = previous != null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLatest(animated: animated);
        });
      }
    });

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: false,
      appBar: _ChatPageAppBar(
        args: widget.args,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double contentWidth = constraints.maxWidth.clamp(
            0,
            _chatContentMaxWidth,
          );
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: <Widget>[
                  if (_shouldShowOrderCard(widget.args))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _OrderSummaryCard(
                        packageName: widget.args.packageName,
                        orderStatus: _resolveOrderStatusLabel(
                          widget.args.orderStatus,
                        ),
                        onTap: _handleOrderCardTap,
                      ),
                    ),
                  if (_shouldShowOrderCard(widget.args))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '对方已接收您的签证申请，现在可以开始沟通了',
                        style: const TextStyle(
                          color: _subtleTextColor,
                          fontSize: 11,
                          height: 18 / 11,
                        ),
                      ),
                    ),
                  if (state.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        _formatChatDateTime(state.messages.last.sentAt),
                        style: const TextStyle(
                          color: _subtleTextColor,
                          fontSize: 11,
                          height: 14 / 11,
                        ),
                      ),
                    ),
                  Expanded(
                    child: state.isInitialLoading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : state.loadErrorMessage != null
                        ? _ChatLoadError(
                            message: state.loadErrorMessage!,
                            onRetry: chatController.retry,
                          )
                        : _ChatMessageList(
                            messages: state.messages,
                            currentUserId: authUser?.userId ?? 0,
                            targetNickname: widget.args.nickname,
                            targetAvatarUrl: widget.args.avatarUrl,
                            currentUserNickname: authUser?.nickname ?? '我',
                            currentUserAvatarUrl: authUser?.avatarUrl ?? '',
                            scrollController: _scrollController,
                            isLoadingMore: state.isLoadingMore,
                            onTapFileMessage: _handleFileMessageTap,
                          ),
                  ),
                  _ChatComposer(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    isSending: state.isSending,
                    onVoiceTap: _handleVoiceTap,
                    onFileTap: _handleFileAction,
                    onSend: () =>
                        chatController.sendTextMessage(_inputController.text),
                  ),
                  ChatBottomPanelContainer<_ChatPanelType>(
                    controller: _bottomPanelController,
                    inputFocusNode: _inputFocusNode,
                    panelBgColor: Colors.transparent,
                    safeAreaBottom: 0,
                    otherPanelWidget: (_ChatPanelType? type) {
                      switch (type) {
                        case _ChatPanelType.attachment:
                          return _ChatAttachmentPanel(
                            onClose: _hideBottomPanel,
                            onCameraTap: _handleCameraPick,
                            onGalleryTap: _handleGalleryPick,
                            onFileTap: _handleLocalFilePick,
                          );
                        case null:
                          return const SizedBox(height: 20);
                      }
                    },
                  ),
                  Container(height: 20, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _ChatPanelType { attachment }

class _ChatPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatPageAppBar({required this.args, required this.onBack});

  final ChatPageArgs args;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 44,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: onBack,
        padding: EdgeInsets.zero,
        icon: SvgPicture.asset(
          _ChatPageState._backAsset,
          width: 12,
          height: 24,
        ),
      ),
      titleSpacing: 0,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${args.nickname}（${_resolveRoleLabel(args.targetUserRole)}）',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: args.isOnline
                        ? _ChatPageState._onlineGreen
                        : const Color(0xFFBFBFBF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  args.isOnline ? '在线' : '离线',
                  style: TextStyle(
                    color: args.isOnline
                        ? _ChatPageState._onlineGreen
                        : const Color(0xFFBFBFBF),
                    fontSize: 10,
                    height: 14 / 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  3,
                  (_) => Container(
                    width: 3,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: const BoxDecoration(
                      color: _ChatPageState._titleColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.packageName,
    required this.orderStatus,
    required this.onTap,
  });

  final String packageName;
  final String orderStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                _ChatPageState._fileAsset,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ChatPageState._titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '订单状态：$orderStatus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ChatPageState._subtleTextColor,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SvgPicture.asset(
                _ChatPageState._orderArrowAsset,
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  const _ChatLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ChatPageState._subtleTextColor,
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.messages,
    required this.currentUserId,
    required this.targetNickname,
    required this.targetAvatarUrl,
    required this.currentUserNickname,
    required this.currentUserAvatarUrl,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onTapFileMessage,
  });

  final List<MessageVO> messages;
  final int currentUserId;
  final String targetNickname;
  final String targetAvatarUrl;
  final String currentUserNickname;
  final String currentUserAvatarUrl;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final Future<void> Function(MessageVO message) onTapFileMessage;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          '暂无聊天记录',
          style: TextStyle(
            color: _ChatPageState._subtleTextColor,
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (BuildContext context, int index) {
              final MessageVO message = messages[index];
              if (message.type == 'system') {
                return _ChatSystemMessage(text: message.content);
              }

              final bool isMine =
                  currentUserId > 0 && message.senderId == currentUserId;
              return _ChatMessageRow(
                message: message,
                isMine: isMine,
                avatarUrl: isMine ? currentUserAvatarUrl : targetAvatarUrl,
                fallbackName: isMine ? currentUserNickname : targetNickname,
                onTapFileMessage: onTapFileMessage,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  const _ChatMessageRow({
    required this.message,
    required this.isMine,
    required this.avatarUrl,
    required this.fallbackName,
    required this.onTapFileMessage,
  });

  final MessageVO message;
  final bool isMine;
  final String avatarUrl;
  final String fallbackName;
  final Future<void> Function(MessageVO message) onTapFileMessage;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = AppUserAvatar(
      imageUrl: avatarUrl,
      size: 40,
      backgroundColor: isMine
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF487BFE),
      placeholder: Center(
        child: Text(
          _buildAvatarFallbackText(fallbackName),
          style: TextStyle(
            color: isMine ? const Color(0xFF171A1D) : Colors.white,
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: <Widget>[
        if (!isMine) avatar,
        if (!isMine) const SizedBox(width: 12),
        Flexible(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.74,
                ),
                child: _ChatBubble(
                  message: message,
                  isMine: isMine,
                  onTapFileMessage: onTapFileMessage,
                ),
              );
            },
          ),
        ),
        if (isMine) const SizedBox(width: 12),
        if (isMine) avatar,
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.onTapFileMessage,
  });

  final MessageVO message;
  final bool isMine;
  final Future<void> Function(MessageVO message) onTapFileMessage;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isMine
        ? _ChatPageState._brandBlue
        : Colors.white;
    final Color foregroundColor = isMine
        ? Colors.white
        : _ChatPageState._titleColor;
    final BorderRadius borderRadius = BorderRadius.circular(12);

    if (message.type == 'image') {
      return InkWell(
        borderRadius: borderRadius,
        onTap: () => onTapFileMessage(message),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            color: backgroundColor,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                message.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: backgroundColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '[图片加载失败]',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (message.type == 'file') {
      return InkWell(
        borderRadius: borderRadius,
        onTap: () => onTapFileMessage(message),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.asset(
                _ChatPageState._fileAsset,
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.fileName.isEmpty ? '文件消息' : message.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        message.isRetracted ? '[消息已撤回]' : message.content,
        style: TextStyle(color: foregroundColor, fontSize: 15, height: 22 / 15),
      ),
    );
  }
}

class _ChatSystemMessage extends StatelessWidget {
  const _ChatSystemMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ChatPageState._subtleTextColor,
            fontSize: 11,
            height: 18 / 11,
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onVoiceTap,
    required this.onFileTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onVoiceTap;
  final Future<void> Function() onFileTap;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(
                width: 24,
                height: 24,
                child: InkWell(
                  onTap: isSending ? null : onVoiceTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: SvgPicture.asset(
                      _ChatPageState._voiceAsset,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !isSending,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.multiline,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    hintText: '发消息...',
                    hintStyle: TextStyle(
                      color: _ChatPageState._subtleTextColor,
                      fontSize: 15,
                      height: 22 / 15,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: _ChatPageState._titleColor,
                    fontSize: 15,
                    height: 22 / 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder:
                    (
                      BuildContext context,
                      TextEditingValue value,
                      Widget? child,
                    ) {
                      final bool hasText = value.text.trim().isNotEmpty;
                      if (hasText) {
                        return InkWell(
                          onTap: isSending ? null : onSend,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '发送',
                              style: TextStyle(
                                color: isSending
                                    ? const Color(0xFFBFBFBF)
                                    : _ChatPageState._brandBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 24 / 15,
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        width: 24,
                        height: 24,
                        child: InkWell(
                          onTap: isSending ? null : onFileTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: SvgPicture.asset(
                              _ChatPageState._addAsset,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAttachmentPanel extends StatelessWidget {
  const _ChatAttachmentPanel({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
  });

  final VoidCallback onClose;
  final Future<void> Function() onCameraTap;
  final Future<void> Function() onGalleryTap;
  final Future<void> Function() onFileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SizedBox(
        height: 86,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36.75, 0, 36.75, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _ChatAttachmentAction(
                        label: '拍照上传',
                        iconAssetPath:
                            'assets/images/order_upload_sheet_camera.svg',
                        onTap: onCameraTap,
                      ),
                      _ChatAttachmentAction(
                        label: '本地相册',
                        iconAssetPath:
                            'assets/images/order_upload_sheet_gallery.svg',
                        onTap: onGalleryTap,
                      ),
                      _ChatAttachmentAction(
                        label: '本地文件',
                        iconAssetPath:
                            'assets/images/order_upload_sheet_file.svg',
                        onTap: onFileTap,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatAttachmentAction extends StatelessWidget {
  const _ChatAttachmentAction({
    required this.label,
    required this.iconAssetPath,
    required this.onTap,
  });

  final String label;
  final String iconAssetPath;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAssetPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF595959),
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 18 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _shouldShowOrderCard(ChatPageArgs args) {
  return args.packageName.trim().isNotEmpty ||
      args.orderStatus.trim().isNotEmpty;
}

String _resolveRoleLabel(String role) {
  switch (role.trim()) {
    case 'worker':
      return '求职者';
    case 'employer':
      return '企业';
    case 'visa_provider':
      return '服务商';
    default:
      return '客户';
  }
}

String _resolveOrderStatusLabel(String status) {
  final String trimmed = status.trim();
  if (trimmed.isEmpty) {
    return '处理中';
  }
  switch (trimmed) {
    case 'pending_material':
      return '待审核材料';
    case 'pending_pay':
      return '待支付';
    case 'processing':
      return '办理中';
    case 'completed':
      return '已完成';
    default:
      return trimmed;
  }
}

String _formatChatDateTime(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) {
    return raw;
  }
  return '${_twoDigits(parsed.month)}-${_twoDigits(parsed.day)} '
      '${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}:${_twoDigits(parsed.second)}';
}

String _buildAvatarFallbackText(String nickname) {
  final String compact = nickname.trim().replaceAll(' ', '');
  if (compact.isEmpty) {
    return '用户';
  }
  final bool isAsciiWord = compact.codeUnits.every((int codeUnit) {
    return (codeUnit >= 48 && codeUnit <= 57) ||
        (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  });
  if (isAsciiWord) {
    return compact
        .substring(0, compact.length >= 2 ? 2 : compact.length)
        .toUpperCase();
  }
  return String.fromCharCodes(compact.runes.take(2));
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
