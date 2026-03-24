import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

class ReplicaReceivePage extends StatelessWidget {
  const ReplicaReceivePage({super.key});

  static const String _address = 'QEF7NgbtJzWvzt17vWkNYK4Uq3zuiEsyj2xoPGSWCdU';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('充值', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadiusTokens.md),
                  ),
                  child: QrImageView(
                    data: _address,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _address,
                style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                width: 140,
                child: ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: _address));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制地址')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('复制地址', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '该地址只能接收Solana 上的资产。',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
