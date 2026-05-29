import 'package:flutter/material.dart';

class BlacklistPageStyles {
  static const Color pageBackground = Color(0xFFF5F7FA);
  static const Color navBackground = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color titleColor = Color(0xFF262626);
  static const Color secondaryText = Color(0xFF8C8C8C);
  static const Color actionColor = Color(0xFF096DD9);
  static const Color divider = Color(0xFFF0F0F0);

  static const double horizontalPadding = 12;
  static const double topPadding = 12;
  static const double cardRadius = 12;
  static const double tileHeight = 56;
  static const double avatarSize = 36;

  static const TextStyle navTitle = TextStyle(
    color: titleColor,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 24 / 17,
  );

  static const TextStyle countText = TextStyle(
    color: titleColor,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle nickname = TextStyle(
    color: titleColor,
    fontSize: 16,
    height: 22 / 16,
  );

  static const TextStyle action = TextStyle(
    color: actionColor,
    fontSize: 14,
    height: 20 / 14,
  );

  static const TextStyle footer = TextStyle(
    color: secondaryText,
    fontSize: 12,
    height: 18 / 12,
  );

  static const TextStyle errorText = TextStyle(
    color: secondaryText,
    fontSize: 14,
    height: 20 / 14,
  );

  const BlacklistPageStyles._();
}
