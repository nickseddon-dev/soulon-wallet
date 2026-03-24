import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_import_store.dart';
import 'replica_import_widgets.dart';

final class ReplicaImportMethodPage extends StatelessWidget {
  const ReplicaImportMethodPage({super.key});

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
        title: const ReplicaProgressDots(total: 8, currentIndex: 2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacingTokens.sm),
              Text(
                '导入${store.selectedBlockchain.label}钱包',
                style: const TextStyle(
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
                '选择导入方式',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.xl),
              ReplicaListRow(
                icon: Icons.format_list_numbered,
                title: '助记词',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaImportMnemonic),
              ),
              const SizedBox(height: 10),
              ReplicaListRow(
                icon: Icons.key_outlined,
                title: '私钥',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon'))),
              ),
              const SizedBox(height: 10),
              ReplicaListRow(
                icon: Icons.usb_rounded,
                title: '硬件钱包',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon'))),
              ),
              const SizedBox(height: 10),
              ReplicaListRow(
                icon: Icons.remove_red_eye_outlined,
                title: '只读钱包',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

