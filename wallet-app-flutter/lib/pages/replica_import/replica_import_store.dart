import 'package:flutter/material.dart';

enum ReplicaImportBlockchain {
  solana,
  ethereum,
  sui,
  aptos,
  base,
  monad,
  sei,
  hyperEvm,
  bnb,
  arbitrum,
  eclipse,
}

extension ReplicaImportBlockchainLabel on ReplicaImportBlockchain {
  String get label {
    switch (this) {
      case ReplicaImportBlockchain.solana:
        return 'Solana';
      case ReplicaImportBlockchain.ethereum:
        return 'Ethereum';
      case ReplicaImportBlockchain.sui:
        return 'Sui';
      case ReplicaImportBlockchain.aptos:
        return 'Aptos';
      case ReplicaImportBlockchain.base:
        return 'Base';
      case ReplicaImportBlockchain.monad:
        return 'Monad';
      case ReplicaImportBlockchain.sei:
        return 'Sei';
      case ReplicaImportBlockchain.hyperEvm:
        return 'HyperEVM';
      case ReplicaImportBlockchain.bnb:
        return 'BNB Chain';
      case ReplicaImportBlockchain.arbitrum:
        return 'Arbitrum';
      case ReplicaImportBlockchain.eclipse:
        return 'Eclipse';
    }
  }
}

final class ReplicaImportStore extends ChangeNotifier {
  ReplicaImportBlockchain selectedBlockchain = ReplicaImportBlockchain.solana;

  bool use24Words = false;

  void selectBlockchain(ReplicaImportBlockchain blockchain) {
    selectedBlockchain = blockchain;
    notifyListeners();
  }

  void setUse24Words(bool value) {
    use24Words = value;
    notifyListeners();
  }
}

final ReplicaImportStore replicaImportStore = ReplicaImportStore();

final class ReplicaImportProvider extends InheritedNotifier<ReplicaImportStore> {
  const ReplicaImportProvider({
    super.key,
    required ReplicaImportStore store,
    required super.child,
  }) : super(notifier: store);

  static ReplicaImportStore of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ReplicaImportProvider>();
    if (provider == null) {
      throw FlutterError('ReplicaImportProvider not found in widget tree');
    }
    return provider.notifier!;
  }
}

