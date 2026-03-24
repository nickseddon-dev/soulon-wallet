import 'package:flutter/material.dart';

import '../motion/route_motion.dart';
import '../pages/component_showcase_page.dart';
import '../pages/create_wallet_page.dart';
import '../pages/foundation_home_page.dart';
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
import '../pages/replica_import_wallet_page.dart';
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

final class WalletRoutes {
  const WalletRoutes._();

  static const String home = '/';
  static const String components = '/components';
  static const String motion = '/motion';
  static const String identityMnemonic = '/identity/mnemonic';
  static const String createWallet = '/identity/create-wallet';
  static const String identityHd = '/identity/hd';
  static const String identityBackupVerify = '/identity/backup-verify';
  static const String assetDashboard = '/asset/dashboard';
  static const String transactionFlow = '/asset/tx-flow';
  static const String transactionHistoryExport = '/asset/history-export';
  static const String swapExchange = '/asset/swap-exchange';
  static const String stakingFlow = '/interop/staking';
  static const String governanceVote = '/interop/governance';
  static const String ibcTransferTracking = '/interop/ibc';
  static const String pinBiometricConfirm = '/security/pin-biometric';
  static const String walletConnectSession = '/security/walletconnect';
  static const String suggestChainScanReorg = '/security/suggestchain-scan-reorg';
  static const String notificationCenter = '/notify/center';
  static const String notificationDetail = '/notify/detail';
  static const String multisigApproval = '/multisig/approval';
  static const String offlineSignatureImport = '/multisig/offline-import';
  static const String replicaMobileHome = '/replica/mobile/home';
  static const String replicaOnboarding = '/replica/mobile/onboarding';
  static const String replicaOnboardingNetworks = '/replica/mobile/onboarding/networks';
  static const String replicaOnboardingPassword = '/replica/mobile/onboarding/password';
  static const String replicaOnboardingSetupWallet = '/replica/mobile/onboarding/setup-wallet';
  static const String replicaOnboardingFinish = '/replica/mobile/onboarding/finish';
  static const String replicaImportWallet = '/replica/mobile/import-wallet';
  static const String replicaImportMethod = '/replica/mobile/import-wallet/method';
  static const String replicaImportMnemonic = '/replica/mobile/import-wallet/mnemonic';
  static const String replicaImportDiscovering = '/replica/mobile/import-wallet/discovering';
  static const String replicaImportAccounts = '/replica/mobile/import-wallet/accounts';
  static const String replicaAssetDetail = '/replica/mobile/asset-detail';
  static const String replicaExplore = '/replica/mobile/explore';
  static const String replicaSend = '/replica/mobile/send';
  static const String replicaSendRecipient = '/replica/mobile/send/recipient';
  static const String replicaSendAmount = '/replica/mobile/send/amount';
  static const String replicaReceive = '/replica/mobile/receive';
  static const String replicaSettings = '/replica/mobile/settings';
  static const String replicaSecurityConfirm = '/replica/mobile/security-confirm';

  static const String replicaSettingsWallets = '/replica/mobile/settings/wallets';
  static const String replicaSettingsWalletDetail = '/replica/mobile/settings/wallets/detail';
  static const String replicaSettingsWalletRename = '/replica/mobile/settings/wallets/rename';
  static const String replicaSettingsWalletRemove = '/replica/mobile/settings/wallets/remove';
  static const String replicaSettingsWalletRemoveConfirm = '/replica/mobile/settings/wallets/remove/confirm';
  static const String replicaSettingsWalletAdd = '/replica/mobile/settings/wallets/add';
  static const String replicaSettingsWalletAddBlockchainSelect = '/replica/mobile/settings/wallets/add/blockchain';
  static const String replicaSettingsWalletCreateOrImportMnemonic = '/replica/mobile/settings/wallets/add/mnemonic';
  static const String replicaSettingsWalletCreateMnemonic = '/replica/mobile/settings/wallets/add/mnemonic/create';
  static const String replicaSettingsWalletSetMnemonic = '/replica/mobile/settings/wallets/add/mnemonic/import';
  static const String replicaSettingsWalletAddBackpackRecoveryPhrase = '/replica/mobile/settings/wallets/add/mnemonic/backpack';
  static const String replicaSettingsWalletAddDeriveRecoveryPhrase = '/replica/mobile/settings/wallets/add/mnemonic/derive';
  static const String replicaSettingsWalletAddPrivateKey = '/replica/mobile/settings/wallets/add/private-key';
  static const String replicaSettingsWalletAddHardware = '/replica/mobile/settings/wallets/add/hardware';

