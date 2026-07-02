import 'package:flutter/material.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';

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

  static final TextStyle sectionTitle = TestStyle.medium(
    fontSize: 16,
    color: textPrimary,
  );

  static final TextStyle fieldLabel = TestStyle.regular(
    fontSize: 14,
    color: textPrimary,
  );

  static final TextStyle fieldValue = TestStyle.regular(
    fontSize: 14,
    color: textPrimary,
  );

  static final TextStyle fieldHint = TestStyle.regular(
    fontSize: 14,
    color: textTertiary,
  );

  static final TextStyle helper = TestStyle.regular(
    fontSize: 12,
    color: textSecondary,
  );

  static final TextStyle plainChip = TestStyle.regular(
    fontSize: 14,
    color: textStrong,
  );

  static final TextStyle selectedChip = TestStyle.regular(
    fontSize: 14,
    color: primary,
  );

  static final TextStyle headerTitle = TestStyle.medium(
    fontSize: 17,
    color: black,
  );

  static final TextStyle headerAction = TestStyle.regular(
    fontSize: 14,
    color: textPrimary,
  );

  static final TextStyle primaryButton = TestStyle.medium(
    fontSize: 16,
    color: white,
  );

  static final TextStyle secondaryButton = TestStyle.regular(
    fontSize: 14,
    color: primary,
  );

  static final TextStyle materialMeta = TestStyle.regular(
    fontSize: 14,
    color: textSecondary,
  );

  static InputBorder inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: color),
    );
  }
}
