import 'package:flutter/material.dart';

/// 统一管理项目内的字体族与常用文字样式。
class TestStyle {
  const TestStyle._();

  static const String pingFangFamily = 'PingFang';
  static const String sfUiTextFamily = 'SFUIText';
  static const String miSansLatinFamily = 'MiSansLatinVF';
  static const String alibabaPuHuiTiFamily = 'AlibabaPuHuiTi';

  static TextStyle regular({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: sfUiTextFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle medium({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: sfUiTextFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle semibold({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: sfUiTextFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle bold({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: sfUiTextFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle pingFangRegular({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: pingFangFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle pingFangMedium({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: pingFangFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle pingFangSemibold({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: pingFangFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle numberRegular({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: sfUiTextFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle numberBold({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: miSansLatinFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle bannerBold({
    required double fontSize,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return _style(
      fontFamily: alibabaPuHuiTiFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }

  static TextStyle _style({
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    TextOverflow? overflow,
    Color? backgroundColor,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
      overflow: overflow,
      backgroundColor: backgroundColor,
    );
  }
}
