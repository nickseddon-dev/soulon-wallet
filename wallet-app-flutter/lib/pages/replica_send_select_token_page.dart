import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/app_icons.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class ReplicaSendSelectTokenPage extends StatefulWidget {
  const ReplicaSendSelectTokenPage({super.key});

  @override
  State<ReplicaSendSelectTokenPage> createState() => _ReplicaSendSelectTokenPageState();
}

class _ReplicaSendSelectTokenPageState extends State<ReplicaSendSelectTokenPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
        title: const Text('选择代币', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            children: [
              _SearchField(
                controller: _search,
                hint: '搜索代币名称或合约地址',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    _TokenItem(
                      title: 'Solana',
                      subtitle: '0 SOL',
                      onTap: () => Navigator.pushNamed(
                        context,
                        WalletRoutes.replicaSendRecipient,
                        arguments: const ReplicaSendRecipientArgs(symbol: 'SOL'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class ReplicaSendRecipientArgs {
  const ReplicaSendRecipientArgs({required this.symbol});

  final String symbol;
}

final class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
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
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColorTokens.textMuted),
          const SizedBox(width: 10),
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

final class _TokenItem extends StatelessWidget {
  const _TokenItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColorTokens.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
              child: Center(child: AppIcons.backpackLogo(color: AppColorTokens.textPrimary, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textMuted)),
                ],
              ),
            ),
            const Text('-', style: TextStyle(color: AppColorTokens.textMuted, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

