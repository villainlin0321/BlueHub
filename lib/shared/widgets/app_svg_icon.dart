import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG 图标组件：优先加载 asset，加载失败时回退到 Icon。
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.size = 24,
    this.color,
  });

  final String assetPath;
  final IconData fallback;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // 关键点：Figma 导出的资源量大，个别文件可能缺失；这里做容错，避免整页渲染失败。
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      placeholderBuilder: (_) => Icon(fallback, size: size, color: color),
    );
  }
}

