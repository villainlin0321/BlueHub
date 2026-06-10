import 'dart:io';
import 'app_toast.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/files/data/file_models.dart';
import '../../features/files/data/file_providers.dart';
import '../../utils/upload_picker_utils.dart';
import 'upload_placeholder_tile.dart';

class UploadImageGrid extends ConsumerStatefulWidget {
  const UploadImageGrid({
    super.key,
    required this.scene,
    required this.onChanged,
    this.initialImagePaths = const <String>[],
    this.maxImages = 9,
    this.uploadAssetPath = 'assets/images/service_detail_report_upload.svg',
    this.uploadLabel,
    this.sourceSheetTitle,
    this.uploadErrorMessage,
    this.onUploadingChanged,
  });

  final FileScene scene;
  final ValueChanged<List<String>> onChanged;
  final List<String> initialImagePaths;
  final int maxImages;
  final String uploadAssetPath;
  final String? uploadLabel;
  final String? sourceSheetTitle;
  final String? uploadErrorMessage;
  final ValueChanged<bool>? onUploadingChanged;

  @override
  ConsumerState<UploadImageGrid> createState() => _UploadImageGridState();
}

class _UploadImageGridState extends ConsumerState<UploadImageGrid> {
  final List<_UploadImageEntry> _entries = <_UploadImageEntry>[];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _entries.addAll(
      widget.initialImagePaths.map<_UploadImageEntry>(_buildInitialEntry),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      _notifyChanged();
      final List<String> pendingIds = _entries
          .where((_UploadImageEntry entry) => entry.localPath != null)
          .map((entry) => entry.id)
          .toList(growable: false);
      await _uploadEntries(pendingIds);
    });
  }

  Future<void> _handleAddTap() async {
    if (_isUploading) {
      _showMessage('上传.图片上传中'.tr());
      return;
    }
    if (_entries.length >= widget.maxImages) {
      _showMaxImagesMessage();
      return;
    }

    final List<PickedUploadFile> pickedFiles =
        await UploadPickerUtils.pickImagesWithSourceSheet(
          context: context,
          title: widget.sourceSheetTitle ?? '上传.选择图片'.tr(),
        );
    if (!mounted || pickedFiles.isEmpty) {
      return;
    }

    final int availableCount = widget.maxImages - _entries.length;
    final List<PickedUploadFile> acceptedFiles = pickedFiles
        .where((PickedUploadFile file) => file.isImage)
        .take(availableCount)
        .toList(growable: false);
    if (acceptedFiles.isEmpty) {
      _showMaxImagesMessage();
      return;
    }

    final List<_UploadImageEntry> newEntries = acceptedFiles
        .map(_buildLocalEntry)
        .toList(growable: false);
    setState(() {
      _entries.addAll(newEntries);
    });

    if (acceptedFiles.length < pickedFiles.length) {
      _showMaxImagesMessage();
    }

    await _uploadEntries(
      newEntries.map((entry) => entry.id).toList(growable: false),
    );
  }

  Future<void> _uploadEntries(List<String> entryIds) async {
    if (entryIds.isEmpty) {
      return;
    }
    final String resolvedUploadErrorMessage =
        widget.uploadErrorMessage ?? '上传.图片上传失败'.tr();

    _setUploading(true);
    for (final String entryId in entryIds) {
      final _UploadImageEntry? entry = _findEntry(entryId);
      if (entry == null ||
          entry.localPath == null ||
          entry.uploadedUrl != null) {
        continue;
      }

      _replaceEntry(entryId, entry.copyWith(isUploading: true));
      try {
        final FilePresignVO uploaded = await ref
            .read(fileServiceProvider)
            .uploadFile(
              path: entry.localPath!,
              scene: widget.scene,
              errorMessage: resolvedUploadErrorMessage,
            );
        if (!mounted) {
          return;
        }
        _replaceEntry(
          entryId,
          entry.copyWith(uploadedUrl: uploaded.fileUrl, isUploading: false),
        );
        _notifyChanged();
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _entries.removeWhere((_UploadImageEntry item) => item.id == entryId);
        });
        _notifyChanged();
        _showMessage(_resolveErrorMessage(error));
      }
    }
    if (mounted) {
      _setUploading(false);
    }
  }

  void _removeEntry(_UploadImageEntry entry) {
    setState(() {
      _entries.removeWhere((_UploadImageEntry item) => item.id == entry.id);
    });
    _notifyChanged();
  }

  void _replaceEntry(String entryId, _UploadImageEntry updatedEntry) {
    if (!mounted) {
      return;
    }
    setState(() {
      final int index = _entries.indexWhere(
        (_UploadImageEntry entry) => entry.id == entryId,
      );
      if (index < 0) {
        return;
      }
      _entries[index] = updatedEntry;
    });
  }

  _UploadImageEntry? _findEntry(String entryId) {
    for (final _UploadImageEntry entry in _entries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  void _setUploading(bool value) {
    if (_isUploading == value) {
      return;
    }
    _isUploading = value;
    widget.onUploadingChanged?.call(value);
  }

  void _notifyChanged() {
    widget.onChanged(
      _entries
          .map((entry) => entry.uploadedUrl)
          .whereType<String>()
          .toList(growable: false),
    );
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  /// 统一提示图片数量上限，避免多处重复拼接带参数文案。
  void _showMaxImagesMessage() {
    _showMessage(
      '上传.最多上传'.tr(
        namedArgs: <String, String>{'count': widget.maxImages.toString()},
      ),
    );
  }

  String _resolveErrorMessage(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty
        ? (widget.uploadErrorMessage ?? '上传.图片上传失败'.tr())
        : message;
  }

  _UploadImageEntry _buildInitialEntry(String path) {
    return _UploadImageEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}_${path.hashCode}',
      previewPath: path,
      uploadedUrl: _isNetworkPath(path) ? path : null,
      localPath: _isNetworkPath(path) ? null : path,
    );
  }

  _UploadImageEntry _buildLocalEntry(PickedUploadFile file) {
    return _UploadImageEntry(
      id: file.id,
      previewPath: file.path,
      localPath: file.path,
    );
  }

  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedUploadLabel = widget.uploadLabel ?? '上传.上传图片'.tr();
    final bool showAddTile = _entries.length < widget.maxImages;
    final int itemCount = _entries.length + (showAddTile ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _entries.length) {
          return UploadPlaceholderTile(
            assetPath: widget.uploadAssetPath,
            label: resolvedUploadLabel,
            onTap: _handleAddTap,
          );
        }

        final _UploadImageEntry entry = _entries[index];
        return _UploadImageTile(
          entry: entry,
          onDeleteTap: () => _removeEntry(entry),
        );
      },
    );
  }
}

