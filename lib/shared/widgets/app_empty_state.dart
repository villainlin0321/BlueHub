import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
/// 全局通用空态，统一插画与文案排版，外层容器由页面自行决定。
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.padding,
    this.imageAssetPath = defaultImageAssetPath,
    this.imageWidth = 132,
    this.imageHeight = 96,
    this.textTopSpacing = 16,
    this.textStyle,
  });

  static const String defaultImageAssetPath =
      'assets/images/app_empty_no_data.svg';

  final String message;
  final EdgeInsetsGeometry? padding;
  final String imageAssetPath;
  final double imageWidth;
  final double imageHeight;
  final double textTopSpacing;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(
          imageAssetPath,
          width: imageWidth,
          height: imageHeight,
        ),
        SizedBox(height: textTopSpacing),
        Text(
          message,
          textAlign: TextAlign.center,
          style:
              textStyle ??
              TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
        ),
      ],
    );

    if (padding == null) {
      return content;
    }

    return Padding(padding: padding!, child: content);
  }
}
