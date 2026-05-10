import 'package:flutter/material.dart';

abstract final class CompanyApplicationManagementStyles {
  static const Color pageBackground = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF096DD9);
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8C8C8C);
  static const Color textTertiary = Color(0xFFBFBFBF);
  static const Color divider = Color(0x297E868E);
  static const Color tagBorder = Color(0xFFA3AFD4);
  static const Color tagText = Color(0xFF546D96);
  static const Color ghostBorder = Color(0xFFD9D9D9);
  static const Color cardShadow = Color(0x0F000000);
  static const Color actionOverlay = Color(0x0F096DD9);

  static const double pageHorizontalPadding = 12;
  static const double cardRadius = 12;
  static const double buttonRadius = 14;
  static const double tagRadius = 3;

  static const String backAssetPath =
      'assets/images/company_application_back.svg';
  static const String searchAssetPath =
      'assets/images/company_application_search.svg';
  static const String filterArrowAssetPath =
      'assets/images/company_application_dropdown_arrow.png';
  static const String avatarPlaceholderAssetPath =
      'assets/images/company_application_avatar_placeholder.png';
  static const String primaryCardBackgroundAssetPath =
      'assets/images/company_application_card_bg_primary.svg';
  static const String secondaryCardBackgroundAssetPath =
      'assets/images/company_application_card_bg_secondary.svg';
}
