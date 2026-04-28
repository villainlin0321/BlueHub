import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UploadPlaceholderTile extends StatelessWidget {
  const UploadPlaceholderTile({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.label = '上传图片',
    this.borderRadius = 8,
    this.iconSize = 24,
    this.backgroundColor = const Color(0xFFF5F7FA),
  });

  final String assetPath;
  final VoidCallback onTap;
  final String label;
  final double borderRadius;
  final double iconSize;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
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
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF595959),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
