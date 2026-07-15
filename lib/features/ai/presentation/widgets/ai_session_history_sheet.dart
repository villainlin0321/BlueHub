import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_text_input_dialog.dart';
import '../../data/ai_models.dart';
import '../../data/ai_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';
const String _kAiHistoryEditIconAsset = 'assets/images/ai_history_edit.svg';
const String _kAiHistoryDeleteIconAsset = 'assets/images/ai_history_delete.svg';
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
    final String? nextTitle = await showAppTextInputDialog(
      context: context,
      title: 'AI.编辑对话名称'.tr(),
      initialValue: session.title.trim(),
      hintText: 'AI.AI助手'.tr(),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.764,
          child: Column(
            children: <Widget>[
              _buildSheetHeader(context),
              const SizedBox(height: 9),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建历史记录弹窗顶部标题栏，统一控制标题居中与关闭按钮点击热区。
  Widget _buildSheetHeader(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            'AI.历史记录'.tr(),
            style: TestStyle.pingFangMedium(
              fontSize: 17,
              color: const Color(0xFF171A1D),
            ),
          ),
          Positioned(
            right: 16,
            child: SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                splashRadius: 20,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF171A1D),
                ),
              ),
            ),
          ),
        ],
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
          style: TestStyle.pingFangRegular(color: Color(0xFF8C8C8C)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.separated(
        padding: EdgeInsets.zero,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: const Color(0xFF262626),
                        ).copyWith(height: 22 / 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        updatedAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TestStyle.regular(
                          fontSize: 12,
                          color: const Color(0xFFBFBFBF),
                        ).copyWith(height: 14 / 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 29),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _AiSessionHistoryActionIcon(
                    assetPath: _kAiHistoryEditIconAsset,
                    tooltip: '通用.编辑'.tr(),
                    color: iconColor,
                    iconWidth: 14,
                    iconHeight: 14,
                    onTap: isBusy ? null : onRename,
                  ),
                ),
                const SizedBox(width: 20),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _AiSessionHistoryActionIcon(
                    assetPath: _kAiHistoryDeleteIconAsset,
                    tooltip: '通用.删除'.tr(),
                    color: iconColor,
                    iconWidth: 16,
                    iconHeight: 16,
                    onTap: isBusy ? null : onDelete,
                  ),
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
    required this.iconWidth,
    required this.iconHeight,
    required this.onTap,
  });

  final String assetPath;
  final String tooltip;
  final Color color;
  final double iconWidth;
  final double iconHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: iconWidth,
              height: iconHeight,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
