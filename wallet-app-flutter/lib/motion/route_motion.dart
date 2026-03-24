import 'package:flutter/material.dart';

import '../theme/tokens/app_motion_tokens.dart';

PageRouteBuilder<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: AppMotionTokens.normal,
    reverseTransitionDuration: AppMotionTokens.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: AppMotionTokens.standard,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: AppMotionTokens.decelerate),
      );
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

PageRouteBuilder<T> fadeScaleRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: AppMotionTokens.slow,
    reverseTransitionDuration: AppMotionTokens.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: AppMotionTokens.standard,
      );
      final scale = Tween<double>(begin: 0.96, end: 1).animate(
        CurvedAnimation(parent: animation, curve: AppMotionTokens.emphasized),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
