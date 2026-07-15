import 'package:flutter/material.dart';

/// 统一管理项目内的字体族与常用文字样式。
class TestStyle {
  const TestStyle._();

  // static const String pingFangFamily = 'PingFang';
  static const String pingFangFamily = '';
  static const String sfUiTextFamily = 'SFUIText';
  static const String miSansLatinFamily = 'MiSansLatinVF';
  static const String alibabaPuHuiTiFamily = 'AlibabaPuHuiTi';

  static TextStyle regular({
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
    double? fontSize,
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
