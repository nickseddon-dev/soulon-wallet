import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_onboarding_store.dart';
import 'replica_onboarding_widgets.dart';

final class ReplicaOnboardingFinishPage extends StatelessWidget {
  const ReplicaOnboardingFinishPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ReplicaOnboardingDots(total: 5, currentIndex: 4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                '一切就绪!',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColorTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.md),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                  children: const [
                    TextSpan(text: '使用 '),
                    TextSpan(
                      text: 'Shift + Alt + B',
                      style: TextStyle(color: AppColorTokens.accent, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' 打开 Backpack'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacingTokens.xl),
              Row(
                children: const [
                  Expanded(child: _LinkCard(icon: Icons.support_agent, label: '支持')),
                  SizedBox(width: 12),
                  Expanded(child: _LinkCard(icon: Icons.close, label: '@Backpack')),
                  SizedBox(width: 12),
                  Expanded(child: _LinkCard(icon: Icons.chat_bubble_outline, label: 'Discord')),
                ],
              ),
              const Spacer(flex: 3),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, WalletRoutes.replicaMobileHome, (_) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.primary,
                    foregroundColor: AppColorTokens.primaryText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('打开Backpack', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.sm),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColorTokens.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
