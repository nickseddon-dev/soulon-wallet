import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../state/identity_demo_store.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_onboarding_store.dart';
import 'replica_onboarding_widgets.dart';

final class ReplicaOnboardingSetupWalletPage extends StatefulWidget {
  const ReplicaOnboardingSetupWalletPage({super.key});

  @override
  State<ReplicaOnboardingSetupWalletPage> createState() => _ReplicaOnboardingSetupWalletPageState();
}

class _ReplicaOnboardingSetupWalletPageState extends State<ReplicaOnboardingSetupWalletPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _runSetup();
  }

  Future<void> _runSetup() async {
    final identity = IdentityDemoStore.instance;

    await Future.delayed(const Duration(milliseconds: 650));
    try {
      identity.generateMnemonic(wordCount: 12);
      identity.addHdAccount();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, WalletRoutes.replicaOnboardingFinish);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReplicaOnboardingProvider.of(context);
    final primary = store.selectedNetworks.isEmpty ? null : store.selectedNetworks.first;

    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ReplicaOnboardingDots(total: 5, currentIndex: 3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColorTokens.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorTokens.border),
                  ),
                  child: Icon(
                    primary == null ? Icons.backpack_rounded : _iconFor(primary),
                    color: AppColorTokens.danger,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacingTokens.xl),
                const Text(
                  '正在设置您的钱包…',
                  style: TextStyle(
                    fontFamily: AppTypographyTokens.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColorTokens.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacingTokens.lg),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColorTokens.accent),
                    backgroundColor: AppColorTokens.surfaceSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(ReplicaOnboardingNetwork network) {
  switch (network) {
    case ReplicaOnboardingNetwork.solana:
      return Icons.bolt;
    case ReplicaOnboardingNetwork.ethereum:
      return Icons.currency_bitcoin;
    case ReplicaOnboardingNetwork.sui:
      return Icons.water_drop_outlined;
    case ReplicaOnboardingNetwork.aptos:
      return Icons.blur_on;
    case ReplicaOnboardingNetwork.base:
      return Icons.layers_outlined;
    case ReplicaOnboardingNetwork.monad:
      return Icons.change_circle_outlined;
    case ReplicaOnboardingNetwork.sei:
      return Icons.waves_outlined;
    case ReplicaOnboardingNetwork.hyperEvm:
      return Icons.hub_outlined;
    case ReplicaOnboardingNetwork.bnb:
      return Icons.grid_view;
  }
}
