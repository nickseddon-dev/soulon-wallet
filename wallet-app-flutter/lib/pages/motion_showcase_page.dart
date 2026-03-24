import 'package:flutter/material.dart';

import '../theme/tokens/app_motion_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class MotionShowcasePage extends StatefulWidget {
  const MotionShowcasePage({super.key});

  @override
  State<MotionShowcasePage> createState() => _MotionShowcasePageState();
}

class _MotionShowcasePageState extends State<MotionShowcasePage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('动效令牌与封装')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WalletCard(
            title: '状态切换',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppMotionTokens.normal,
                  curve: AppMotionTokens.emphasized,
                  height: _expanded ? 160 : 88,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 12),
                WalletPrimaryButton(
                  label: _expanded ? '收起' : '展开',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
