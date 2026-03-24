import 'package:flutter/material.dart';

import 'app_color_tokens.dart';

final class AppShadowTokens {
  const AppShadowTokens._();

  static const List<BoxShadow> surface = [
    BoxShadow(
      color: Color(0x73020617),
      blurRadius: 40,
      offset: Offset(0, 18),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x47060A14),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> focusRing() {
    return [
      BoxShadow(
        color: AppColorTokens.primary.withValues(alpha: 0.25),
        blurRadius: 0,
        spreadRadius: 2,
      ),
    ];
  }
}
