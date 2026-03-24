final class WalletRuntimeConfig {
  const WalletRuntimeConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'WALLET_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8082',
  );

  static const String walletAddress = String.fromEnvironment(
    'WALLET_WALLET_ADDRESS',
    defaultValue: 'cosmos1u73n5gqxp5n90f5wqm6v93rtyva08m7l62kc8q',
  );

  static const Duration requestTimeout = Duration(seconds: 8);
}
