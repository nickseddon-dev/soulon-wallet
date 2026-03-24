import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import 'replica_settings_store.dart';
import 'replica_settings_widgets.dart';

final class ReplicaWalletsPage extends StatelessWidget {
  const ReplicaWalletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    return ReplicaSettingsScaffold(
      title: 'Wallets',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Your Wallets',
            children: [
              for (int i = 0; i < store.wallets.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.wallets[i].blockchain == ReplicaBlockchain.ethereum
                      ? Icons.currency_bitcoin
                      : Icons.bolt,
                  title: store.wallets[i].name,
                  subtitle: _shortKey(store.wallets[i].publicKey),
                  trailing: _ActivePill(active: store.wallets[i].isActive),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      WalletRoutes.replicaSettingsWalletDetail,
                      arguments: ReplicaWalletDetailArgs(
                        blockchain: store.wallets[i].blockchain,
                        publicKey: store.wallets[i].publicKey,
                        name: store.wallets[i].name,
                        type: store.wallets[i].type.label,
                        isActive: store.wallets[i].isActive,
                      ),
                    );
                  },
                ),
                if (i != store.wallets.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Add Wallet',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.add_circle_outline,
                title: 'Add Wallet',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletDetailPage extends StatelessWidget {
  const ReplicaWalletDetailPage({super.key, required this.args});

  final ReplicaWalletDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: args.name,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsPlaceholderCard(
            title: '${args.blockchain.label} • ${args.type}',
            description: 'Public Key: ${args.publicKey}',
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Actions',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.edit_outlined,
                title: 'Rename Wallet',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    WalletRoutes.replicaSettingsWalletRename,
                    arguments: ReplicaWalletRenameArgs(
                      blockchain: args.blockchain,
                      publicKey: args.publicKey,
                      name: args.name,
                    ),
                  );
                },
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.key_outlined,
                title: 'Show Private Key',
                onTap: () => Navigator.pushNamed(
                  context,
                  WalletRoutes.replicaSettingsShowRecoveryPhraseWarning,
                ),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.delete_outline,
                title: 'Remove Wallet',
                textColor: AppColorTokens.danger,
                iconColor: AppColorTokens.danger,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    WalletRoutes.replicaSettingsWalletRemove,
                    arguments: ReplicaWalletRemoveArgs(
                      blockchain: args.blockchain,
                      publicKey: args.publicKey,
                      type: args.type,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletRenamePage extends StatefulWidget {
  const ReplicaWalletRenamePage({super.key, required this.args});

  final ReplicaWalletRenameArgs args;

  @override
  State<ReplicaWalletRenamePage> createState() => _ReplicaWalletRenamePageState();
}

class _ReplicaWalletRenamePageState extends State<ReplicaWalletRenamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.args.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Rename Wallet',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsPlaceholderCard(
            title: widget.args.blockchain.label,
            description: 'Wallet: ${_shortKey(widget.args.publicKey)}',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: const TextStyle(color: AppColorTokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Wallet Name',
              labelStyle: const TextStyle(color: AppColorTokens.textSecondary),
              filled: true,
              fillColor: AppColorTokens.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColorTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColorTokens.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.primary,
              foregroundColor: AppColorTokens.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletRemovePage extends StatelessWidget {
  const ReplicaWalletRemovePage({super.key, required this.args});

  final ReplicaWalletRemoveArgs args;

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Remove Wallet',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsPlaceholderCard(
            title: '确认移除钱包',
            description: '该操作不可撤销。(${args.blockchain.label} • ${_shortKey(args.publicKey)})',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletRemoveConfirm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletRemoveConfirmPage extends StatelessWidget {
  const ReplicaWalletRemoveConfirmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Remove Wallet',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ReplicaSettingsPlaceholderCard(
            title: '钱包已移除（Mock）',
            description: '该页面为占位确认屏。返回后仍保留 mock 数据。',
          ),
        ),
      ),
    );
  }
}

final class ReplicaWalletAddPage extends StatelessWidget {
  const ReplicaWalletAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Add Wallet',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Choose Blockchain',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.bolt,
                title: 'Solana',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletAddBlockchainSelect),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.currency_bitcoin,
                title: 'Ethereum',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletAddBlockchainSelect),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletAddBlockchainSelectPage extends StatelessWidget {
  const ReplicaWalletAddBlockchainSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Select Flow',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Recovery Phrase',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.create_outlined,
                title: 'Create New Wallet',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletCreateMnemonic),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.file_download_outlined,
                title: 'Import Recovery Phrase',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletSetMnemonic),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Other',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.vpn_key_outlined,
                title: 'Import Private Key',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletAddPrivateKey),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.usb_outlined,
                title: 'Connect Hardware Wallet',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletAddHardware),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletCreateMnemonicPage extends StatelessWidget {
  const ReplicaWalletCreateMnemonicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Create Wallet',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ReplicaSettingsPlaceholderCard(
            title: '创建助记词（占位）',
            description: '这里仅提供 UI 占位，不生成真实助记词。',
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletSetMnemonicPage extends StatelessWidget {
  const ReplicaWalletSetMnemonicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Import Recovery Phrase',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ReplicaSettingsPlaceholderCard(
            title: '导入助记词（占位）',
            description: '这里仅提供 UI 占位，不读取/保存真实助记词。',
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletCreateOrImportMnemonicPage extends StatelessWidget {
  const ReplicaWalletCreateOrImportMnemonicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Create or Import',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Choose',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.create_outlined,
                title: 'Create Recovery Phrase',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletCreateMnemonic),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.file_download_outlined,
                title: 'Import Recovery Phrase',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWalletSetMnemonic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaWalletAddBackpackRecoveryPhrasePage extends StatelessWidget {
  const ReplicaWalletAddBackpackRecoveryPhrasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Add Backpack Recovery Phrase',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: 'Backpack 助记词（占位）',
          description: '用于导入 Backpack 恢复短语的占位页面。',
        ),
      ),
    );
  }
}

final class ReplicaWalletAddDeriveRecoveryPhrasePage extends StatelessWidget {
  const ReplicaWalletAddDeriveRecoveryPhrasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Derive Wallets',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: '派生钱包（占位）',
          description: '用于从助记词派生更多地址的占位页面。',
        ),
      ),
    );
  }
}

final class ReplicaWalletAddPrivateKeyPage extends StatelessWidget {
  const ReplicaWalletAddPrivateKeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Import Private Key',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: '导入私钥（占位）',
          description: '敏感内容不在 mock 中处理，仅提供流程占位。',
        ),
      ),
    );
  }
}

final class ReplicaWalletAddHardwarePage extends StatelessWidget {
  const ReplicaWalletAddHardwarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Hardware Wallet',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: '连接硬件钱包（占位）',
          description: '此处仅复刻 UI 入口，不做真实硬件连接。',
        ),
      ),
    );
  }
}

final class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const Icon(Icons.chevron_right, color: AppColorTokens.textSecondary, size: 20);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorTokens.accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColorTokens.borderLight),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          color: AppColorTokens.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _shortKey(String value) {
  if (value.length <= 12) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
}

