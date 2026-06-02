import 'dart:io';
import 'dart:async';

import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../features/me/data/user_models.dart';
import '../../../features/me/data/user_providers.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../auth/application/auth_session_provider.dart';
import '../application/message_session/message_session_controller.dart';
import '../../messages/data/message_models.dart';
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
  static const String _keyboardAsset = 'assets/images/chat_page_keyboard.svg';
  static const String _addAsset = 'assets/images/chat_page_add.svg';

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ChatBottomPanelContainerController<_ChatPanelType>
  _bottomPanelController = ChatBottomPanelContainerController<_ChatPanelType>();
  final Dio _dio = Dio();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isBlockingUser = false;
  late final ChatPageController _chatController;
  StreamSubscription<PlayerState>? _audioPlayerStateSubscription;
  int _activeConversationId = 0;

  @override
  void initState() {
    super.initState();
    _chatController = ref.read(chatPageControllerProvider(widget.args).notifier);
    if (widget.args.conversationId > 0) {
      _activeConversationId = widget.args.conversationId;
      MessageSessionController.setActiveChatConversationId(
        widget.args.conversationId,
      );
    }
    _audioPlayerStateSubscription = _audioPlayer.playerStateStream.listen((
      PlayerState playerState,
    ) {
      if (!mounted) {
        return;
      }
      if (playerState.processingState == ProcessingState.completed) {
        _chatController.setPlayingMessageId(null);
        unawaited(_audioPlayer.seek(Duration.zero));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _chatController.loadInitialData();
    });
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    final int conversationId = _activeConversationId;
    if (conversationId > 0) {
      unawaited(_chatController.markConversationReadById(conversationId));
    }
    unawaited(_audioPlayer.stop());
    unawaited(_audioPlayer.dispose());
    _audioPlayerStateSubscription?.cancel();
    MessageSessionController.setActiveChatConversationId(0);
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
      _chatController.loadMoreMessages();
    }
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
      errorMessage: '消息.打开相机失败'.tr(),
      emptyMessage: null,
    );
  }

  Future<void> _handleGalleryPick() async {
    await _pickAndSendFiles(
      picker: UploadPickerUtils.pickFromGallery,
      errorMessage: '消息.打开相册失败'.tr(),
      emptyMessage: null,
    );
  }

  Future<void> _handleLocalFilePick() async {
    await _pickAndSendFiles(
      picker: UploadPickerUtils.pickFromFiles,
      errorMessage: '消息.选择文件失败'.tr(),
      emptyMessage: '消息.未能读取所选文件'.tr(),
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
    _chatController.toggleComposerMode();
    final ChatPageState state = ref.read(chatPageControllerProvider(widget.args));
    if (state.isVoiceMode) {
      _hideBottomPanel();
      _inputFocusNode.unfocus();
    }
  }

  void _handleOrderCardTap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('消息.订单详情开发中'.tr())));
  }

  Future<void> _handleFileMessageTap(MessageVO message) async {
    if (message.type == 'audio') {
      await _handleAudioMessageTap(message);
      return;
    }
    final String label = message.type == 'image'
        ? '消息.图片预览开发中'.tr()
        : '消息.文件预览开发中'.tr();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _handleVoiceRecordStart() async {
    if (ref.read(chatPageControllerProvider(widget.args)).isSending) {
      return;
    }
    final bool granted = await _chatController.hasMicrophonePermission();
    if (!granted) {
      final PermissionStatus status =
          await _chatController.requestMicrophonePermission();
      if (!mounted) {
        return;
      }
      if (!status.isGranted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('消息.麦克风权限说明'.tr())),
          );
        return;
      }
    }
    await _stopAudioPlayback();
    await _chatController.startVoiceRecording();
  }

  Future<void> _handleVoiceRecordEnd() async {
    await _chatController.finishVoiceRecordingAndSend();
  }

  void _handleVoiceRecordMove(LongPressMoveUpdateDetails details) {
    if (details.localPosition.dy < -50) {
      _chatController.cancelVoiceRecording();
      return;
    }
    _chatController.restoreVoiceRecording();
  }

  Future<void> _handleAudioMessageTap(MessageVO message) async {
    final ChatPageState currentState = ref.read(
      chatPageControllerProvider(widget.args),
    );
    if (currentState.downloadingAudioMessageIds.contains(message.messageId)) {
      return;
    }
    if (currentState.playingMessageId == message.messageId &&
        _audioPlayer.playing) {
      await _stopAudioPlayback();
      return;
    }

    try {
      await _stopAudioPlayback();
      final String audioPath = await _ensureAudioPlayablePath(message);
      await _audioPlayer.setFilePath(audioPath);
      _chatController.setPlayingMessageId(message.messageId);
      await _audioPlayer.play();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_resolveAudioPlaybackErrorMessage(error))),
        );
    }
  }

  Future<void> _stopAudioPlayback() async {
    try {
      await _audioPlayer.stop();
    } finally {
      _chatController.setPlayingMessageId(null);
    }
  }

  Future<String> _ensureAudioPlayablePath(MessageVO message) async {
    final String rawPath = message.fileUrl.trim();
    if (rawPath.isEmpty) {
      throw ApiException.parse('audio file url missing');
    }
    if (!_isRemoteFileUrl(rawPath)) {
      final File localFile = File(rawPath);
      if (await localFile.exists()) {
        return localFile.path;
      }
    }

    final Directory cacheDirectory = await _resolveAudioCacheDirectory();
    final String targetPath =
        '${cacheDirectory.path}/${message.messageId}${_resolveAudioCacheExtension(message)}';
    final File cachedFile = File(targetPath);
    if (await cachedFile.exists() && await cachedFile.length() > 0) {
      return cachedFile.path;
    }

    _chatController.setAudioDownloading(message.messageId, true);
    try {
      if (!_isRemoteFileUrl(rawPath)) {
        throw ApiException.parse('audio file unavailable');
      }
      await _dio.download(rawPath, targetPath);
      return targetPath;
    } catch (error) {
      if (await cachedFile.exists()) {
        await cachedFile.delete();
      }
      rethrow;
    } finally {
      _chatController.setAudioDownloading(message.messageId, false);
    }
  }

  Future<Directory> _resolveAudioCacheDirectory() async {
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final Directory cacheDirectory = Directory(
      '${temporaryDirectory.path}/chat_audio_cache',
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return cacheDirectory;
  }

  String _resolveAudioCacheExtension(MessageVO message) {
    final String fileName = message.fileName.trim();
    if (fileName.contains('.')) {
      return '.${fileName.split('.').last}';
    }
    final Uri? uri = Uri.tryParse(message.fileUrl.trim());
    if (uri != null && uri.path.contains('.')) {
      return '.${uri.path.split('.').last}';
    }
    return '.wav';
  }

  String _resolveAudioPlaybackErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '消息.语音播放失败'.tr();
  }

  Future<void> _showMoreMenu(BuildContext buttonContext) async {
    if (_isBlockingUser) {
      return;
    }

    final RenderBox button = buttonContext.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final _ChatMoreMenuAction? action = await showMenu<_ChatMoreMenuAction>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      menuPadding: EdgeInsets.zero,
      items: <PopupMenuEntry<_ChatMoreMenuAction>>[
        PopupMenuItem<_ChatMoreMenuAction>(
          value: _ChatMoreMenuAction.block,
          padding: EdgeInsets.zero,
          height: 48,
          child: const _ChatMoreMenuItem(),
        ),
      ],
    );

    if (action == _ChatMoreMenuAction.block) {
      await _handleBlockUser();
    }
  }

  Future<void> _handleBlockUser() async {
    if (_isBlockingUser) {
      return;
    }

    setState(() {
      _isBlockingUser = true;
    });

    try {
      await ref
          .read(userServiceProvider)
          .manageBlacklist(
            request: BlacklistBO(
              targetUserId: widget.args.targetUserId,
              action: 'add',
            ),
          );

      if (!mounted) {
        return;
      }
      Navigator.of(context).maybePop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_resolveBlockUserErrorMessage(error))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isBlockingUser = false;
        });
      }
    }
  }

  String _resolveBlockUserErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '消息.拉黑失败'.tr();
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
    final authUser = ref.watch(authSessionProvider).user;

    ref.listen<ChatPageState>(chatPageControllerProvider(widget.args), (
      previous,
      next,
    ) {
      if (previous?.conversationId != next.conversationId &&
          next.conversationId > 0) {
        _activeConversationId = next.conversationId;
        MessageSessionController.setActiveChatConversationId(
          next.conversationId,
        );
      }

      if (previous?.feedbackId != next.feedbackId &&
          next.feedbackMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.feedbackMessage!)));
        _chatController.clearFeedback();
      }

      if (previous?.clearComposerToken != next.clearComposerToken) {
        _inputController.clear();
      }

      if (previous?.newestMessageToken != next.newestMessageToken) {
        final bool animated = previous != null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _scrollToLatest(animated: animated);
        });
      }
    });
    ref.listen(messageSessionControllerProvider, (previous, next) {
      if (previous?.latestEventToken == next.latestEventToken) {
        return;
      }
      final event = next.latestEvent;
      if (event == null) {
        return;
      }
      _chatController.handleSseEvent(event);
    });

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: false,
      appBar: _ChatPageAppBar(
        args: widget.args,
        onBack: () => Navigator.of(context).maybePop(),
        onMoreTap: _showMoreMenu,
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
                        '消息.签证申请沟通提示'.tr(),
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
                            onRetry: _chatController.retry,
                          )
                        : _ChatMessageList(
                            messages: state.messages,
                            currentUserId: authUser?.userId ?? 0,
                            targetNickname: widget.args.nickname,
                            targetAvatarUrl: widget.args.avatarUrl,
                            currentUserNickname:
                                authUser?.nickname ?? '消息.我'.tr(),
                            currentUserAvatarUrl: authUser?.avatarUrl ?? '',
                            scrollController: _scrollController,
                            isLoadingMore: state.isLoadingMore,
                            playingMessageId: state.playingMessageId,
                            downloadingAudioMessageIds:
                                state.downloadingAudioMessageIds,
                            onTapFileMessage: _handleFileMessageTap,
                          ),
                  ),
                  _ChatComposer(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    isSending: state.isSending,
                    isVoiceMode: state.isVoiceMode,
                    recordingState: state.recordingState,
                    recordingSeconds: state.recordingSeconds,
                    onVoiceTap: _handleVoiceTap,
                    onVoiceRecordStart: _handleVoiceRecordStart,
                    onVoiceRecordEnd: _handleVoiceRecordEnd,
                    onVoiceRecordMoveUpdate: _handleVoiceRecordMove,
                    onFileTap: _handleFileAction,
                    onSend: () =>
                        _chatController.sendTextMessage(_inputController.text),
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

enum _ChatMoreMenuAction { block }

class _ChatPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatPageAppBar({
    required this.args,
    required this.onBack,
    required this.onMoreTap,
  });

  final ChatPageArgs args;
  final VoidCallback onBack;
  final ValueChanged<BuildContext> onMoreTap;

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
                  args.isOnline ? '消息.在线'.tr() : '消息.离线'.tr(),
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
        Builder(
          builder: (BuildContext buttonContext) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onMoreTap(buttonContext),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(child: _ChatMoreButtonDots()),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChatMoreButtonDots extends StatelessWidget {
  const _ChatMoreButtonDots();

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _ChatMoreMenuItem extends StatelessWidget {
  const _ChatMoreMenuItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 48,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.block_outlined,
            size: 18,
            color: _ChatPageState._titleColor,
          ),
          SizedBox(width: 10),
          Text(
            '消息.拉黑'.tr(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ],
      ),
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
                      '消息.订单状态'.tr(
                        namedArgs: <String, String>{'status': orderStatus},
                      ),
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
            TextButton(onPressed: onRetry, child: Text('消息.重新加载'.tr())),
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
    required this.playingMessageId,
    required this.downloadingAudioMessageIds,
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
  final int? playingMessageId;
  final Set<int> downloadingAudioMessageIds;
  final Future<void> Function(MessageVO message) onTapFileMessage;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: AppEmptyState(
          message: '消息.暂无聊天记录'.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                isPlaying: playingMessageId == message.messageId,
                isDownloading: downloadingAudioMessageIds.contains(
                  message.messageId,
                ),
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
    required this.isPlaying,
    required this.isDownloading,
    required this.onTapFileMessage,
  });

  final MessageVO message;
  final bool isMine;
  final String avatarUrl;
  final String fallbackName;
  final bool isPlaying;
  final bool isDownloading;
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
                  isPlaying: isPlaying,
                  isDownloading: isDownloading,
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
    required this.isPlaying,
    required this.isDownloading,
    required this.onTapFileMessage,
  });

  final MessageVO message;
  final bool isMine;
  final bool isPlaying;
  final bool isDownloading;
  final Future<void> Function(MessageVO message) onTapFileMessage;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isMine
        ? _ChatPageState._brandBlue
        : Colors.white;
    final Color foregroundColor = isMine
        ? Colors.white
        : _ChatPageState._titleColor;
    const Color attachmentBackgroundColor = Colors.white;
    const Color attachmentForegroundColor = _ChatPageState._titleColor;
    final BorderRadius borderRadius = BorderRadius.circular(12);

    if (message.type == 'image') {
      final String imagePath = message.fileUrl.trim();
      return InkWell(
        borderRadius: borderRadius,
        onTap: () => onTapFileMessage(message),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Container(
            color: attachmentBackgroundColor,
            child: AspectRatio(
              aspectRatio: 1,
              child: imagePath.isEmpty
                  ? Container(
                      color: attachmentBackgroundColor,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '消息.图片加载失败'.tr(),
                        style: const TextStyle(
                          color: attachmentForegroundColor,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : _isRemoteFileUrl(imagePath)
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: attachmentBackgroundColor,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '消息.图片加载失败'.tr(),
                          style: const TextStyle(
                            color: attachmentForegroundColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: attachmentBackgroundColor,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '消息.图片加载失败'.tr(),
                          style: const TextStyle(
                            color: attachmentForegroundColor,
                            fontSize: 14,
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
            color: attachmentBackgroundColor,
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
                  message.fileName.isEmpty ? '消息.文件消息'.tr() : message.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: attachmentForegroundColor,
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

    if (message.type == 'audio') {
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
              if (isDownloading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                  color: foregroundColor,
                ),
              const SizedBox(width: 8),
              Text(
                _formatAudioDuration(message.duration),
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
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
        message.isRetracted ? '消息.消息已撤回'.tr() : message.content,
        style: TextStyle(color: foregroundColor, fontSize: 15, height: 22 / 15),
      ),
    );
  }

  String _formatAudioDuration(int? seconds) {
    final int safeSeconds = seconds == null || seconds < 0 ? 0 : seconds;
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    final String minuteText = minutes.toString().padLeft(2, '0');
    final String secondText = remainder.toString().padLeft(2, '0');
    return '$minuteText:$secondText';
  }
}

bool _isRemoteFileUrl(String value) {
  final Uri? uri = Uri.tryParse(value);
  if (uri == null) {
    return false;
  }
  return uri.scheme == 'http' || uri.scheme == 'https';
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
    required this.isVoiceMode,
    required this.recordingState,
    required this.recordingSeconds,
    required this.onVoiceTap,
    required this.onVoiceRecordStart,
    required this.onVoiceRecordEnd,
    required this.onVoiceRecordMoveUpdate,
    required this.onFileTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isVoiceMode;
  final ChatVoiceRecordingState recordingState;
  final int recordingSeconds;
  final VoidCallback onVoiceTap;
  final Future<void> Function() onVoiceRecordStart;
  final Future<void> Function() onVoiceRecordEnd;
  final void Function(LongPressMoveUpdateDetails details)
  onVoiceRecordMoveUpdate;
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
                      isVoiceMode
                          ? _ChatPageState._keyboardAsset
                          : _ChatPageState._voiceAsset,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isVoiceMode
                    ? _VoiceRecordButton(
                        isSending: isSending,
                        recordingState: recordingState,
                        recordingSeconds: recordingSeconds,
                        onRecordStart: onVoiceRecordStart,
                        onRecordEnd: onVoiceRecordEnd,
                        onRecordMoveUpdate: onVoiceRecordMoveUpdate,
                      )
                    : TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !isSending,
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: '消息.发消息'.tr(),
                          hintStyle: const TextStyle(
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
              if (isVoiceMode)
                SizedBox(
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
                )
              else
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
                                '消息.发送'.tr(),
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

class _VoiceRecordButton extends StatelessWidget {
  const _VoiceRecordButton({
    required this.isSending,
    required this.recordingState,
    required this.recordingSeconds,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onRecordMoveUpdate,
  });

  final bool isSending;
  final ChatVoiceRecordingState recordingState;
  final int recordingSeconds;
  final Future<void> Function() onRecordStart;
  final Future<void> Function() onRecordEnd;
  final void Function(LongPressMoveUpdateDetails details) onRecordMoveUpdate;

  @override
  Widget build(BuildContext context) {
    final bool isCancel = recordingState == ChatVoiceRecordingState.cancel;
    final bool isRecording = recordingState == ChatVoiceRecordingState.recording;
    final Color backgroundColor = isCancel
        ? const Color(0xFFFFEAEA)
        : isRecording
        ? const Color(0xFFEAF3FF)
        : Colors.transparent;
    final Color foregroundColor = isCancel
        ? const Color(0xFFD9363E)
        : isRecording
        ? _ChatPageState._brandBlue
        : _ChatPageState._subtleTextColor;
    final String label = isCancel
        ? '消息.松开取消'.tr()
        : isRecording
        ? '${'消息.松开发送'.tr()} ${_formatDuration(recordingSeconds)}'
        : '消息.按住说话'.tr();
    return Listener(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: isSending ? null : (_) => onRecordStart(),
        onLongPressEnd: isSending ? null : (_) => onRecordEnd(),
        onLongPressMoveUpdate: isSending ? null : onRecordMoveUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 22 / 15,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int safeSeconds = seconds < 0 ? 0 : seconds;
    final int minutes = safeSeconds ~/ 60;
    final int remainder = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
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
                        label: '消息.拍照上传'.tr(),
                        iconAssetPath:
                            'assets/images/order_upload_sheet_camera.svg',
                        onTap: onCameraTap,
                      ),
                      _ChatAttachmentAction(
                        label: '消息.本地相册'.tr(),
                        iconAssetPath:
                            'assets/images/order_upload_sheet_gallery.svg',
                        onTap: onGalleryTap,
                      ),
                      _ChatAttachmentAction(
                        label: '消息.本地文件'.tr(),
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
      return '消息.求职者'.tr();
    case 'employer':
      return '招聘.企业'.tr();
    case 'visa_provider':
      return '消息.服务商'.tr();
    default:
      return '消息.客户'.tr();
  }
}

String _resolveOrderStatusLabel(String status) {
  final String trimmed = status.trim();
  if (trimmed.isEmpty) {
    return '消息.处理中'.tr();
  }
  switch (trimmed) {
    case 'pending_material':
      return '消息.待审核材料'.tr();
    case 'pending_pay':
      return '消息.待支付'.tr();
    case 'processing':
      return '消息.办理中'.tr();
    case 'completed':
      return '消息.已完成'.tr();
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
    return '消息.用户'.tr();
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
