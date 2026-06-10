import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../data/ai_models.dart';
import '../../data/ai_providers.dart';

const String _kAiHistoryEditIconAsset = 'assets/images/ai_history_edit.svg';
const String _kAiHistoryDeleteIconAsset = 'assets/images/ai_history_delete.svg';
const String _kAiHistoryRenameClearIconAsset =
    'assets/images/ai_history_rename_clear.svg';

Future<void> showAiSessionHistorySheet(
  BuildContext context, {
  required int? currentSessionId,
  required Future<void> Function(AiSessionVO session) onSessionSelected,
  required Future<void> Function() onCurrentSessionDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return _AiSessionHistorySheet(
        currentSessionId: currentSessionId,
        onSessionSelected: onSessionSelected,
        onCurrentSessionDeleted: onCurrentSessionDeleted,
      );
    },
  );
}

class _AiSessionHistorySheet extends ConsumerStatefulWidget {
  const _AiSessionHistorySheet({
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onCurrentSessionDeleted,
  });

  final int? currentSessionId;
  final Future<void> Function(AiSessionVO session) onSessionSelected;
  final Future<void> Function() onCurrentSessionDeleted;

  @override
  ConsumerState<_AiSessionHistorySheet> createState() =>
      _AiSessionHistorySheetState();
}

class _AiSessionHistorySheetState
    extends ConsumerState<_AiSessionHistorySheet> {
  List<AiSessionVO> _sessions = const <AiSessionVO>[];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<AiSessionVO> sessions = await ref
          .read(aiServiceProvider)
          .listSessions();
      if (!mounted) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _handleRename(AiSessionVO session) async {
    if (_isBusy) {
      return;
    }
    final String? nextTitle = await showAppDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _AiSessionRenameDialog(
          initialValue: session.title.trim(),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onComplete: (String value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        );
      },
    );
    if (nextTitle == null ||
        nextTitle.isEmpty ||
        nextTitle == session.title.trim()) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await ref
          .read(aiServiceProvider)
          .renameSession(id: session.sessionId, title: nextTitle);
      await _loadSessions();
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _handleDelete(AiSessionVO session) async {
    if (_isBusy) {
      return;
    }
    final bool confirmed = await showAppDeleteConfirmDialog(
      context: context,
      title: '通用.确认删除'.tr(),
      message: 'AI.删除对话不可恢复'.tr(),
      cancelLabel: '通用.取消'.tr(),
      confirmLabel: '通用.删除'.tr(),
    );
    if (!confirmed) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await ref.read(aiServiceProvider).deleteSession(id: session.sessionId);
      if (widget.currentSessionId == session.sessionId) {
        await widget.onCurrentSessionDeleted();
      }
      await _loadSessions();
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    AppToast.show(message);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 35,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      'AI.历史记录'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF171A1D),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        height: 25 / 17,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF171A1D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadSessions, child: Text('通用.重试'.tr())),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          'AI.暂无历史记录'.tr(),
          style: const TextStyle(color: Color(0xFF8C8C8C)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.separated(
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 0.5,
          thickness: 0.5,
          color: Color(0xFFF0F0F0),
        ),
        itemBuilder: (BuildContext context, int index) {
          final AiSessionVO item = _sessions[index];
          return _AiSessionHistoryItem(
            title: item.title.trim().isEmpty ? 'AI.AI助手'.tr() : item.title,
            updatedAt: item.updatedAt,
            isBusy: _isBusy,
            onRename: () => _handleRename(item),
            onDelete: () => _handleDelete(item),
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              await widget.onSessionSelected(item);
              if (mounted) {
                navigator.pop();
              }
            },
          );
        },
      ),
    );
  }
}

class _AiSessionRenameDialog extends StatefulWidget {
  const _AiSessionRenameDialog({
    required this.initialValue,
    required this.onCancel,
    required this.onComplete,
  });

  final String initialValue;
  final VoidCallback onCancel;
  final ValueChanged<String> onComplete;

  @override
  State<_AiSessionRenameDialog> createState() => _AiSessionRenameDialogState();
}

class _AiSessionRenameDialogState extends State<_AiSessionRenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'AI.编辑对话名称'.tr(),
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(height: 16),
              _AiSessionRenameInput(
                controller: _controller,
                onSubmitted: (_) => widget.onComplete(_controller.text),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _AiSessionRenameButton(
                      label: '通用.取消'.tr(),
                      isPrimary: false,
                      onTap: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AiSessionRenameButton(
                      label: '通用.完成'.tr(),
                      isPrimary: true,
                      onTap: () => widget.onComplete(_controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSessionRenameInput extends StatelessWidget {
  const _AiSessionRenameInput({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        final bool canClear = value.text.isNotEmpty;
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'AI.AI助手'.tr(),
                    hintStyle: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IgnorePointer(
                ignoring: !canClear,
                child: Opacity(
                  opacity: canClear ? 1 : 0,
                  child: GestureDetector(
                    onTap: () => controller.clear(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: SvgPicture.asset(
                        _kAiHistoryRenameClearIconAsset,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiSessionRenameButton extends StatelessWidget {
  const _AiSessionRenameButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: isPrimary ? const Color(0xFF096DD9) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isPrimary
                ? const Color(0xFF096DD9)
                : const Color(0xFFD9D9D9),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF262626),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSessionHistoryItem extends StatelessWidget {
  const _AiSessionHistoryItem({
    required this.title,
    required this.updatedAt,
    required this.isBusy,
    required this.onRename,
    required this.onDelete,
    required this.onTap,
  });

  final String title;
  final String updatedAt;
  final bool isBusy;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isBusy
        ? const Color(0xFFBFBFBF)
        : const Color(0xFF8C8C8C);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        child: SizedBox(
          height: 64,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 29),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF262626),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 22 / 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          updatedAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFBFBFBF),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 14 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _AiSessionHistoryActionIcon(
                  assetPath: _kAiHistoryEditIconAsset,
                  tooltip: '通用.编辑'.tr(),
                  color: iconColor,
                  onTap: isBusy ? null : onRename,
                ),
                const SizedBox(width: 20),
                _AiSessionHistoryActionIcon(
                  assetPath: _kAiHistoryDeleteIconAsset,
                  tooltip: '通用.删除'.tr(),
                  color: iconColor,
                  onTap: isBusy ? null : onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiSessionHistoryActionIcon extends StatelessWidget {
  const _AiSessionHistoryActionIcon({
    required this.assetPath,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final String assetPath;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 20,
          height: 20,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            assetPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
