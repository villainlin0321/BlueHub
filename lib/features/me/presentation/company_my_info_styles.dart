import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';
/// 企业端“我的信息”页的样式常量，统一管理颜色、间距与尺寸。
abstract final class CompanyMyInfoStyles {
  static const Color pageBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Color(0xFF262626);
  static const Color secondaryText = Color(0xFF8C8C8C);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color primaryButton = Color(0xFF096DD9);
  static const Color placeholderBackground = Color(0xFFF5F7FA);
  static const Color placeholderBorder = Color(0xFFD9D9D9);

  static const double pageHorizontalPadding = 12;
  static const double sectionRadius = 12;
  static const double qualificationPreviewRadius = 8;
  static const double qualificationPreviewWidth = 148;
  static const double qualificationPreviewHeight = 110;
  static const double primaryButtonHeight = 44;

  static final TextStyle navTitle = TestStyle.medium(fontSize: 17, color: primaryText);

  static final TextStyle sectionTitle = TestStyle.medium(fontSize: 16, color: primaryText);

  static final TextStyle fieldLabel = TestStyle.regular(fontSize: 16, color: primaryText);

  static final TextStyle fieldValue = TestStyle.regular(fontSize: 16, color: secondaryText);

  static final TextStyle noteText = TestStyle.regular(fontSize: 12, color: secondaryText);

  static final TextStyle buttonText = TestStyle.medium(fontSize: 16, color: Colors.white);
}
