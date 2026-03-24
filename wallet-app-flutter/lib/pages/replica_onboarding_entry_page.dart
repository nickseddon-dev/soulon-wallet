import 'package:flutter/material.dart';
import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import 'replica_onboarding/replica_onboarding_store.dart';
import 'replica_onboarding/replica_onboarding_widgets.dart';

class ReplicaOnboardingEntryPage extends StatelessWidget {
  const ReplicaOnboardingEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaOnboardingProvider.of(context);
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      body: Center(
        child: Container(
          width: 420,
          // Backpack: YStack gap={40}
          // Padding top to account for visual balance if needed, but Backpack centers vertically.
          padding: const EdgeInsets.symmetric(horizontal: 24), // Add some horizontal padding for safety on small screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: ReplicaOnboardingDots(total: 5, currentIndex: 0)),
              const SizedBox(height: 48),
              // 1. Icon
              const Center(
                child: Icon(
                  Icons.backpack_rounded, // Placeholder for RedBackpackIcon
                  size: 64,
                  color: AppColorTokens.danger, // backpack red
                ),
              ),
              const SizedBox(height: 40), // gap={40}

              // 2. Text Group (YStack gap={8})
              Column(
                children: const [
                  Text(
                    '欢迎使用 Backpack',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColorTokens.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w600, // $semiBold
                      fontFamily: 'Inter',
                      height: 1.2,
                      letterSpacing: -0.02,
                    ),
                  ),
                  SizedBox(height: 8), // gap={8}
                  Text(
                    '您将使用这个钱包来发送和接收加密资产及 NFT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColorTokens.textSecondary, // baseTextMedEmphasis
                      fontSize: 16, // base size
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),

              // 3. Button Group (YStack gap={16})
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: store.acceptedTerms,
                          onChanged: (v) => store.setAcceptedTerms(v ?? false),
                          activeColor: AppColorTokens.accent,
                          checkColor: Colors.white,
                          side: const BorderSide(color: AppColorTokens.borderLight),
                        ),
                        GestureDetector(
                          onTap: () => store.setAcceptedTerms(!store.acceptedTerms),
                          child: const Text(
                            '我同意 服务条款.',
                            style: TextStyle(
                              color: AppColorTokens.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: store.acceptedTerms
                          ? () {
                              store.resetCreateWalletFlow();
                              Navigator.pushNamed(context, WalletRoutes.replicaOnboardingNetworks);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorTokens.surfaceSubtle,
                        foregroundColor: AppColorTokens.textPrimary,
                        disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                        disabledForegroundColor: AppColorTokens.textMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                        elevation: 0,
                      ),
                      child: const Text('创建一个新钱包', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, WalletRoutes.replicaImportWallet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorTokens.surface,
                        foregroundColor: AppColorTokens.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                        elevation: 0,
                      ),
                      child: const Text('我已经有钱包', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
