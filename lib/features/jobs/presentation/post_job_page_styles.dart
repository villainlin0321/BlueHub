import 'package:flutter/material.dart';

/// 发布岗位页样式常量，尽量对齐 Figma 导出值。
class PostJobPageStyles {
  static const Color pageBackground = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF096DD9);
  static const Color titleText = Color(0xFF262626);
  static const Color bodyText = Color(0xFF171A1D);
  static const Color secondaryText = Color(0xFF8C8C8C);
  static const Color placeholderText = Color(0xFFBFBFBF);
  static const Color inputFill = Color(0xFFF5F7FA);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color required = Color(0xFFFF4D4F);
  static const Color chipSelectedBackground = Color(0xFFEDF4FF);
  static const Color chipSelectedBorder = Color(0xFF91C3FF);
  static const Color chipSelectedText = Color(0xFF096DD9);
  static const Color chipUnselectedBorder = Color(0xFFBFBFBF);
  static const Color chipUnselectedText = Color(0xFF171A1D);

  static const double pageHorizontalPadding = 12;
  static const double cardRadius = 12;
  static const double fieldRadius = 8;
  static const double chipRadius = 4;
  static const double buttonRadius = 8;

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static const TextStyle navTitle = TextStyle(
    color: Color(0xE6000000),
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 24 / 17,
  );

  static const TextStyle navAction = TextStyle(
    color: titleText,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 21 / 15,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: titleText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: titleText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle optionText = TextStyle(
    color: bodyText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle placeholder = TextStyle(
    color: placeholderText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle optional = TextStyle(
    color: secondaryText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle buttonText = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );

  static const TextStyle counter = TextStyle(
    color: placeholderText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );
}
