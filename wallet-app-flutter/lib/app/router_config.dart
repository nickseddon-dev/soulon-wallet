import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/component_showcase_page.dart';
import '../pages/asset_dashboard_page.dart';
import '../pages/identity_backup_verify_page.dart';
import '../pages/ibc_transfer_tracking_page.dart';
import '../pages/identity_hd_watch_page.dart';
import '../pages/identity_mnemonic_page.dart';
import '../pages/motion_showcase_page.dart';
import '../pages/multisig_approval_page.dart';
import '../pages/notification_center_page.dart';
import '../pages/notification_detail_page.dart';
import '../pages/offline_signature_import_page.dart';
import '../pages/governance_vote_page.dart';
import '../pages/pin_biometric_confirm_page.dart';
import '../pages/replica_asset_detail_page.dart';
import '../pages/replica_explore_page.dart';
import '../pages/replica_mobile_home_page.dart';
import '../pages/replica_onboarding_entry_page.dart';
import '../pages/replica_receive_page.dart';
import '../pages/replica_security_confirm_page.dart';
import '../pages/replica_send_page.dart';
import '../pages/replica_send_amount_page.dart';
import '../pages/replica_send_select_token_page.dart';
import '../pages/replica_import/replica_import_accounts_page.dart';
import '../pages/replica_import/replica_import_discovering_page.dart';
import '../pages/replica_import/replica_import_method_page.dart';
import '../pages/replica_import/replica_import_mnemonic_page.dart';
import '../pages/replica_import/replica_import_select_blockchain_page.dart';
import '../pages/replica_import/replica_import_store.dart';
import '../pages/replica_onboarding/replica_onboarding_finish_page.dart';
import '../pages/replica_onboarding/replica_onboarding_networks_page.dart';
import '../pages/replica_onboarding/replica_onboarding_password_page.dart';
import '../pages/replica_onboarding/replica_onboarding_setup_wallet_page.dart';
import '../pages/replica_onboarding/replica_onboarding_store.dart';
import '../pages/replica_settings_page.dart';
import '../pages/replica_settings/about_page.dart';
import '../pages/replica_settings/preferences_pages.dart';
import '../pages/replica_settings/replica_settings_store.dart';
import '../pages/replica_settings/wallets_pages.dart';
import '../pages/replica_settings/your_account_pages.dart';
import '../pages/staking_flow_page.dart';
import '../pages/suggest_chain_scan_reorg_page.dart';
import '../pages/swap_exchange_page.dart';
import '../pages/transaction_flow_page.dart';
import '../pages/transaction_history_export_page.dart';
import '../pages/walletconnect_session_page.dart';
import '../pages/ovd_auth_login_page.dart';
import '../pages/ovd_auth_register_page.dart';
import '../pages/ovd_launcher_page.dart';
import '../pages/ovd_placeholder_page.dart';
import '../pages/global_search_page.dart';
import 'app_router.dart' show WalletRoutes;

