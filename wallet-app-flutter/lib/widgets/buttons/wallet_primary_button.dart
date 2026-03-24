import 'package:flutter/material.dart';

import '../../motion/motion_pressable.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_motion_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_shadow_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';

class WalletPrimaryButton extends StatelessWidget {
  const WalletPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return MotionPressable(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: AppMotionTokens.fast,
        curve: AppMotionTokens.decelerate,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? AppColorTokens.border : AppColorTokens.primary,
          borderRadius: BorderRadius.circular(AppRadiusTokens.md),
          boxShadow: disabled ? null : AppShadowTokens.card,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.lg),
        child: loading
            ? const SizedBox(
                width: AppSpacingTokens.lg + 2,
                height: AppSpacingTokens.lg + 2,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColorTokens.textPrimary,
                    ),
              ),
      ),
    );
  }
}
