import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../app/router/route_paths.dart';
import '../../utils/upload_picker_utils.dart';
import '../widgets/app_toast.dart';

/// 附件预览页入参，统一描述图片与 PDF 的预览所需信息。
class AttachmentPreviewArgs {
  const AttachmentPreviewArgs({
    required this.path,
    required this.title,
    required this.isImage,
    required this.isPdf,
  });

  final String path;
  final String title;
  final bool isImage;
  final bool isPdf;
}

/// 统一打开附件预览页，优先使用业务层显式类型，扩展名判断仅作兜底。
Future<void> openAttachmentPreview(
  BuildContext context, {
  required String path,
  String? title,
  bool? isImage,
  bool? isPdf,
}) async {
  final String normalizedPath = path.trim();
  if (normalizedPath.isEmpty) {
    AppToast.show('附件预览.文件地址无效'.tr());
    return;
  }
  final bool resolvedIsImage =
      isImage ?? UploadPickerUtils.isImagePath(normalizedPath);
  final bool resolvedIsPdf = isPdf ?? UploadPickerUtils.isPdfPath(normalizedPath);
  if (!resolvedIsImage && !resolvedIsPdf) {
    AppToast.show('附件预览.暂不支持该文件类型'.tr());
    return;
  }

  final String resolvedTitle = (title ?? '').trim().isEmpty
      ? UploadPickerUtils.basename(normalizedPath)
      : title!.trim();
  await context.push(
    RoutePaths.attachmentPreview,
    extra: AttachmentPreviewArgs(
      path: normalizedPath,
      title: resolvedTitle,
      isImage: resolvedIsImage,
      isPdf: resolvedIsPdf,
    ),
  );
}

/// 附件预览页，统一承载图片与 PDF 的应用内预览能力。
class AttachmentPreviewPage extends StatefulWidget {
  const AttachmentPreviewPage({super.key, required this.args});

  final AttachmentPreviewArgs args;

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  String? _pdfErrorMessage;

  /// 记录 PDF 加载失败信息，避免底层错误直接暴露为崩溃。
  void _handlePdfLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pdfErrorMessage = details.description.trim().isEmpty
          ? '附件预览.PDF加载失败'.tr()
          : details.description.trim();
    });
  }

  /// 渲染页面主体，按附件类型切换到图片或 PDF 预览。
  Widget _buildBody() {
    if (widget.args.path.trim().isEmpty) {
      return _PreviewErrorState(message: '附件预览.文件地址无效'.tr());
    }
    if (widget.args.isImage) {
      return _AttachmentImagePreview(path: widget.args.path);
    }
    if (widget.args.isPdf) {
      return _buildPdfPreview();
    }
    return _PreviewErrorState(message: '附件预览.暂不支持该文件类型'.tr());
  }

  /// 构建 PDF 预览区域，同时兼容本地路径与远程 URL。
  Widget _buildPdfPreview() {
    if (_pdfErrorMessage != null) {
      return _PreviewErrorState(message: _pdfErrorMessage!);
    }

    final String path = widget.args.path;
    if (_isNetworkPath(path)) {
      return SfPdfViewer.network(
        path,
        onDocumentLoadFailed: _handlePdfLoadFailed,
      );
    }

    final File file = File(path);
    if (!file.existsSync()) {
      return _PreviewErrorState(message: '附件预览.文件地址无效'.tr());
    }
    return SfPdfViewer.file(file, onDocumentLoadFailed: _handlePdfLoadFailed);
  }

  /// 判断当前路径是否为可直接访问的网络资源。
  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.args.title.trim().isEmpty
              ? '附件预览.标题'.tr()
              : widget.args.title,
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(child: _buildBody()),
    );
  }
}

/// 图片预览组件，支持缩放查看本地或网络图片。
class _AttachmentImagePreview extends StatelessWidget {
  const _AttachmentImagePreview({required this.path});

  final String path;

  /// 判断当前路径是否为网络图片地址。
  bool _isNetworkPath(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  /// 构建图片组件，优先展示真实图片，失败时回退到统一错误态。
  Widget _buildImage() {
    if (_isNetworkPath(path)) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        progressIndicatorBuilder:
            (BuildContext context, String url, DownloadProgress progress) =>
                const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, ___) =>
            _PreviewErrorState(message: '附件预览.图片加载失败'.tr()),
      );
    }

    final File file = File(path);
    if (!file.existsSync()) {
      return _PreviewErrorState(message: '附件预览.文件地址无效'.tr());
    }
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          _PreviewErrorState(message: '附件预览.图片加载失败'.tr()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(child: _buildImage()),
    );
  }
}

/// 统一错误态组件，避免预览失败时出现空白页面。
class _PreviewErrorState extends StatelessWidget {
  const _PreviewErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
