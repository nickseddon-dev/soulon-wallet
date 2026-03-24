import 'package:flutter/material.dart';

import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';

final class ReplicaOnboardingDots extends StatelessWidget {
  const ReplicaOnboardingDots({super.key, required this.total, required this.currentIndex});

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final active = index == currentIndex;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active ? AppColorTokens.accent : AppColorTokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
          ),
        );
      }),
    );
  }
}

final class ReplicaOnboardingPrimaryButton extends StatelessWidget {
  const ReplicaOnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorTokens.surfaceSubtle,
          foregroundColor: AppColorTokens.textPrimary,
          disabledBackgroundColor: AppColorTokens.surfaceSubtle,
          disabledForegroundColor: AppColorTokens.textMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

final class ReplicaOnboardingSecondaryButton extends StatelessWidget {
  const ReplicaOnboardingSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorTokens.surface,
          foregroundColor: AppColorTokens.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

