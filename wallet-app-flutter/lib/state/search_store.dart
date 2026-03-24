import 'package:flutter/foundation.dart';

import 'transaction_store.dart';
import 'notification_store.dart';
import 'walletconnect_store.dart';

enum SearchResultCategory { token, transaction, dapp, setting }

class SearchResultItem {
  const SearchResultItem({
    required this.category,
    required this.title,
    required this.subtitle,
    this.route,
    this.extra,
  });

  final SearchResultCategory category;
  final String title;
  final String subtitle;
  final String? route;
  final Object? extra;
}

class GlobalSearchState {
  const GlobalSearchState({
    required this.query,
    required this.results,
    required this.recentSearches,
    this.loading = false,
  });

  final String query;
  final List<SearchResultItem> results;
  final List<String> recentSearches;
  final bool loading;

  GlobalSearchState copyWith({
    String? query,
    List<SearchResultItem>? results,
    List<String>? recentSearches,
    bool? loading,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      loading: loading ?? this.loading,
    );
  }
}

class GlobalSearchStore extends ValueNotifier<GlobalSearchState> {
  GlobalSearchStore._()
      : super(const GlobalSearchState(
          query: '',
          results: [],
          recentSearches: [],
        ));

  static final GlobalSearchStore instance = GlobalSearchStore._();

  static const _settingsEntries = <(String, String, String)>[
    ('Wallets', '管理钱包', '/replica/mobile/settings/wallets'),
    ('Your Account', '账户信息', '/replica/mobile/settings/account'),
    ('Preferences', '偏好设置', '/replica/mobile/settings/preferences'),
    ('Autolock', '自动锁定', '/replica/mobile/settings/preferences/autolock'),
    ('Language', '语言设置', '/replica/mobile/settings/preferences/language'),
    ('Trusted Sites', '受信站点', '/replica/mobile/settings/preferences/trusted-sites'),
    ('Hidden Tokens', '隐藏代币', '/replica/mobile/settings/preferences/hidden-tokens'),
    ('RPC Connection', 'RPC 连接', '/replica/mobile/settings/preferences/blockchain/rpc'),
    ('About', '关于', '/replica/mobile/settings/about'),
  ];

  void search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      value = value.copyWith(query: '', results: const []);
      return;
    }

    value = value.copyWith(query: trimmed, loading: true);

    final results = <SearchResultItem>[];
    final lowerQuery = trimmed.toLowerCase();

    // Search tokens
    final assets = TransactionDemoStore.instance.value.assets;
    for (final asset in assets) {
      if (asset.symbol.toLowerCase().contains(lowerQuery) ||
          asset.protocol.name.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResultItem(
          category: SearchResultCategory.token,
          title: asset.symbol,
          subtitle: '${asset.amount} (${asset.protocol.name})',
          route: '/asset/dashboard',
        ));
      }
    }

    // Search transactions
    final history = TransactionDemoStore.instance.value.history;
    for (final record in history) {
      if (record.txHash.toLowerCase().contains(lowerQuery) ||
          record.toAddress.toLowerCase().contains(lowerQuery) ||
          record.type.contains(trimmed) ||
          record.amount.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResultItem(
          category: SearchResultCategory.transaction,
          title: '${record.type} ${record.amount}',
          subtitle: '${record.toAddress.length > 20 ? '${record.toAddress.substring(0, 20)}...' : record.toAddress} - ${record.status}',
          route: '/asset/tx-flow',
        ));
      }
    }

    // Search DApp sessions
    final sessions = WalletConnectStore.instance.value.sessions;
    for (final session in sessions) {
      if (session.dappName.toLowerCase().contains(lowerQuery) ||
          session.chainId.toLowerCase().contains(lowerQuery) ||
          session.topic.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResultItem(
          category: SearchResultCategory.dapp,
          title: session.dappName,
          subtitle: '${session.chainId} - ${session.topic}',
          route: '/security/walletconnect',
        ));
      }
    }

    // Search notifications
    final notifications = NotificationCenterStore.instance.value.notifications;
    for (final item in notifications) {
      if (item.title.contains(trimmed) ||
          item.summary.contains(trimmed)) {
        results.add(SearchResultItem(
          category: SearchResultCategory.dapp,
          title: item.title,
          subtitle: item.summary,
          route: '/notify/detail',
          extra: item.id,
        ));
      }
    }

    // Search settings
    for (final entry in _settingsEntries) {
      if (entry.$1.toLowerCase().contains(lowerQuery) ||
          entry.$2.contains(trimmed)) {
        results.add(SearchResultItem(
          category: SearchResultCategory.setting,
          title: entry.$1,
          subtitle: entry.$2,
          route: entry.$3,
        ));
      }
    }

    value = value.copyWith(results: results, loading: false);
  }

  void addRecent(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      trimmed,
      ...value.recentSearches.where((item) => item != trimmed),
    ];
    final capped = updated.length > 10 ? updated.sublist(0, 10) : updated;
    value = value.copyWith(recentSearches: capped);
  }

  void removeRecent(String query) {
    final updated = value.recentSearches.where((item) => item != query).toList(growable: false);
    value = value.copyWith(recentSearches: updated);
  }

  void clearRecent() {
    value = value.copyWith(recentSearches: const []);
  }

  void clearResults() {
    value = value.copyWith(query: '', results: const []);
  }
}
