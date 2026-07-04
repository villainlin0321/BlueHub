import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';
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

  static final TextStyle navTitle = TestStyle.medium(fontSize: 17, color: titleColor);

  static final TextStyle countText = TestStyle.regular(fontSize: 14, color: titleColor);

  static final TextStyle nickname = TestStyle.regular(fontSize: 16, color: titleColor);

  static final TextStyle action = TestStyle.regular(fontSize: 14, color: actionColor);

  static final TextStyle footer = TestStyle.regular(fontSize: 12, color: secondaryText);

  static final TextStyle errorText = TestStyle.regular(fontSize: 14, color: secondaryText);

  const BlacklistPageStyles._();
}
