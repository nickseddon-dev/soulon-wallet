import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import 'replica_settings_store.dart';
import 'replica_settings_widgets.dart';

final class ReplicaPreferencesPage extends StatelessWidget {
  const ReplicaPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    return ReplicaSettingsScaffold(
      title: 'Preferences',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'General',
            children: [
              ReplicaSettingsValueTile(
                icon: Icons.lock_clock_outlined,
                title: 'Auto Lock Timer',
                value: store.autoLockTimer,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesAutolock),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsValueTile(
                icon: Icons.language,
                title: 'Language',
                value: store.language,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesLanguage),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.visibility_off_outlined,
                title: 'Hidden Tokens',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesHiddenTokens),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.verified_user_outlined,
                title: 'Trusted Sites',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesTrustedSites),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Blockchain',
            children: [
              ReplicaSettingsValueTile(
                icon: Icons.link,
                title: 'Blockchain',
                value: store.defaultBlockchain.label,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesBlockchain),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesAutolockPage extends StatelessWidget {
  const ReplicaPreferencesAutolockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    final options = const ['1 minute', '5 minutes', '10 minutes', '30 minutes', '1 hour'];
    return ReplicaSettingsScaffold(
      title: 'Auto Lock Timer',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Timer',
            children: [
              for (int i = 0; i < options.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.autoLockTimer == options[i] ? Icons.check_circle : Icons.circle_outlined,
                  title: options[i],
                  trailing: const SizedBox(width: 20),
                  onTap: () {
                    store.setAutoLockTimer(options[i]);
                    Navigator.pop(context);
                  },
                ),
                if (i != options.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesTrustedSitesPage extends StatelessWidget {
  const ReplicaPreferencesTrustedSitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Trusted Sites',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: 'Trusted Sites（占位）',
          description: '此处展示已授权站点列表、移除授权等操作（mock）。',
        ),
      ),
    );
  }
}

final class ReplicaPreferencesLanguagePage extends StatelessWidget {
  const ReplicaPreferencesLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    final options = const ['English', '中文'];
    return ReplicaSettingsScaffold(
      title: 'Language',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Select',
            children: [
              for (int i = 0; i < options.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.language == options[i] ? Icons.check_circle : Icons.circle_outlined,
                  title: options[i],
                  trailing: const SizedBox(width: 20),
                  onTap: () {
                    store.setLanguage(options[i]);
                    Navigator.pop(context);
                  },
                ),
                if (i != options.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesHiddenTokensPage extends StatelessWidget {
  const ReplicaPreferencesHiddenTokensPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReplicaSettingsScaffold(
      title: 'Hidden Tokens',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ReplicaSettingsPlaceholderCard(
          title: 'Hidden Tokens（占位）',
          description: '此处展示隐藏 Token 列表并支持恢复显示（mock）。',
        ),
      ),
    );
  }
}

final class ReplicaPreferencesBlockchainPage extends StatelessWidget {
  const ReplicaPreferencesBlockchainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    return ReplicaSettingsScaffold(
      title: store.defaultBlockchain.label,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Blockchain',
            children: [
              ReplicaSettingsActionTile(
                icon: store.defaultBlockchain == ReplicaBlockchain.solana ? Icons.check_circle : Icons.circle_outlined,
                title: 'Solana',
                trailing: const SizedBox(width: 20),
                onTap: () => store.setDefaultBlockchain(ReplicaBlockchain.solana),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: store.defaultBlockchain == ReplicaBlockchain.ethereum ? Icons.check_circle : Icons.circle_outlined,
                title: 'Ethereum',
                trailing: const SizedBox(width: 20),
                onTap: () => store.setDefaultBlockchain(ReplicaBlockchain.ethereum),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Connection',
            children: [
              ReplicaSettingsValueTile(
                icon: Icons.settings_ethernet_outlined,
                title: 'RPC Connection',
                value: store.rpcConnection,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesRpcConnection),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsValueTile(
                icon: Icons.check_circle_outline,
                title: 'Commitment',
                value: store.commitment,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesCommitment),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsValueTile(
                icon: Icons.open_in_new,
                title: 'Explorer',
                value: store.explorer,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesExplorer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesRpcConnectionPage extends StatelessWidget {
  const ReplicaPreferencesRpcConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    final options = const ['Default', 'Custom'];
    return ReplicaSettingsScaffold(
      title: 'RPC Connection',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Select',
            children: [
              for (int i = 0; i < options.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.rpcConnection == options[i] ? Icons.check_circle : Icons.circle_outlined,
                  title: options[i],
                  trailing: const SizedBox(width: 20),
                  onTap: () {
                    store.setRpcConnection(options[i]);
                    if (options[i] == 'Custom') {
                      Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferencesRpcCustom);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                if (i != options.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesRpcCustomPage extends StatefulWidget {
  const ReplicaPreferencesRpcCustomPage({super.key});

  @override
  State<ReplicaPreferencesRpcCustomPage> createState() => _ReplicaPreferencesRpcCustomPageState();
}

class _ReplicaPreferencesRpcCustomPageState extends State<ReplicaPreferencesRpcCustomPage> {
  TextEditingController? _controller;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final store = ReplicaSettingsProvider.of(context);
    _controller = TextEditingController(text: store.rpcCustomUrl);
    _initialized = true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _save() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.text.trim();
    if (value.isEmpty || !value.startsWith('http')) {
      setState(() => _error = '请输入有效 URL（http/https）');
      return;
    }
    final store = ReplicaSettingsProvider.of(context);
    store.setRpcCustomUrl(value);
    Navigator.popUntil(context, (route) => route.settings.name == WalletRoutes.replicaSettingsPreferencesBlockchain);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ReplicaSettingsScaffold(
      title: 'Custom RPC',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: AppColorTokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'RPC URL',
              labelStyle: const TextStyle(color: AppColorTokens.textSecondary),
              filled: true,
              fillColor: AppColorTokens.surface,
              errorText: _error,
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
            onPressed: _save,
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

final class ReplicaPreferencesCommitmentPage extends StatelessWidget {
  const ReplicaPreferencesCommitmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    final options = const ['Processed', 'Confirmed', 'Finalized'];
    return ReplicaSettingsScaffold(
      title: 'Commitment',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Select',
            children: [
              for (int i = 0; i < options.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.commitment == options[i] ? Icons.check_circle : Icons.circle_outlined,
                  title: options[i],
                  trailing: const SizedBox(width: 20),
                  onTap: () {
                    store.setCommitment(options[i]);
                    Navigator.pop(context);
                  },
                ),
                if (i != options.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaPreferencesExplorerPage extends StatelessWidget {
  const ReplicaPreferencesExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReplicaSettingsProvider.of(context);
    final options = const ['Solana Explorer', 'Solscan', 'SolanaFM'];
    return ReplicaSettingsScaffold(
      title: 'Explorer',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReplicaSettingsGroup(
            title: 'Select',
            children: [
              for (int i = 0; i < options.length; i++) ...[
                ReplicaSettingsActionTile(
                  icon: store.explorer == options[i] ? Icons.check_circle : Icons.circle_outlined,
                  title: options[i],
                  trailing: const SizedBox(width: 20),
                  onTap: () {
                    store.setExplorer(options[i]);
                    Navigator.pop(context);
                  },
                ),
                if (i != options.length - 1) const ReplicaSettingsDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
