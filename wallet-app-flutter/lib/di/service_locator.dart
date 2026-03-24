import 'package:get_it/get_it.dart';

import '../api/chain_api_client.dart';
import '../config/wallet_runtime_config.dart';
import '../state/dapp_interop_store.dart';
import '../state/identity_demo_store.dart';
import '../state/ibc_store.dart';
import '../state/multisig_store.dart';
import '../state/notification_store.dart';
import '../state/search_store.dart';
import '../state/security_confirm_store.dart';
import '../state/staking_governance_store.dart';
import '../state/transaction_models.dart';
import '../state/transaction_store.dart';
import '../state/walletconnect_store.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // --- Infrastructure ---
  sl.registerLazySingleton<ChainApiClient>(
    () => ChainApiClient(
      baseUrl: WalletRuntimeConfig.apiBaseUrl,
      timeout: WalletRuntimeConfig.requestTimeout,
    ),
  );

  // --- Repositories ---
  sl.registerLazySingleton<TransactionRepository>(
    () => ChainTransactionRepository(
      apiClient: sl<ChainApiClient>(),
      walletAddress: WalletRuntimeConfig.walletAddress,
    ),
  );

  sl.registerLazySingleton<StakeGovernanceRepository>(
    () => ChainStakeGovernanceRepository(
      apiClient: sl<ChainApiClient>(),
      walletAddress: WalletRuntimeConfig.walletAddress,
    ),
  );

  // --- Use Cases ---
  sl.registerLazySingleton<TransactionUseCase>(
    () => TransactionUseCase(sl<TransactionRepository>()),
  );

  sl.registerLazySingleton<StakeGovernanceUseCase>(
    () => StakeGovernanceUseCase(sl<StakeGovernanceRepository>()),
  );

  // --- Stores ---
  sl.registerLazySingleton<TransferFormDraftBridge>(
    () => TransferFormDraftBridge.instance,
  );

  sl.registerLazySingleton<IdentityDemoStore>(
    () => IdentityDemoStore.instance,
  );

  sl.registerLazySingleton<SecurityConfirmStore>(
    () => SecurityConfirmStore.instance,
  );

  sl.registerLazySingleton<NotificationCenterStore>(
    () => NotificationCenterStore.instance,
  );

  sl.registerLazySingleton<DappInteropStore>(
    () => DappInteropStore.instance,
  );

  sl.registerLazySingleton<WalletConnectStore>(
    () => WalletConnectStore.instance,
  );

  sl.registerLazySingleton<StakeDemoStore>(
    () => StakeDemoStore.instance,
  );

  sl.registerLazySingleton<GovernanceDemoStore>(
    () => GovernanceDemoStore.instance,
  );

  sl.registerLazySingleton<IbcDemoStore>(
    () => IbcDemoStore.instance,
  );

  sl.registerLazySingleton<TransactionDemoStore>(
    () => TransactionDemoStore.instance,
  );

  sl.registerLazySingleton<MultisigWorkbenchStore>(
    () => MultisigWorkbenchStore.instance,
  );

  sl.registerLazySingleton<GlobalSearchStore>(
    () => GlobalSearchStore.instance,
  );
}

void resetServiceLocator() {
  sl.reset();
}
