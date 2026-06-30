import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
class UploadPlaceholderTile extends StatelessWidget {
  const UploadPlaceholderTile({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.label,
    this.borderRadius = 8,
    this.iconSize = 24,
    this.backgroundColor = const Color(0xFFF5F7FA),
  });

  final String assetPath;
  final VoidCallback onTap;
  final String? label;
  final double borderRadius;
  final double iconSize;
  final Color backgroundColor;

  @override
  /// 构建上传占位卡片，未传文案时默认展示国际化后的“上传图片”。
  Widget build(BuildContext context) {
    final String resolvedLabel = label ?? '上传.上传图片'.tr();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              placeholderBuilder: (_) => Icon(
                Icons.add_photo_alternate_outlined,
                size: iconSize,
                color: const Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              resolvedLabel,
              style: TestStyle.regular(fontSize: 12, color: const Color(0xFF595959)),
            ),
          ],
        ),
      ),
    );
  }
}
