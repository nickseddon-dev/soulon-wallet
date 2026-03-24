import 'package:flutter/material.dart';

import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_shadow_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: AppShadowTokens.card),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColorTokens.textPrimary,
                          ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AppSpacingTokens.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
