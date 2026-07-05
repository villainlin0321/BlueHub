import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../qualification_preview_resolver.dart';

/// 统一处理资质认证图片预览，兼容本地文件与网络缓存回显。
class QualificationPreviewImage extends StatelessWidget {
  const QualificationPreviewImage({
    super.key,
    required this.previewPath,
    required this.placeholderAsset,
    this.fit = BoxFit.cover,
    this.placeholderFit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final String? previewPath;
  final String placeholderAsset;
  final BoxFit fit;
  final BoxFit placeholderFit;
  final BorderRadius borderRadius;

  /// 根据路径来源切换本地文件预览或网络缓存图片，并在失败时回退占位图。
  @override
  Widget build(BuildContext context) {
    final String? normalizedPath = previewPath?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return _buildPlaceholder();
    }

    if (QualificationPreviewResolver.isNetworkPath(normalizedPath)) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: normalizedPath,
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          placeholder: (_, __) => _buildPlaceholder(),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        File(normalizedPath),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      ),
    );
  }

  /// 统一返回占位图，避免各上传卡片分别处理空态和失败态。
  Widget _buildPlaceholder() {
    return Image.asset(
      placeholderAsset,
      width: double.infinity,
      height: double.infinity,
      fit: placeholderFit,
    );
  }
}
