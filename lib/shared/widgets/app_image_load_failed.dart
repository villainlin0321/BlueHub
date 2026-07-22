import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:europepass/shared/ui/test_style.dart';

/// 通用图片加载失败占位，统一图标、文案与底色样式。
class AppImageLoadFailed extends StatelessWidget {
  const AppImageLoadFailed({
    super.key,
    this.width,
    this.height,
    this.message = '加载失败',
    this.backgroundColor = const Color(0xFFF5F7FA),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.iconSize = 20,
    this.iconColor = const Color(0xFF8C8C8C),
    this.spacing = 4,
    this.textStyle,
  });

  final double? width;
  final double? height;
  final String message;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final double iconSize;
  final Color iconColor;
  final double spacing;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/add_warining.svg',
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            SizedBox(height: spacing),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textStyle ??
                  TestStyle.pingFangRegular(
                    fontSize: 12,
                    color: iconColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