  static const String replicaSettingsAccount = '/replica/mobile/settings/account';
  static const String replicaSettingsAccountUpdateName = '/replica/mobile/settings/account/update-name';
  static const String replicaSettingsAccountChangePassword = '/replica/mobile/settings/account/change-password';
  static const String replicaSettingsShowRecoveryPhraseWarning = '/replica/mobile/settings/account/show-recovery-phrase-warning';
  static const String replicaSettingsAccountRemove = '/replica/mobile/settings/account/remove';

  static const String replicaSettingsPreferences = '/replica/mobile/settings/preferences';
  static const String replicaSettingsPreferencesAutolock = '/replica/mobile/settings/preferences/autolock';
  static const String replicaSettingsPreferencesTrustedSites = '/replica/mobile/settings/preferences/trusted-sites';
  static const String replicaSettingsPreferencesLanguage = '/replica/mobile/settings/preferences/language';
  static const String replicaSettingsPreferencesHiddenTokens = '/replica/mobile/settings/preferences/hidden-tokens';
  static const String replicaSettingsPreferencesBlockchain = '/replica/mobile/settings/preferences/blockchain';
  static const String replicaSettingsPreferencesRpcConnection = '/replica/mobile/settings/preferences/blockchain/rpc';
  static const String replicaSettingsPreferencesRpcCustom = '/replica/mobile/settings/preferences/blockchain/rpc/custom';
  static const String replicaSettingsPreferencesCommitment = '/replica/mobile/settings/preferences/blockchain/commitment';
  static const String replicaSettingsPreferencesExplorer = '/replica/mobile/settings/preferences/blockchain/explorer';

  static const String replicaSettingsAbout = '/replica/mobile/settings/about';

  static const String ovdAuthLogin = '/ovd/auth/login';
  static const String ovdAuthRegister = '/ovd/auth/register';
  static const String ovdLauncher = '/ovd/launcher';
}

final class AppRouter {
  const AppRouter._();

  static Widget _withSettingsProvider(Widget child) {
    return ReplicaSettingsProvider(store: replicaSettingsStore, child: child);
  }

  static Widget _withOnboardingProvider(Widget child) {
    return ReplicaOnboardingProvider(store: replicaOnboardingStore, child: child);
  }

