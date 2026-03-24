import 'package:flutter/material.dart';

enum ReplicaOnboardingNetwork {
  solana,
  ethereum,
  sui,
  aptos,
  base,
  monad,
  sei,
  hyperEvm,
  bnb,
}

extension ReplicaOnboardingNetworkLabel on ReplicaOnboardingNetwork {
  String get label {
    switch (this) {
      case ReplicaOnboardingNetwork.solana:
        return 'Solana';
      case ReplicaOnboardingNetwork.ethereum:
        return 'Ethereum';
      case ReplicaOnboardingNetwork.sui:
        return 'Sui';
      case ReplicaOnboardingNetwork.aptos:
        return 'Aptos';
      case ReplicaOnboardingNetwork.base:
        return 'Base';
      case ReplicaOnboardingNetwork.monad:
        return 'Monad';
      case ReplicaOnboardingNetwork.sei:
        return 'Sei';
      case ReplicaOnboardingNetwork.hyperEvm:
        return 'HyperEVM';
      case ReplicaOnboardingNetwork.bnb:
        return 'BNB Chain';
    }
  }
}

final class ReplicaOnboardingStore extends ChangeNotifier {
  bool acceptedTerms = false;

  final Set<ReplicaOnboardingNetwork> selectedNetworks = <ReplicaOnboardingNetwork>{};

  String password = '';

  void setAcceptedTerms(bool value) {
    acceptedTerms = value;
    notifyListeners();
  }

  void toggleNetwork(ReplicaOnboardingNetwork value) {
    if (selectedNetworks.contains(value)) {
      selectedNetworks.remove(value);
    } else {
      selectedNetworks.add(value);
    }
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    notifyListeners();
  }

  void resetCreateWalletFlow() {
    selectedNetworks.clear();
    password = '';
    notifyListeners();
  }
}

final ReplicaOnboardingStore replicaOnboardingStore = ReplicaOnboardingStore();

final class ReplicaOnboardingProvider extends InheritedNotifier<ReplicaOnboardingStore> {
  const ReplicaOnboardingProvider({
    super.key,
    required ReplicaOnboardingStore store,
    required super.child,
  }) : super(notifier: store);

  static ReplicaOnboardingStore of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ReplicaOnboardingProvider>();
    if (provider == null) {
      throw FlutterError('ReplicaOnboardingProvider not found in widget tree');
    }
    return provider.notifier!;
  }
}

