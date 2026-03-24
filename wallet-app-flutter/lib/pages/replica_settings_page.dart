import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import 'replica_settings/replica_settings_store.dart';
import 'replica_settings/replica_settings_widgets.dart';

class ReplicaSettingsPage extends StatefulWidget {
  const ReplicaSettingsPage({super.key});

  @override
  State<ReplicaSettingsPage> createState() => _ReplicaSettingsPageState();
}

class _ReplicaSettingsPageState extends State<ReplicaSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsProvider(
      store: replicaSettingsStore,
      child: AnimatedBuilder(
        animation: replicaSettingsStore,
        builder: (context, _) {
          return ReplicaSettingsScaffold(
            title: 'Settings',
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AccountHeaderCard(
                  accountName: 'Account 1',
                  address: '0x71C...978b',
                  onCopy: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied (mock)')),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'Your Account',
                  children: [
                    ReplicaSettingsActionTile(
                      icon: Icons.person_outline,
                      title: 'Your Account',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsAccount),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'Wallets',
                  children: [
                    ReplicaSettingsActionTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallets',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsWallets),
                    ),
                    const ReplicaSettingsDivider(),
                    ReplicaSettingsActionTile(
                      icon: Icons.add_circle_outline,
                      title: 'Create Wallet',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.createWallet),
                    ),
                    const ReplicaSettingsDivider(),
                    ReplicaSettingsActionTile(
                      icon: Icons.file_download_outlined,
                      title: 'Import Wallet',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaImportWallet),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'Preferences',
                  children: [
                    ReplicaSettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      value: replicaSettingsStore.pushNotifications,
                      onChanged: replicaSettingsStore.togglePushNotifications,
                    ),
                    const ReplicaSettingsDivider(),
                    ReplicaSettingsSwitchTile(
                      icon: Icons.trending_up,
                      title: 'Price Alerts',
                      value: replicaSettingsStore.priceAlerts,
                      onChanged: replicaSettingsStore.togglePriceAlerts,
                    ),
                    const ReplicaSettingsDivider(),
                    ReplicaSettingsValueTile(
                      icon: Icons.attach_money,
                      title: 'Currency',
                      value: replicaSettingsStore.currency,
                      onTap: () {
                        replicaSettingsStore.setCurrency(
                          replicaSettingsStore.currency == 'USD' ? 'CNY' : 'USD',
                        );
                      },
                    ),
                    const ReplicaSettingsDivider(),
                    ReplicaSettingsActionTile(
                      icon: Icons.tune,
                      title: 'Preferences',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsPreferences),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'Features',
                  children: [
                    ReplicaSettingsActionTile(
                      icon: Icons.swap_horiz,
                      title: 'Swap',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.swapExchange),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'Security',
                  children: [
                    ReplicaSettingsActionTile(
                      icon: Icons.lock_outline,
                      title: 'Lock Wallet',
                      textColor: AppColorTokens.danger,
                      iconColor: AppColorTokens.danger,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wallet Locked (mock)')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ReplicaSettingsGroup(
                  title: 'About',
                  children: [
                    ReplicaSettingsActionTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsAbout),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Soulon v0.1.0+1',
                    style: TextStyle(color: AppColorTokens.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({
    required this.accountName,
    required this.address,
    required this.onCopy,
  });

  final String accountName;
  final String address;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4C94FF), Color(0xFF9F5AF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'A1',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    color: AppColorTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      address,
                      style: const TextStyle(color: AppColorTokens.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onCopy,
                      child: const Icon(Icons.copy_rounded, size: 14, color: AppColorTokens.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            color: AppColorTokens.textPrimary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR (mock)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