  static Widget _withImportProvider(Widget child) {
    return ReplicaImportProvider(store: replicaImportStore, child: child);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case WalletRoutes.ovdAuthLogin:
        return fadeSlideRoute(const OvdAuthLoginPage());
      case WalletRoutes.ovdAuthRegister:
        return fadeSlideRoute(const OvdAuthRegisterPage());
      case WalletRoutes.ovdLauncher:
        return fadeSlideRoute(
          Builder(
            builder: (context) {
              return OvdLauncherPage(
                onClose: () => Navigator.pop(context),
                onDeposit: () => Navigator.pushNamed(context, WalletRoutes.replicaReceive),
                onWithdraw: () => Navigator.pushNamed(context, WalletRoutes.replicaSend),
                onSwap: () => Navigator.pushNamed(context, WalletRoutes.swapExchange),
                onOpenTavern: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Tavern'))),
                onOpenVault: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Vault'))),
                onOpenBazaar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Bazaar'))),
                onOpenLab: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvdPlaceholderPage(title: 'Lab'))),
              );
            },
          ),
        );
      case WalletRoutes.components:
        return fadeSlideRoute(const ComponentShowcasePage());
      case WalletRoutes.motion:
        return fadeSlideRoute(const MotionShowcasePage());
      case WalletRoutes.identityMnemonic:
        return fadeSlideRoute(const IdentityMnemonicPage());
      case WalletRoutes.createWallet:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingNetworksPage()));
      case WalletRoutes.identityHd:
        return fadeSlideRoute(const IdentityHdWatchPage());
      case WalletRoutes.identityBackupVerify:
        return fadeScaleRoute(const IdentityBackupVerifyPage());
      case WalletRoutes.assetDashboard:
        return fadeSlideRoute(const AssetDashboardPage());
      case WalletRoutes.transactionFlow:
        return fadeSlideRoute(const TransactionFlowPage());
      case WalletRoutes.transactionHistoryExport:
        return fadeSlideRoute(const TransactionHistoryExportPage());
      case WalletRoutes.swapExchange:
        return fadeSlideRoute(const SwapExchangePage());
      case WalletRoutes.stakingFlow:
        return fadeSlideRoute(const StakingFlowPage());
      case WalletRoutes.governanceVote:
        return fadeSlideRoute(const GovernanceVotePage());
      case WalletRoutes.ibcTransferTracking:
        return fadeSlideRoute(const IbcTransferTrackingPage());
      case WalletRoutes.pinBiometricConfirm:
        return fadeSlideRoute(const PinBiometricConfirmPage());
      case WalletRoutes.walletConnectSession:
        return fadeSlideRoute(const WalletConnectSessionPage());
      case WalletRoutes.suggestChainScanReorg:
        return fadeSlideRoute(const SuggestChainScanReorgPage());
      case WalletRoutes.notificationCenter:
        return fadeSlideRoute(const NotificationCenterPage());
      case WalletRoutes.notificationDetail:
        final notificationId = (settings.arguments as String?) ?? '';
        return fadeSlideRoute(NotificationDetailPage(notificationId: notificationId));
      case WalletRoutes.multisigApproval:
        return fadeSlideRoute(const MultisigApprovalPage());
      case WalletRoutes.offlineSignatureImport:
        final initialTaskId = settings.arguments as String?;
        return fadeSlideRoute(OfflineSignatureImportPage(initialTaskId: initialTaskId));
      case WalletRoutes.replicaMobileHome:
        return fadeSlideRoute(const ReplicaMobileHomePage());
      case WalletRoutes.replicaOnboarding:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingEntryPage()));
      case WalletRoutes.replicaOnboardingNetworks:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingNetworksPage()));
      case WalletRoutes.replicaOnboardingPassword:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingPasswordPage()));
      case WalletRoutes.replicaOnboardingSetupWallet:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingSetupWalletPage()));
      case WalletRoutes.replicaOnboardingFinish:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingFinishPage()));
      case WalletRoutes.replicaImportWallet:
        return fadeSlideRoute(_withImportProvider(const ReplicaImportSelectBlockchainPage()));
      case WalletRoutes.replicaImportMethod:
        return fadeSlideRoute(_withImportProvider(const ReplicaImportMethodPage()));
      case WalletRoutes.replicaImportMnemonic:
        return fadeSlideRoute(_withImportProvider(const ReplicaImportMnemonicPage()));
      case WalletRoutes.replicaImportDiscovering:
        return fadeSlideRoute(_withImportProvider(const ReplicaImportDiscoveringPage()));
      case WalletRoutes.replicaImportAccounts:
        return fadeSlideRoute(_withImportProvider(const ReplicaImportAccountsPage()));
      case WalletRoutes.replicaAssetDetail:
        final args = settings.arguments as ReplicaAssetDetailArgs?;
        return fadeSlideRoute(
          ReplicaAssetDetailPage(
            args: args ??
                const ReplicaAssetDetailArgs(
                  symbol: 'Solana',
                  network: 'SOL',
                  balance: '0 SOL',
                  fiatValue: '\$0.00',
                ),
          ),
        );
      case WalletRoutes.replicaExplore:
        return fadeSlideRoute(const ReplicaExplorePage());
      case WalletRoutes.replicaSend:
        return fadeSlideRoute(const ReplicaSendSelectTokenPage());
      case WalletRoutes.replicaSendRecipient:
        final args = settings.arguments as ReplicaSendRecipientArgs?;
        return fadeSlideRoute(ReplicaSendPage(args: args));
      case WalletRoutes.replicaSendAmount:
        final args = settings.arguments as ReplicaSendAmountArgs?;
        return fadeSlideRoute(ReplicaSendAmountPage(args: args ?? const ReplicaSendAmountArgs(symbol: 'SOL', recipient: '')));
      case WalletRoutes.replicaReceive:
        return fadeSlideRoute(const ReplicaReceivePage());
      case WalletRoutes.replicaSettings:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaSettingsPage()));
      case WalletRoutes.replicaSettingsWallets:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletsPage()));
      case WalletRoutes.replicaSettingsWalletDetail:
        final args = settings.arguments as ReplicaWalletDetailArgs?;
        return fadeSlideRoute(
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
        );
      case WalletRoutes.replicaSettingsWalletRename:
        final args = settings.arguments as ReplicaWalletRenameArgs?;
        return fadeSlideRoute(
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
        );
      case WalletRoutes.replicaSettingsWalletRemove:
        final args = settings.arguments as ReplicaWalletRemoveArgs?;
        return fadeSlideRoute(
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
        );
      case WalletRoutes.replicaSettingsWalletRemoveConfirm:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletRemoveConfirmPage()));
      case WalletRoutes.replicaSettingsWalletAdd:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddPage()));
      case WalletRoutes.replicaSettingsWalletAddBlockchainSelect:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddBlockchainSelectPage()));
      case WalletRoutes.replicaSettingsWalletCreateOrImportMnemonic:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletCreateOrImportMnemonicPage()));
      case WalletRoutes.replicaSettingsWalletCreateMnemonic:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletCreateMnemonicPage()));
      case WalletRoutes.replicaSettingsWalletSetMnemonic:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletSetMnemonicPage()));
      case WalletRoutes.replicaSettingsWalletAddBackpackRecoveryPhrase:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddBackpackRecoveryPhrasePage()));
      case WalletRoutes.replicaSettingsWalletAddDeriveRecoveryPhrase:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddDeriveRecoveryPhrasePage()));
      case WalletRoutes.replicaSettingsWalletAddPrivateKey:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddPrivateKeyPage()));
      case WalletRoutes.replicaSettingsWalletAddHardware:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaWalletAddHardwarePage()));

      case WalletRoutes.replicaSettingsAccount:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaYourAccountPage()));
      case WalletRoutes.replicaSettingsAccountUpdateName:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaUpdateAccountNamePage()));
      case WalletRoutes.replicaSettingsAccountChangePassword:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaChangePasswordPage()));
      case WalletRoutes.replicaSettingsShowRecoveryPhraseWarning:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaShowRecoveryPhraseWarningPage()));
      case WalletRoutes.replicaSettingsAccountRemove:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaRemoveAccountPage()));

      case WalletRoutes.replicaSettingsPreferences:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesPage()));
      case WalletRoutes.replicaSettingsPreferencesAutolock:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesAutolockPage()));
      case WalletRoutes.replicaSettingsPreferencesTrustedSites:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesTrustedSitesPage()));
      case WalletRoutes.replicaSettingsPreferencesLanguage:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesLanguagePage()));
      case WalletRoutes.replicaSettingsPreferencesHiddenTokens:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesHiddenTokensPage()));
      case WalletRoutes.replicaSettingsPreferencesBlockchain:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesBlockchainPage()));
      case WalletRoutes.replicaSettingsPreferencesRpcConnection:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesRpcConnectionPage()));
      case WalletRoutes.replicaSettingsPreferencesRpcCustom:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesRpcCustomPage()));
      case WalletRoutes.replicaSettingsPreferencesCommitment:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesCommitmentPage()));
      case WalletRoutes.replicaSettingsPreferencesExplorer:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaPreferencesExplorerPage()));

      case WalletRoutes.replicaSettingsAbout:
        return fadeSlideRoute(_withSettingsProvider(const ReplicaAboutPage()));
      case WalletRoutes.replicaSecurityConfirm:
        return fadeSlideRoute(const ReplicaSecurityConfirmPage());
      case WalletRoutes.home:
      default:
        return fadeSlideRoute(_withOnboardingProvider(const ReplicaOnboardingEntryPage()));
    }
  }
}
