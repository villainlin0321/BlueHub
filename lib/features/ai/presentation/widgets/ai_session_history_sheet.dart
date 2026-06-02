import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_models.dart';
import '../../data/ai_providers.dart';

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

class _AiSessionHistorySheetState extends ConsumerState<_AiSessionHistorySheet> {
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
      final List<AiSessionVO> sessions = await ref.read(aiServiceProvider).listSessions();
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
    final TextEditingController controller = TextEditingController(
      text: session.title.trim(),
    );
    final String? nextTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('AI.历史记录'.tr()),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: 'AI.AI助手'.tr()),
            onSubmitted: (String value) {
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('通用.取消'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim(),
              ),
              child: Text('通用.确认'.tr()),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (nextTitle == null || nextTitle.isEmpty || nextTitle == session.title.trim()) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await ref.read(aiServiceProvider).renameSession(id: session.sessionId, title: nextTitle);
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('AI.历史记录'.tr()),
          content: Text(
            tr(
              '通用.删除确认提示',
              namedArgs: <String, String>{'name': session.title.trim()},
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('通用.取消'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('通用.删除'.tr()),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? const Color(0xFFD9363E) : null,
          content: Text(message),
        ),
      );
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI.历史记录'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final AiSessionVO item = _sessions[index];
          final bool isCurrent = item.sessionId == widget.currentSessionId;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.title.trim().isEmpty ? 'AI.AI助手'.tr() : item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.updatedAt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              spacing: 8,
              children: <Widget>[
                if (isCurrent)
                  const Icon(Icons.check_circle, color: Color(0xFF1677FF), size: 18),
                IconButton(
                  onPressed: _isBusy ? null : () => _handleRename(item),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '通用.编辑'.tr(),
                ),
                IconButton(
                  onPressed: _isBusy ? null : () => _handleDelete(item),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '通用.删除'.tr(),
                ),
              ],
            ),
            onTap: _isBusy
                ? null
                : () async {
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
