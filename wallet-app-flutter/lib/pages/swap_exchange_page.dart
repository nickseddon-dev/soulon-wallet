import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';
import '../widgets/replica_wallet_bottom_nav.dart';

class SwapExchangePage extends StatefulWidget {
  const SwapExchangePage({super.key});

  @override
  State<SwapExchangePage> createState() => _SwapExchangePageState();
}

class _SwapExchangePageState extends State<SwapExchangePage> {
  final TextEditingController _amountController = TextEditingController();
  String _fromAsset = 'SOL';
  String _toAsset = 'USDC';
  int _mode = 0;
  final TextEditingController _toAmountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _amountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: AppColorTokens.background,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettings),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColorTokens.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('A1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        title: _SwapHeaderTitle(walletName: 'Wallet 1', onCopy: () {}),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: AppColorTokens.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacingTokens.xl),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColorTokens.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeTab(label: '兑换', selected: _mode == 0, onTap: () => setState(() => _mode = 0)),
                  const SizedBox(width: 6),
                  _ModeTab(label: '跨链', selected: _mode == 1, onTap: () => setState(() => _mode = 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacingTokens.xl),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorTokens.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColorTokens.border),
            ),
            child: Column(
              children: [
                _SwapRow(
                  title: '卖',
                  balanceLabel: '余额: 0.0 SOL',
                  amountController: _amountController,
                  token: _fromAsset,
                  tokens: const ['SOL', 'ETH', 'USDC'],
                  onTokenChanged: (v) => setState(() => _fromAsset = v),
                  chips: const ['25%', '50%'],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColorTokens.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColorTokens.border),
                    ),
                    child: const Icon(Icons.swap_vert, color: AppColorTokens.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                _SwapRow(
                  title: '买',
                  balanceLabel: '余额: 0.0',
                  amountController: _toAmountController,
                  token: _toAsset,
                  tokens: const ['USDC', 'USDT', 'SOL'],
                  onTokenChanged: (v) => setState(() => _toAsset = v),
                  chips: const [],
                  readOnlyAmount: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacingTokens.xl),
          Row(
            children: [
              Text('热门代币', style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Icon(Icons.trending_up, size: 18, color: AppColorTokens.textMuted),
              const Spacer(),
              const Icon(Icons.arrow_downward, size: 18, color: AppColorTokens.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          _HotTokenRow(title: 'BIAO', subtitle: 'BIAO', price: r'$0.03328', change: '+144.19%'),
          const SizedBox(height: 8),
          _HotTokenRow(title: 'Project89', subtitle: 'PROJECT89', price: r'$0.48989', change: '+64.57%'),
        ],
      ),
      bottomNavigationBar: ReplicaWalletBottomNav(
        selectedIndex: 1,
        onSelected: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, WalletRoutes.replicaMobileHome);
          if (index == 2) Navigator.pushReplacementNamed(context, WalletRoutes.replicaExplore);
        },
      ),
    );
  }
}

final class _SwapHeaderTitle extends StatelessWidget {
  const _SwapHeaderTitle({required this.walletName, required this.onCopy});

  final String walletName;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.bolt, size: 12, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Text(walletName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColorTokens.textSecondary),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColorTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

final class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColorTokens.surfaceSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColorTokens.borderLight : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColorTokens.textPrimary : AppColorTokens.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.title,
    required this.balanceLabel,
    required this.amountController,
    required this.token,
    required this.tokens,
    required this.onTokenChanged,
    required this.chips,
    this.readOnlyAmount = false,
  });

  final String title;
  final String balanceLabel;
  final TextEditingController amountController;
  final String token;
  final List<String> tokens;
  final ValueChanged<String> onTokenChanged;
  final List<String> chips;
  final bool readOnlyAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(balanceLabel, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  enabled: !readOnlyAmount,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColorTokens.textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                ),
              ),
              const SizedBox(width: 12),
              _TokenPill(token: token, tokens: tokens, onChanged: onTokenChanged),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final c in chips) ...[
                  _Chip(label: c),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

final class _TokenPill extends StatelessWidget {
  const _TokenPill({required this.token, required this.tokens, required this.onChanged});

  final String token;
  final List<String> tokens;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: token,
          dropdownColor: AppColorTokens.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColorTokens.textSecondary),
          items: tokens.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}

final class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Text(label, style: const TextStyle(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

final class _HotTokenRow extends StatelessWidget {
  const _HotTokenRow({required this.title, required this.subtitle, required this.price, required this.change});

  final String title;
  final String subtitle;
  final String price;
  final String change;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColorTokens.surfaceSubtle, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.face, size: 18, color: AppColorTokens.textPrimary)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(change, style: AppTypographyTokens.label.copyWith(color: AppColorTokens.success, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColorTokens.textMuted),
        ],
      ),
    );
  }
}
