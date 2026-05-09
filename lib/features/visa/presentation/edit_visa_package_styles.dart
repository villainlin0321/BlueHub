import 'package:flutter/material.dart';

/// “编辑/签证套餐”页面的样式常量，集中管理以便复用。
abstract final class EditVisaPackageStyles {
  static const double designWidth = 375;

  static const Color pageBackground = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF096DD9);
  static const Color primarySoft = Color(0xFFEDF4FF);
  static const Color primaryBorder = Color(0xFF91C3FF);
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8C8C8C);
  static const Color textTertiary = Color(0xFFBFBFBF);
  static const Color textStrong = Color(0xFF171A1D);
  static const Color border = Color(0xFFD9D9D9);
  static const Color borderMuted = Color(0xFFBFBFBF);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color fieldBackground = Color(0xFFF5F7FA);
  static const Color required = Color(0xFFFF4D4F);
  static const Color danger = Color(0xFFD9363E);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(4));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(8));

  static const TextStyle sectionTitle = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: textPrimary,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle fieldValue = TextStyle(
    color: textPrimary,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle fieldHint = TextStyle(
    color: textTertiary,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle helper = TextStyle(
    color: textSecondary,
    fontSize: 12,
    height: 16 / 12,
  );

  static const TextStyle plainChip = TextStyle(
    color: textStrong,
    fontSize: 14,
    height: 18 / 14,
  );

  static const TextStyle selectedChip = TextStyle(
    color: primary,
    fontSize: 14,
    height: 18 / 14,
  );

  static const TextStyle headerTitle = TextStyle(
    color: black,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 24 / 17,
  );

  static const TextStyle headerAction = TextStyle(
    color: textPrimary,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle primaryButton = TextStyle(
    color: white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
  );

  static const TextStyle secondaryButton = TextStyle(
    color: primary,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle materialMeta = TextStyle(
    color: textSecondary,
    fontSize: 14,
    height: 20 / 14,
  );

  static InputBorder inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: color),
    );
  }
}