Page<void> _fadeSlide(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

Page<void> _fadeScale(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

Widget _withSettingsProvider(Widget child) {
  return ReplicaSettingsProvider(store: replicaSettingsStore, child: child);
}

Widget _withOnboardingProvider(Widget child) {
  return ReplicaOnboardingProvider(store: replicaOnboardingStore, child: child);
}

Widget _withImportProvider(Widget child) {
  return ReplicaImportProvider(store: replicaImportStore, child: child);
}

final GoRouter appRouter = GoRouter(
  initialLocation: WalletRoutes.ovdAuthLogin,
  routes: [
    // --- OVD Auth ---
    GoRoute(
      path: WalletRoutes.ovdAuthLogin,
      pageBuilder: (context, state) => _fadeSlide(const OvdAuthLoginPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.ovdAuthRegister,
      pageBuilder: (context, state) => _fadeSlide(const OvdAuthRegisterPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.ovdLauncher,
      pageBuilder: (context, state) => _fadeSlide(
        Builder(
          builder: (context) {
            return OvdLauncherPage(
              onClose: () => context.pop(),
              onDeposit: () => context.push(WalletRoutes.replicaReceive),
              onWithdraw: () => context.push(WalletRoutes.replicaSend),
              onSwap: () => context.push(WalletRoutes.swapExchange),
              onOpenTavern: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Tavern'))),
              onOpenVault: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Vault'))),
              onOpenBazaar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Bazaar'))),
              onOpenLab: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Lab'))),
            );
          },
        ),
        state,
      ),
    ),

    // --- Foundation ---
    GoRoute(
      path: WalletRoutes.components,
      pageBuilder: (context, state) => _fadeSlide(const ComponentShowcasePage(), state),
    ),
    GoRoute(
      path: WalletRoutes.motion,
      pageBuilder: (context, state) => _fadeSlide(const MotionShowcasePage(), state),
    ),

    // --- Identity ---
    GoRoute(
      path: WalletRoutes.identityMnemonic,
      pageBuilder: (context, state) => _fadeSlide(const IdentityMnemonicPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.createWallet,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingNetworksPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.identityHd,
      pageBuilder: (context, state) => _fadeSlide(const IdentityHdWatchPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.identityBackupVerify,
      pageBuilder: (context, state) => _fadeScale(const IdentityBackupVerifyPage(), state),
    ),

    // --- Asset ---
    GoRoute(
      path: WalletRoutes.assetDashboard,
      pageBuilder: (context, state) => _fadeSlide(const AssetDashboardPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.transactionFlow,
      pageBuilder: (context, state) => _fadeSlide(const TransactionFlowPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.transactionHistoryExport,
      pageBuilder: (context, state) => _fadeSlide(const TransactionHistoryExportPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.swapExchange,
      pageBuilder: (context, state) => _fadeSlide(const SwapExchangePage(), state),
    ),

    // --- Interop ---
    GoRoute(
      path: WalletRoutes.stakingFlow,
      pageBuilder: (context, state) => _fadeSlide(const StakingFlowPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.governanceVote,
      pageBuilder: (context, state) => _fadeSlide(const GovernanceVotePage(), state),
    ),
    GoRoute(
      path: WalletRoutes.ibcTransferTracking,
      pageBuilder: (context, state) => _fadeSlide(const IbcTransferTrackingPage(), state),
    ),

    // --- Security ---
    GoRoute(
      path: WalletRoutes.pinBiometricConfirm,
      pageBuilder: (context, state) => _fadeSlide(const PinBiometricConfirmPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.walletConnectSession,
      pageBuilder: (context, state) => _fadeSlide(const WalletConnectSessionPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.suggestChainScanReorg,
      pageBuilder: (context, state) => _fadeSlide(const SuggestChainScanReorgPage(), state),
    ),

    // --- Notification ---
    GoRoute(
      path: WalletRoutes.notificationCenter,
      pageBuilder: (context, state) => _fadeSlide(const NotificationCenterPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.notificationDetail,
      pageBuilder: (context, state) {
        final notificationId = state.extra as String? ?? '';
        return _fadeSlide(NotificationDetailPage(notificationId: notificationId), state);
      },
    ),

    // --- Multisig ---
    GoRoute(
      path: WalletRoutes.multisigApproval,
      pageBuilder: (context, state) => _fadeSlide(const MultisigApprovalPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.offlineSignatureImport,
      pageBuilder: (context, state) {
        final initialTaskId = state.extra as String?;
        return _fadeSlide(OfflineSignatureImportPage(initialTaskId: initialTaskId), state);
      },
    ),

    // --- Replica Mobile ---
    GoRoute(
      path: WalletRoutes.replicaMobileHome,
      pageBuilder: (context, state) => _fadeSlide(const ReplicaMobileHomePage(), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaOnboarding,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingEntryPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaOnboardingNetworks,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingNetworksPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaOnboardingPassword,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingPasswordPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaOnboardingSetupWallet,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingSetupWalletPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaOnboardingFinish,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingFinishPage()), state),
    ),

    // --- Replica Import ---
    GoRoute(
      path: WalletRoutes.replicaImportWallet,
      pageBuilder: (context, state) => _fadeSlide(_withImportProvider(const ReplicaImportSelectBlockchainPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaImportMethod,
      pageBuilder: (context, state) => _fadeSlide(_withImportProvider(const ReplicaImportMethodPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaImportMnemonic,
      pageBuilder: (context, state) => _fadeSlide(_withImportProvider(const ReplicaImportMnemonicPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaImportDiscovering,
      pageBuilder: (context, state) => _fadeSlide(_withImportProvider(const ReplicaImportDiscoveringPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaImportAccounts,
      pageBuilder: (context, state) => _fadeSlide(_withImportProvider(const ReplicaImportAccountsPage()), state),
    ),

    // --- Replica Asset/Send/Receive ---
    GoRoute(
      path: WalletRoutes.replicaAssetDetail,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaAssetDetailArgs?;
        return _fadeSlide(
          ReplicaAssetDetailPage(
            args: args ??
                const ReplicaAssetDetailArgs(
                  symbol: 'Solana',
                  network: 'SOL',
                  balance: '0 SOL',
                  fiatValue: '\$0.00',
                ),
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaExplore,
      pageBuilder: (context, state) => _fadeSlide(const ReplicaExplorePage(), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSend,
      pageBuilder: (context, state) => _fadeSlide(const ReplicaSendSelectTokenPage(), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSendRecipient,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaSendRecipientArgs?;
        return _fadeSlide(ReplicaSendPage(args: args), state);
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaSendAmount,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaSendAmountArgs?;
        return _fadeSlide(ReplicaSendAmountPage(args: args ?? const ReplicaSendAmountArgs(symbol: 'SOL', recipient: '')), state);
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaReceive,
      pageBuilder: (context, state) => _fadeSlide(const ReplicaReceivePage(), state),
    ),

    // --- Replica Settings ---
    GoRoute(
      path: WalletRoutes.replicaSettings,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaSettingsPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWallets,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletsPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletDetail,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaWalletDetailArgs?;
        return _fadeSlide(
          _withSettingsProvider(
            ReplicaWalletDetailPage(
              args: args ??
                  const ReplicaWalletDetailArgs(
                    blockchain: ReplicaBlockchain.solana,
                    publicKey: 'So1aNaPubKeyMock1111111111111111111111',
                    name: 'Wallet 1',
                    type: 'Recovery Phrase',
                    isActive: true,
                  ),
            ),
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletRename,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaWalletRenameArgs?;
        return _fadeSlide(
          _withSettingsProvider(
            ReplicaWalletRenamePage(
              args: args ??
                  const ReplicaWalletRenameArgs(
                    blockchain: ReplicaBlockchain.solana,
                    publicKey: 'So1aNaPubKeyMock1111111111111111111111',
                    name: 'Wallet 1',
                  ),
            ),
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletRemove,
      pageBuilder: (context, state) {
        final args = state.extra as ReplicaWalletRemoveArgs?;
        return _fadeSlide(
          _withSettingsProvider(
            ReplicaWalletRemovePage(
              args: args ??
                  const ReplicaWalletRemoveArgs(
                    blockchain: ReplicaBlockchain.solana,
                    publicKey: 'So1aNaPubKeyMock1111111111111111111111',
                    type: 'Recovery Phrase',
                  ),
            ),
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletRemoveConfirm,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletRemoveConfirmPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAdd,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAddBlockchainSelect,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddBlockchainSelectPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletCreateOrImportMnemonic,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletCreateOrImportMnemonicPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletCreateMnemonic,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletCreateMnemonicPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletSetMnemonic,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletSetMnemonicPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAddBackpackRecoveryPhrase,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddBackpackRecoveryPhrasePage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAddDeriveRecoveryPhrase,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddDeriveRecoveryPhrasePage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAddPrivateKey,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddPrivateKeyPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsWalletAddHardware,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaWalletAddHardwarePage()), state),
    ),

    // --- Replica Settings > Account ---
    GoRoute(
      path: WalletRoutes.replicaSettingsAccount,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaYourAccountPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsAccountUpdateName,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaUpdateAccountNamePage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsAccountChangePassword,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaChangePasswordPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsShowRecoveryPhraseWarning,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaShowRecoveryPhraseWarningPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsAccountRemove,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaRemoveAccountPage()), state),
    ),

    // --- Replica Settings > Preferences ---
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferences,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesAutolock,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesAutolockPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesTrustedSites,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesTrustedSitesPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesLanguage,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesLanguagePage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesHiddenTokens,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesHiddenTokensPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesBlockchain,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesBlockchainPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesRpcConnection,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesRpcConnectionPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesRpcCustom,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesRpcCustomPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesCommitment,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesCommitmentPage()), state),
    ),
    GoRoute(
      path: WalletRoutes.replicaSettingsPreferencesExplorer,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaPreferencesExplorerPage()), state),
    ),

    // --- Replica Settings > About ---
    GoRoute(
      path: WalletRoutes.replicaSettingsAbout,
      pageBuilder: (context, state) => _fadeSlide(_withSettingsProvider(const ReplicaAboutPage()), state),
    ),

    // --- Replica Security ---
    GoRoute(
      path: WalletRoutes.replicaSecurityConfirm,
      pageBuilder: (context, state) => _fadeSlide(const ReplicaSecurityConfirmPage(), state),
    ),

    // --- Global Search ---
    GoRoute(
      path: WalletRoutes.globalSearch,
      pageBuilder: (context, state) => _fadeSlide(const GlobalSearchPage(), state),
    ),

    // --- Home (fallback) ---
    GoRoute(
      path: WalletRoutes.home,
      pageBuilder: (context, state) => _fadeSlide(_withOnboardingProvider(const ReplicaOnboardingEntryPage()), state),
    ),
  ],
);
