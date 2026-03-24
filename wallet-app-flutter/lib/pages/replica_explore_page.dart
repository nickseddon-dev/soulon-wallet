import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';
import '../widgets/replica_wallet_bottom_nav.dart';

final class ReplicaExplorePage extends StatelessWidget {
  const ReplicaExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: AppColorTokens.background,
        elevation: 0,
        title: const Text('探索', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
        ),
      ),
      bottomNavigationBar: ReplicaWalletBottomNav(
        selectedIndex: 2,
        onSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, WalletRoutes.replicaMobileHome);
          }
          if (index == 1) {
            Navigator.pushReplacementNamed(context, WalletRoutes.swapExchange);
          }
        },
      ),
    );
  }
}

