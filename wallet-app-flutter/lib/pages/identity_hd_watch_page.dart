import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/identity_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class IdentityHdWatchPage extends StatefulWidget {
  const IdentityHdWatchPage({super.key});

  @override
  State<IdentityHdWatchPage> createState() => _IdentityHdWatchPageState();
}

class _IdentityHdWatchPageState extends State<IdentityHdWatchPage> {
  final IdentityDemoStore _store = IdentityDemoStore.instance;
  final TextEditingController _watchLabelController = TextEditingController();
  final TextEditingController _watchAddressController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _watchLabelController.dispose();
    _watchAddressController.dispose();
    super.dispose();
  }

  void _addHdAccount() {
    setState(() => _errorText = null);
    try {
      _store.addHdAccount();
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  void _addWatchWallet() {
    setState(() => _errorText = null);
    try {
      _store.addWatchWallet(
        label: _watchLabelController.text,
        address: _watchAddressController.text,
      );
      _watchLabelController.clear();
      _watchAddressController.clear();
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentityDemoState>(
      valueListenable: _store,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('HD 账户与观察者钱包')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: 'HD 账户',
                trailing: Text(
                  '${state.hdAccounts.length} 个',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColorTokens.accent,
                      ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletPrimaryButton(label: '派生下一个账户', onPressed: _addHdAccount),
                    const SizedBox(height: 12),
                    if (state.hdAccounts.isEmpty)
                      const Text('暂无账户，请先生成或恢复助记词后派生。'),
                    for (final account in state.hdAccounts) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColorTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(account.path),
                            const SizedBox(height: 4),
                            Text(account.address),
                            const SizedBox(height: 4),
                            Text('余额: ${account.balance}'),
                            const SizedBox(height: 8),
                            const Chip(label: Text('可签名')),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '观察者钱包',
                trailing: Text(
                  '${state.watchWallets.length} 个',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColorTokens.warning,
                      ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletTextField(
                      label: '钱包名称',
                      hintText: '例如：交易观察账户',
                      controller: _watchLabelController,
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '只读地址',
                      hintText: 'cosmos1...',
                      controller: _watchAddressController,
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(label: '添加观察地址', onPressed: _addWatchWallet),
                    const SizedBox(height: 12),
                    if (state.watchWallets.isEmpty) const Text('暂无观察者钱包。'),
                    for (final wallet in state.watchWallets) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColorTokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColorTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(wallet.address),
                            const SizedBox(height: 8),
                            const Chip(
                              label: Text('只读模式'),
                              avatar: Icon(Icons.visibility_outlined, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColorTokens.danger,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              WalletPrimaryButton(
                label: '进入助记词备份校验',
                onPressed: () => Navigator.pushNamed(context, WalletRoutes.identityBackupVerify),
              ),
            ],
          ),
        );
      },
    );
  }
}
