import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_import_store.dart';
import 'replica_import_widgets.dart';

final class ReplicaImportSelectBlockchainPage extends StatelessWidget {
  const ReplicaImportSelectBlockchainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaImportProvider.of(context);
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const ReplicaProgressDots(total: 8, currentIndex: 1),
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
                '选择公链',
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
                '您可以随时添加和移除网络。',
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
                      _Grid(
                        items: const [
                          ReplicaImportBlockchain.solana,
                          ReplicaImportBlockchain.ethereum,
                          ReplicaImportBlockchain.sui,
                          ReplicaImportBlockchain.aptos,
                          ReplicaImportBlockchain.base,
                          ReplicaImportBlockchain.monad,
                          ReplicaImportBlockchain.sei,
                          ReplicaImportBlockchain.hyperEvm,
                          ReplicaImportBlockchain.bnb,
                        ],
                        selected: store.selectedBlockchain,
                        onSelect: store.selectBlockchain,
                      ),
                      const SizedBox(height: AppSpacingTokens.lg),
                      Center(
                        child: Text('更多', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: AppSpacingTokens.md),
                      _Grid(
                        items: const [
                          ReplicaImportBlockchain.arbitrum,
                          ReplicaImportBlockchain.eclipse,
                        ],
                        selected: store.selectedBlockchain,
                        onSelect: store.selectBlockchain,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, WalletRoutes.replicaImportMethod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.surfaceSubtle,
                    foregroundColor: AppColorTokens.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('继续', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

final class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<ReplicaImportBlockchain> items;
  final ReplicaImportBlockchain selected;
  final ValueChanged<ReplicaImportBlockchain> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 2;
        final itemWidth = (constraints.maxWidth - (columns - 1) * AppSpacingTokens.md) / columns;
        return Wrap(
          spacing: AppSpacingTokens.md,
          runSpacing: AppSpacingTokens.md,
          children: [
            for (final chain in items)
              SizedBox(
                width: itemWidth,
                child: _ChainItem(
                  chain: chain,
                  selected: chain == selected,
                  onTap: () => onSelect(chain),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _ChainItem extends StatelessWidget {
  const _ChainItem({
    required this.chain,
    required this.selected,
    required this.onTap,
  });

  final ReplicaImportBlockchain chain;
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Icon(_iconFor(chain), color: AppColorTokens.textPrimary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chain.label,
                style: const TextStyle(
                  color: AppColorTokens.textPrimary,
                  fontWeight: FontWeight.w800,
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

IconData _iconFor(ReplicaImportBlockchain chain) {
  switch (chain) {
    case ReplicaImportBlockchain.solana:
      return Icons.bolt;
    case ReplicaImportBlockchain.ethereum:
      return Icons.currency_bitcoin;
    case ReplicaImportBlockchain.sui:
      return Icons.water_drop_outlined;
    case ReplicaImportBlockchain.aptos:
      return Icons.blur_on;
    case ReplicaImportBlockchain.base:
      return Icons.layers_outlined;
    case ReplicaImportBlockchain.monad:
      return Icons.change_circle_outlined;
    case ReplicaImportBlockchain.sei:
      return Icons.waves_outlined;
    case ReplicaImportBlockchain.hyperEvm:
      return Icons.hub_outlined;
    case ReplicaImportBlockchain.bnb:
      return Icons.grid_view;
    case ReplicaImportBlockchain.arbitrum:
      return Icons.all_inclusive;
    case ReplicaImportBlockchain.eclipse:
      return Icons.brightness_3_outlined;
  }
}

