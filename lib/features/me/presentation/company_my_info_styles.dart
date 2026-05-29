import 'package:flutter/material.dart';

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

  static const TextStyle navTitle = TextStyle(
    color: primaryText,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 24 / 17,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: primaryText,
    fontSize: 16,
    height: 22 / 16,
  );

  static const TextStyle fieldValue = TextStyle(
    color: secondaryText,
    fontSize: 16,
    height: 22 / 16,
  );

  static const TextStyle noteText = TextStyle(
    color: secondaryText,
    fontSize: 12,
    height: 18 / 12,
  );

  static const TextStyle buttonText = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );
}
