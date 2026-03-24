import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_onboarding_store.dart';
import 'replica_onboarding_widgets.dart';

final class ReplicaOnboardingNetworksPage extends StatelessWidget {
  const ReplicaOnboardingNetworksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaOnboardingProvider.of(context);
    final selectedCount = store.selectedNetworks.length;

    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ReplicaOnboardingDots(total: 5, currentIndex: 1),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacingTokens.sm),
              const Text(
                '请选择一个或多个网络',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColorTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.sm),
              Text(
                '您之后可以随时更改。',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('热门', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
                      const SizedBox(height: AppSpacingTokens.md),
                      _NetworkGrid(
                        children: const [
                          ReplicaOnboardingNetwork.solana,
                          ReplicaOnboardingNetwork.ethereum,
                          ReplicaOnboardingNetwork.sui,
                          ReplicaOnboardingNetwork.aptos,
                          ReplicaOnboardingNetwork.base,
                          ReplicaOnboardingNetwork.monad,
                          ReplicaOnboardingNetwork.sei,
                          ReplicaOnboardingNetwork.hyperEvm,
                          ReplicaOnboardingNetwork.bnb,
                        ],
                      ),
                      const SizedBox(height: AppSpacingTokens.lg),
                      Center(
                        child: Text(
                          '更多',
                          style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () => Navigator.pushNamed(context, WalletRoutes.replicaOnboardingPassword),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.surfaceSubtle,
                    foregroundColor: AppColorTokens.textPrimary,
                    disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                    disabledForegroundColor: AppColorTokens.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('选择网络', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

final class _NetworkGrid extends StatelessWidget {
  const _NetworkGrid({required this.children});

  final List<ReplicaOnboardingNetwork> children;

  @override
  Widget build(BuildContext context) {
    final store = ReplicaOnboardingProvider.of(context);
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 520 ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * AppSpacingTokens.md) / columns;
        return Wrap(
          spacing: AppSpacingTokens.md,
          runSpacing: AppSpacingTokens.md,
          children: [
            for (final network in children)
              SizedBox(
                width: itemWidth,
                child: _NetworkItem(
                  network: network,
                  selected: store.selectedNetworks.contains(network),
                  onTap: () => store.toggleNetwork(network),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _NetworkItem extends StatelessWidget {
  const _NetworkItem({
    required this.network,
    required this.selected,
    required this.onTap,
  });

  final ReplicaOnboardingNetwork network;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColorTokens.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColorTokens.accent : AppColorTokens.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColorTokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Icon(_iconFor(network), color: AppColorTokens.textPrimary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                network.label,
                style: const TextStyle(
                  color: AppColorTokens.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
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

