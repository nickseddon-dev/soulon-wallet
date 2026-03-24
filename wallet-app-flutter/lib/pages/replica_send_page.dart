import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';
import '../app/app_router.dart';
import 'replica_send_select_token_page.dart';
import 'replica_send_amount_page.dart';

class ReplicaSendPage extends StatefulWidget {
  const ReplicaSendPage({super.key, this.args});

  final ReplicaSendRecipientArgs? args;

  @override
  State<ReplicaSendPage> createState() => _ReplicaSendPageState();
}

class _ReplicaSendPageState extends State<ReplicaSendPage> {
  final TextEditingController _recipientController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  bool get _canNext => _recipientController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final symbol = widget.args?.symbol ?? 'SOL';
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
            _TextBox(
              hint: '输入地址',
              controller: _recipientController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text('你的地址', style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
            const SizedBox(height: 10),
            _MyAddressRow(
              badge: 'A1',
              accountName: 'Account 1',
              walletName: 'Wallet 1',
              address: '6sqY...vt3M',
              walletCount: '1 钱包',
              onTap: () => setState(() => _recipientController.text = '6sqY...vt3M'),
              symbol: symbol,
            ),
            const SizedBox(height: 10),
            _MyAddressRow(
              badge: 'A2',
              accountName: 'Account 2',
              walletName: 'Wallet 1',
              address: '8yVc...Kynx',
              walletCount: '1 钱包',
              onTap: () => setState(() => _recipientController.text = '8yVc...Kynx'),
              symbol: symbol,
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
              onPressed: _canNext
                  ? () {
                      Navigator.pushNamed(
                        context,
                        WalletRoutes.replicaSendAmount,
                        arguments: ReplicaSendAmountArgs(
                          symbol: symbol,
                          recipient: _recipientController.text.trim(),
                        ),
                      );
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
              child: const Text('下一步', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

final class _MyAddressRow extends StatelessWidget {
  const _MyAddressRow({
    required this.badge,
    required this.accountName,
    required this.walletName,
    required this.address,
    required this.walletCount,
    required this.onTap,
    required this.symbol,
  });

  final String badge;
  final String accountName;
  final String walletName;
  final String address;
  final String walletCount;
  final VoidCallback onTap;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColorTokens.surface,
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          border: Border.all(color: AppColorTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
                  child: Center(child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(accountName, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800))),
                Text(walletCount, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
                  child: Center(child: AppIcons.backpackLogo(color: AppColorTokens.textPrimary, size: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(walletName, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(address, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
