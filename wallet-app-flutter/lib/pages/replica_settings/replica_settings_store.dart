import 'package:flutter/material.dart';

import '../../theme/tokens/app_color_tokens.dart';

enum ReplicaBlockchain {
  solana,
  ethereum,
}

extension ReplicaBlockchainLabel on ReplicaBlockchain {
  String get label {
    switch (this) {
      case ReplicaBlockchain.solana:
        return 'Solana';
      case ReplicaBlockchain.ethereum:
        return 'Ethereum';
    }
  }
}

enum ReplicaWalletType {
  mnemonic,
  privateKey,
  hardware,
}

extension ReplicaWalletTypeLabel on ReplicaWalletType {
  String get label {
    switch (this) {
      case ReplicaWalletType.mnemonic:
        return 'Recovery Phrase';
      case ReplicaWalletType.privateKey:
        return 'Private Key';
      case ReplicaWalletType.hardware:
        return 'Hardware';
    }
  }
}

final class ReplicaWalletModel {
  const ReplicaWalletModel({
    required this.blockchain,
    required this.publicKey,
    required this.name,
    required this.type,
    required this.isActive,
  });

  final ReplicaBlockchain blockchain;
  final String publicKey;
  final String name;
  final ReplicaWalletType type;
  final bool isActive;

  ReplicaWalletModel copyWith({
    ReplicaBlockchain? blockchain,
    String? publicKey,
    String? name,
    ReplicaWalletType? type,
    bool? isActive,
  }) {
    return ReplicaWalletModel(
      blockchain: blockchain ?? this.blockchain,
      publicKey: publicKey ?? this.publicKey,
      name: name ?? this.name,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}

final class ReplicaSettingsStore extends ChangeNotifier {
  ReplicaSettingsStore()
      : wallets = List<ReplicaWalletModel>.unmodifiable(const [
          ReplicaWalletModel(
            blockchain: ReplicaBlockchain.solana,
            publicKey: 'So1aNaPubKeyMock1111111111111111111111',
            name: 'Wallet 1',
            type: ReplicaWalletType.mnemonic,
            isActive: true,
          ),
          ReplicaWalletModel(
            blockchain: ReplicaBlockchain.solana,
            publicKey: 'So1aNaPubKeyMock2222222222222222222222',
            name: 'Wallet 2',
            type: ReplicaWalletType.privateKey,
            isActive: false,
          ),
          ReplicaWalletModel(
            blockchain: ReplicaBlockchain.ethereum,
            publicKey: '0x71C0b90b8f7C9c2d2d0f1A2b3C4d5E6f789a978b',
            name: 'EVM 1',
            type: ReplicaWalletType.hardware,
            isActive: false,
          ),
        ]);

  bool pushNotifications = true;
  bool priceAlerts = false;
  String currency = 'USD';
  String language = 'English';
  String autoLockTimer = '10 minutes';

  ReplicaBlockchain defaultBlockchain = ReplicaBlockchain.solana;
  String rpcConnection = 'Default';
  String rpcCustomUrl = '';
  String commitment = 'Confirmed';
  String explorer = 'Solana Explorer';

  final List<ReplicaWalletModel> wallets;

  Color get accent => AppColorTokens.accent;

  void togglePushNotifications(bool value) {
    pushNotifications = value;
    notifyListeners();
  }

  void togglePriceAlerts(bool value) {
    priceAlerts = value;
    notifyListeners();
  }

  void setCurrency(String value) {
    currency = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setAutoLockTimer(String value) {
    autoLockTimer = value;
    notifyListeners();
  }

  void setDefaultBlockchain(ReplicaBlockchain value) {
    defaultBlockchain = value;
    notifyListeners();
  }

  void setRpcConnection(String value) {
    rpcConnection = value;
    notifyListeners();
  }

  void setRpcCustomUrl(String value) {
    rpcCustomUrl = value;
    notifyListeners();
  }

  void setCommitment(String value) {
    commitment = value;
    notifyListeners();
  }

  void setExplorer(String value) {
    explorer = value;
    notifyListeners();
  }
}

final ReplicaSettingsStore replicaSettingsStore = ReplicaSettingsStore();

final class ReplicaSettingsProvider extends InheritedNotifier<ReplicaSettingsStore> {
  const ReplicaSettingsProvider({
    super.key,
    required ReplicaSettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static ReplicaSettingsStore of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ReplicaSettingsProvider>();
    if (provider == null) {
      throw FlutterError('ReplicaSettingsProvider not found in widget tree');
    }
    return provider.notifier!;
  }
}

final class ReplicaWalletDetailArgs {
  const ReplicaWalletDetailArgs({
    required this.blockchain,
    required this.publicKey,
    required this.name,
    required this.type,
    required this.isActive,
  });

  final ReplicaBlockchain blockchain;
  final String publicKey;
  final String name;
  final String type;
  final bool isActive;
}

final class ReplicaWalletRenameArgs {
  const ReplicaWalletRenameArgs({
    required this.blockchain,
    required this.publicKey,
    required this.name,
  });

  final ReplicaBlockchain blockchain;
  final String publicKey;
  final String name;
}

final class ReplicaWalletRemoveArgs {
  const ReplicaWalletRemoveArgs({
    required this.blockchain,
    required this.publicKey,
    required this.type,
  });

  final ReplicaBlockchain blockchain;
  final String publicKey;
  final String type;
}
