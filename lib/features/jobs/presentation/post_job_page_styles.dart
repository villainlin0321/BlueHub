import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';
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
  static const double chipHeight = 35.8;
  static const double buttonRadius = 8;

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static final TextStyle navTitle = TestStyle.medium(fontSize: 17, color: Color(0xE6000000));

  static final TextStyle navAction = TestStyle.regular(fontSize: 15, color: titleText);

  static final TextStyle sectionTitle = TestStyle.medium(fontSize: 16, color: titleText);

  static final TextStyle fieldLabel = TestStyle.regular(fontSize: 14, color: titleText);

  static final TextStyle optionText = TestStyle.regular(fontSize: 14, color: bodyText);

  static final TextStyle placeholder = TestStyle.regular(fontSize: 14, color: placeholderText);

  static final TextStyle optional = TestStyle.regular(fontSize: 14, color: secondaryText);

  static final TextStyle buttonText = TestStyle.medium(fontSize: 16, color: Colors.white);

  static final TextStyle counter = TestStyle.regular(fontSize: 12, color: placeholderText);
}
