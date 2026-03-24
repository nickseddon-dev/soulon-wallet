import 'package:flutter/material.dart';

final class AppColorTokens {
  const AppColorTokens._();

  // Backpack Colors (Dark Mode)
  // Backgrounds
  static const Color background = Color(0xFF0E0F14); // base950
  static const Color surface = Color(0xFF14151B); // base900
  static const Color surfaceSubtle = Color(0xFF202127); // base800

  // Primary Action (White Button)
  static const Color primary = Color(0xFFFFFFFF); // baseWhite
  static const Color primaryPressed = Color(0xFFF4F4F6); // base50
  static const Color primaryText = Color(0xFF14151B); // base900

  // Secondary Action (Dark Button)
  static const Color secondary = Color(0xFF202127); // base800
  static const Color secondaryPressed = Color(0xFF383A45); // base700
  static const Color secondaryText = Color(0xFFF4F4F6); // base50

  // Borders
  static const Color border = Color(0xFF202127); // base800
  static const Color borderLight = Color(0x26FFFFFF); // baseWhite alpha 0.15

  // Semantic
  static const Color accent = Color(0xFF4C94FF); // blue500
  static const Color success = Color(0xFF00C278); // green500
  static const Color warning = Color(0xFFEFA411); // yellow500
  static const Color danger = Color(0xFFFF575A); // red500

  // Text
  static const Color textPrimary = Color(0xFFF4F4F6); // base50
  static const Color textSecondary = Color(0xFF969FAF); // base400
  static const Color textMuted = Color(0xFF5D606F); // base600
}