class _UploadImageEntry {
  const _UploadImageEntry({
    required this.id,
    required this.previewPath,
    this.uploadedUrl,
    this.localPath,
    this.isUploading = false,
  });

  final String id;
  final String previewPath;
  final String? uploadedUrl;
  final String? localPath;
  final bool isUploading;

  _UploadImageEntry copyWith({
    String? previewPath,
    Object? uploadedUrl = _sentinel,
    Object? localPath = _sentinel,
    bool? isUploading,
  }) {
    return _UploadImageEntry(
      id: id,
      previewPath: previewPath ?? this.previewPath,
      uploadedUrl: identical(uploadedUrl, _sentinel)
          ? this.uploadedUrl
          : uploadedUrl as String?,
      localPath: identical(localPath, _sentinel)
          ? this.localPath
          : localPath as String?,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  static const Object _sentinel = Object();
}

class _UploadImageTile extends StatelessWidget {
  const _UploadImageTile({required this.entry, required this.onDeleteTap});

  final _UploadImageEntry entry;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _UploadImagePreview(path: entry.previewPath),
                  if (entry.isUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDeleteTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadImagePreview extends StatelessWidget {
  const _UploadImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        errorWidget: (BuildContext context, String url, Object error) =>
            const _UploadImageFallback(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _UploadImageFallback(),
    );
  }
}

class _UploadImageFallback extends StatelessWidget {
  const _UploadImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5F7FA),
      child: Center(
        child: Icon(Icons.photo_outlined, size: 28, color: Color(0xFF8C8C8C)),
      ),
    );
  }
}
