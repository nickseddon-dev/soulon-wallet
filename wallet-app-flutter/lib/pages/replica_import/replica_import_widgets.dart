import 'package:flutter/material.dart';

import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';

final class ReplicaProgressDots extends StatelessWidget {
  const ReplicaProgressDots({super.key, required this.total, required this.currentIndex});

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

final class ReplicaListRow extends StatelessWidget {
  const ReplicaListRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColorTokens.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColorTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

