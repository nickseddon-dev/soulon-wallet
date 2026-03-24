import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_import_widgets.dart';

final class ReplicaImportAccountsPage extends StatelessWidget {
  const ReplicaImportAccountsPage({super.key});

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
        title: const ReplicaProgressDots(total: 8, currentIndex: 5),
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
                '导入有余额的账户',
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
                '选择一个或多个有资产的账户进行导入',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.xl),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColorTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColorTokens.border),
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_outlined, color: AppColorTokens.textPrimary, size: 30),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '未找到有余额的账户',
                      style: TextStyle(color: AppColorTokens.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '你可以使用提供的助记词创建新钱包，或使用高级搜索',
                      style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, WalletRoutes.replicaOnboarding, (_) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorTokens.primary,
                          foregroundColor: AppColorTokens.primaryText,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                          elevation: 0,
                        ),
                        child: const Text('创建新钱包', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '高级',
                  style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.xl),
            ],
          ),
        ),
      ),
    );
  }
}

