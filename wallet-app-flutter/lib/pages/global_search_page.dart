import 'package:flutter/material.dart';

import '../state/search_store.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _store = GlobalSearchStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStateChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSearch(String query) {
    _store.search(query);
  }

  void _onSubmit(String query) {
    if (query.trim().isNotEmpty) {
      _store.addRecent(query.trim());
    }
  }

  void _onResultTap(SearchResultItem item) {
    _store.addRecent(_store.value.query);
    if (item.route != null) {
      Navigator.pushNamed(context, item.route!, arguments: item.extra);
    }
  }

  void _onRecentTap(String query) {
    _controller.text = query;
    _store.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = _store.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearch,
          onSubmitted: _onSubmit,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: '搜索代币、交易、DApp、设置...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(color: Colors.white38),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                _store.clearResults();
              },
            ),
        ],
      ),
      body: state.query.isEmpty
          ? _buildRecentSearches(state, theme)
          : state.results.isEmpty
              ? _buildEmpty(theme)
              : _buildResults(state, theme),
    );
  }

  Widget _buildRecentSearches(GlobalSearchState state, ThemeData theme) {
    if (state.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              '输入关键词开始搜索',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('最近搜索', style: theme.textTheme.titleSmall?.copyWith(color: Colors.white54)),
              GestureDetector(
                onTap: _store.clearRecent,
                child: Text('清除', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.recentSearches.length,
            itemBuilder: (context, index) {
              final query = state.recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 20, color: Colors.white38),
                title: Text(query, style: const TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white24),
                  onPressed: () => _store.removeRecent(query),
                ),
                onTap: () => _onRecentTap(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            '未找到匹配结果',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(GlobalSearchState state, ThemeData theme) {
    final grouped = <SearchResultCategory, List<SearchResultItem>>{};
    for (final item in state.results) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final sections = grouped.entries.toList();

    return ListView.builder(
      itemCount: sections.fold<int>(0, (sum, entry) => sum + 1 + entry.value.length),
      itemBuilder: (context, index) {
        var offset = 0;
        for (final section in sections) {
          if (index == offset) {
            return _buildSectionHeader(section.key, theme);
          }
          offset += 1;
          if (index < offset + section.value.length) {
            final item = section.value[index - offset];
            return _buildResultTile(item, theme);
          }
          offset += section.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(SearchResultCategory category, ThemeData theme) {
    final label = switch (category) {
      SearchResultCategory.token => 'Tokens',
      SearchResultCategory.transaction => 'Transactions',
      SearchResultCategory.dapp => 'DApps & Notifications',
      SearchResultCategory.setting => 'Settings',
    };
    final icon = switch (category) {
      SearchResultCategory.token => Icons.toll,
      SearchResultCategory.transaction => Icons.receipt_long,
      SearchResultCategory.dapp => Icons.apps,
      SearchResultCategory.setting => Icons.settings,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildResultTile(SearchResultItem item, ThemeData theme) {
    return ListTile(
      title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(item.subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      dense: true,
      onTap: () => _onResultTap(item),
    );
  }
}
