import 'dart:math';

import 'package:flutter/foundation.dart';

class HdAccountItem {
  const HdAccountItem({
    required this.name,
    required this.path,
    required this.address,
    required this.balance,
  });

  final String name;
  final String path;
  final String address;
  final String balance;
}

class WatchWalletItem {
  const WatchWalletItem({
    required this.label,
    required this.address,
  });

  final String label;
  final String address;
}

class IdentityDemoState {
  const IdentityDemoState({
    required this.mnemonicWords,
    required this.hdAccounts,
    required this.watchWallets,
  });

  final List<String> mnemonicWords;
  final List<HdAccountItem> hdAccounts;
  final List<WatchWalletItem> watchWallets;

  bool get hasMnemonic => mnemonicWords.isNotEmpty;

  IdentityDemoState copyWith({
    List<String>? mnemonicWords,
    List<HdAccountItem>? hdAccounts,
    List<WatchWalletItem>? watchWallets,
  }) {
    return IdentityDemoState(
      mnemonicWords: mnemonicWords ?? this.mnemonicWords,
      hdAccounts: hdAccounts ?? this.hdAccounts,
      watchWallets: watchWallets ?? this.watchWallets,
    );
  }
}

class IdentityDemoStore extends ValueNotifier<IdentityDemoState> {
  IdentityDemoStore._()
      : _random = Random.secure(),
        super(
          const IdentityDemoState(
            mnemonicWords: [],
            hdAccounts: [],
            watchWallets: [],
          ),
        );

  static final IdentityDemoStore instance = IdentityDemoStore._();
  final Random _random;

  static const List<String> _wordBank = [
    'absorb',
    'adapt',
    'ancient',
    'anchor',
    'artist',
    'autumn',
    'balance',
    'banner',
    'beacon',
    'beyond',
    'blossom',
    'brisk',
    'canyon',
    'captain',
    'citrus',
    'cobalt',
    'cosmos',
    'crystal',
    'daring',
    'dawn',
    'desert',
    'drift',
    'echo',
    'ember',
    'eternal',
    'feather',
    'festival',
    'forest',
    'future',
    'galaxy',
    'gentle',
    'glacier',
    'harbor',
    'horizon',
    'ivory',
    'jungle',
    'ladder',
    'lantern',
    'legacy',
    'lotus',
    'marble',
    'matrix',
    'meadow',
    'merit',
    'meteor',
    'mirror',
    'moment',
    'nebula',
    'north',
    'oak',
    'oasis',
    'olive',
    'orbit',
    'origin',
    'phoenix',
    'planet',
    'pioneer',
    'pulse',
    'quantum',
    'raven',
    'ripple',
    'river',
    'saddle',
    'saffron',
    'shelter',
    'signal',
    'silver',
    'solar',
    'spirit',
    'stable',
    'summit',
    'sunrise',
    'timber',
    'token',
    'travel',
    'unity',
    'valley',
    'velvet',
    'voyage',
    'wallet',
    'willow',
    'wisdom',
    'zenith',
  ];

  void generateMnemonic({required int wordCount}) {
    if (wordCount != 12 && wordCount != 24) {
      throw const FormatException('仅支持 12 或 24 词助记词');
    }
    final words = List<String>.generate(
      wordCount,
      (_) => _wordBank[_random.nextInt(_wordBank.length)],
    );
    value = value.copyWith(mnemonicWords: words);
  }

  void recoverMnemonic(String rawInput) {
    final words = rawInput
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .toList(growable: false);

    if (words.length != 12 && words.length != 24) {
      throw const FormatException('恢复助记词必须为 12 或 24 个单词');
    }
    final invalidWord = words.firstWhere(
      (word) => !RegExp(r'^[a-z]+$').hasMatch(word),
      orElse: () => '',
    );
    if (invalidWord.isNotEmpty) {
      throw const FormatException('助记词仅允许 a-z 字母');
    }
    value = value.copyWith(mnemonicWords: words);
  }

  HdAccountItem addHdAccount() {
    if (!value.hasMnemonic) {
      throw const FormatException('请先生成或恢复助记词');
    }
    final index = value.hdAccounts.length;
    final path = "m/44'/118'/0'/0/$index";
    final address = _buildCosmosAddress(index + 11);
    final account = HdAccountItem(
      name: '账户 ${index + 1}',
      path: path,
      address: address,
      balance: '${(index + 1) * 12}.40 SOUL',
    );
    value = value.copyWith(
      hdAccounts: [...value.hdAccounts, account],
    );
    return account;
  }

  void addWatchWallet({
    required String label,
    required String address,
  }) {
    final normalizedLabel = label.trim();
    final normalizedAddress = address.trim().toLowerCase();
    if (normalizedLabel.isEmpty) {
      throw const FormatException('观察者钱包名称不能为空');
    }
    if (!RegExp(r'^cosmos1[0-9a-z]{20,}$').hasMatch(normalizedAddress)) {
      throw const FormatException('地址格式错误，请输入有效 cosmos 地址');
    }
    final duplicated = value.watchWallets.any(
      (wallet) => wallet.address == normalizedAddress,
    );
    if (duplicated) {
      throw const FormatException('该观察地址已存在');
    }
    value = value.copyWith(
      watchWallets: [
        ...value.watchWallets,
        WatchWalletItem(label: normalizedLabel, address: normalizedAddress),
      ],
    );
  }

  bool verifyMnemonicOrder(List<String> selectedWords) {
    if (!value.hasMnemonic) {
      return false;
    }
    if (selectedWords.length != value.mnemonicWords.length) {
      return false;
    }
    for (var i = 0; i < selectedWords.length; i++) {
      if (selectedWords[i] != value.mnemonicWords[i]) {
        return false;
      }
    }
    return true;
  }

  String _buildCosmosAddress(int seed) {
    const charset = '023456789acdefghjklmnpqrstuvwxyz';
    final random = Random(seed * 9973);
    final body = List<String>.generate(
      38,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
    return 'cosmos1$body';
  }
}
