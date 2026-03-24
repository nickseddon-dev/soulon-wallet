import 'package:flutter/material.dart';

import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class ReplicaSendAmountArgs {
  const ReplicaSendAmountArgs({
    required this.symbol,
    required this.recipient,
  });

  final String symbol;
  final String recipient;
}

final class ReplicaSendAmountPage extends StatefulWidget {
  const ReplicaSendAmountPage({super.key, required this.args});

  final ReplicaSendAmountArgs args;

  @override
  State<ReplicaSendAmountPage> createState() => _ReplicaSendAmountPageState();
}

class _ReplicaSendAmountPageState extends State<ReplicaSendAmountPage> {
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  bool get _canNext => (_amount.text.trim().isNotEmpty);

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
        title: const Text('发送', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          children: [
            Text('代币', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
            const SizedBox(height: 8),
            Text(widget.args.symbol, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text('接收地址', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
            const SizedBox(height: 8),
            Text(widget.args.recipient, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Text('金额', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
            const SizedBox(height: 8),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w600),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canNext ? () => Navigator.pop(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorTokens.surfaceSubtle,
                foregroundColor: AppColorTokens.textPrimary,
                disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                disabledForegroundColor: AppColorTokens.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                elevation: 0,
              ),
              child: const Text('下一步', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

