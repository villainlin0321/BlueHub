import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 求职者端页面通用背景图容器。
class JobSeekerPageBackground extends StatelessWidget {
  const JobSeekerPageBackground({
    super.key,
    required this.child,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  });

  static const String assetPath = 'assets/images/mon5bjog-m6uktu1.svg';

  final Widget child;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: SvgPicture.asset(
              assetPath,
              fit: fit,
              alignment: alignment,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
