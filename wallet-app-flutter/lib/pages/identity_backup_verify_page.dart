import 'dart:math';

import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/identity_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_motion_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';

class IdentityBackupVerifyPage extends StatefulWidget {
  const IdentityBackupVerifyPage({super.key});

  @override
  State<IdentityBackupVerifyPage> createState() => _IdentityBackupVerifyPageState();
}

class _IdentityBackupVerifyPageState extends State<IdentityBackupVerifyPage> {
  final IdentityDemoStore _store = IdentityDemoStore.instance;
  late List<String> _shuffledWords;
  final List<String> _selectedWords = [];
  bool? _verified;

  @override
  void initState() {
    super.initState();
    _prepareWords();
  }

  void _prepareWords() {
    final words = [..._store.value.mnemonicWords];
    words.shuffle(Random());
    _shuffledWords = words;
    _selectedWords.clear();
    _verified = null;
  }

  void _addWord(String word) {
    if (_selectedWords.length == _store.value.mnemonicWords.length) {
      return;
    }
    setState(() {
      _selectedWords.add(word);
      _verified = null;
    });
  }

  void _removeWordAt(int index) {
    setState(() {
      _selectedWords.removeAt(index);
      _verified = null;
    });
  }

  void _verify() {
    final result = _store.verifyMnemonicOrder(_selectedWords);
    setState(() => _verified = result);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentityDemoState>(
      valueListenable: _store,
      builder: (context, state, _) {
        if (!state.hasMnemonic) {
          return Scaffold(
            appBar: AppBar(title: const Text('助记词备份校验')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: WalletCard(
                title: '未找到助记词',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('请先完成助记词生成或恢复，再进行备份校验。'),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: '前往助记词页面',
                      onPressed: () => Navigator.pushNamed(context, WalletRoutes.identityMnemonic),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final availableWords = List<String>.generate(
          _shuffledWords.length,
          (index) => _shuffledWords[index],
        );

        return Scaffold(
          appBar: AppBar(title: const Text('助记词备份校验')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '按顺序点击助记词',
                trailing: Text(
                  '${_selectedWords.length}/${state.mnemonicWords.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColorTokens.accent,
                      ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('请按原始顺序点击单词，完成后提交校验。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final word in availableWords)
                          ActionChip(
                            label: Text(word),
                            onPressed: () => _addWord(word),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColorTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColorTokens.border),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_selectedWords.isEmpty) const Text('尚未选择单词'),
                          for (var i = 0; i < _selectedWords.length; i++)
                            InputChip(
                              label: Text('${i + 1}. ${_selectedWords[i]}'),
                              onDeleted: () => _removeWordAt(i),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(label: '提交校验', onPressed: _verify),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: AppMotionTokens.normal,
                      child: _verified == null
                          ? const SizedBox.shrink()
                          : _verified!
                              ? _buildStatusBanner(
                                  '备份校验通过，助记词顺序正确。',
                                  AppColorTokens.success,
                                  Icons.verified_outlined,
                                )
                              : _buildStatusBanner(
                                  '校验失败，请重新按顺序选择。',
                                  AppColorTokens.danger,
                                  Icons.error_outline,
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const WalletCard(
                title: '风险提示',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('请勿截屏或云端明文保存助记词。'),
                    SizedBox(height: 8),
                    Text('建议离线抄写并分地保管。'),
                    SizedBox(height: 8),
                    Text('任何索要助记词的“客服”均为高风险行为。'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletPrimaryButton(
                label: '返回首页',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  WalletRoutes.home,
                  (route) => false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(String text, Color color, IconData icon) {
    return Container(
      key: ValueKey(text),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
