import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 通用用户头像组件。
///
/// 基于 `CachedNetworkImage` 封装，统一处理以下能力：
/// 1. 网络头像缓存与失败回退；
/// 2. 通过 `size` 自动计算合适的解码尺寸，减少小图模糊和大图浪费；
/// 3. 支持自定义圆角、占位资源和适配不同页面的头像样式。
class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    this.placeholderAssetPath,
    this.placeholder,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.backgroundColor = const Color(0xFFF5F5F5),
  });

  final String imageUrl;
  final double size;
  final String? placeholderAssetPath;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String trimmedUrl = imageUrl.trim();
    final BorderRadius resolvedBorderRadius =
        borderRadius ?? BorderRadius.circular(size / 2);
    final int targetPixelSize = _resolveTargetPixelSize(context);
    final Widget fallback = _buildFallback();

    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: trimmedUrl.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: trimmedUrl,
                width: size,
                height: size,
                fit: fit,
                memCacheWidth: targetPixelSize,
                memCacheHeight: targetPixelSize,
                maxWidthDiskCache: targetPixelSize,
                maxHeightDiskCache: targetPixelSize,
                filterQuality: FilterQuality.high,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  Widget _buildFallback() {
    if (placeholder != null) {
      return SizedBox(width: size, height: size, child: placeholder);
    }
    if (placeholderAssetPath != null && placeholderAssetPath!.isNotEmpty) {
      return Image.asset(
        placeholderAssetPath!,
        width: size,
        height: size,
        fit: fit,
      );
    }
    return Icon(
      Icons.person_outline,
      size: size * 0.58,
      color: const Color(0xFF8C8C8C),
    );
  }

  /// 按展示尺寸和屏幕像素比估算目标解码尺寸：
  /// - 小头像至少保留 64px，避免高密度屏幕下出现糊边；
  /// - 超大头像限制到 1024px，避免无意义的内存与磁盘缓存开销。
  int _resolveTargetPixelSize(BuildContext context) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final double rawSize = size * math.max(devicePixelRatio, 1);
    return rawSize.round().clamp(64, 1024);
  }
}
