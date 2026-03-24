import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../state/identity_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_motion_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

enum _MnemonicMode { create, recover }

class IdentityMnemonicPage extends StatefulWidget {
  const IdentityMnemonicPage({super.key});

  @override
  State<IdentityMnemonicPage> createState() => _IdentityMnemonicPageState();
}

class _IdentityMnemonicPageState extends State<IdentityMnemonicPage> {
  final IdentityDemoStore _store = IdentityDemoStore.instance;
  final TextEditingController _recoverController = TextEditingController();
  _MnemonicMode _mode = _MnemonicMode.create;
  int _wordCount = 12;
  String? _errorText;

  @override
  void dispose() {
    _recoverController.dispose();
    super.dispose();
  }

  void _generateMnemonic() {
    setState(() => _errorText = null);
    try {
      _store.generateMnemonic(wordCount: _wordCount);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  void _recoverMnemonic() {
    setState(() => _errorText = null);
    try {
      _store.recoverMnemonic(_recoverController.text);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdentityDemoState>(
      valueListenable: _store,
      builder: (context, state, _) {
        final canContinue = state.hasMnemonic;
        return Scaffold(
          appBar: AppBar(title: const Text('助记词生成与恢复')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '流程模式',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<_MnemonicMode>(
                      segments: const [
                        ButtonSegment(
                          value: _MnemonicMode.create,
                          label: Text('创建钱包'),
                        ),
                        ButtonSegment(
                          value: _MnemonicMode.recover,
                          label: Text('恢复钱包'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _mode = selected.first;
                          _errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: AppMotionTokens.normal,
                      switchInCurve: AppMotionTokens.emphasized,
                      switchOutCurve: AppMotionTokens.standard,
                      child: _mode == _MnemonicMode.create
                          ? _buildCreateMode()
                          : _buildRecoverMode(),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColorTokens.danger,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.hasMnemonic) _buildMnemonicPreview(state.mnemonicWords),
              const SizedBox(height: 16),
              WalletPrimaryButton(
                label: '进入账户初始化',
                onPressed: canContinue
                    ? () => Navigator.pushNamed(context, WalletRoutes.identityHd)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateMode() {
    return Column(
      key: const ValueKey(_MnemonicMode.create),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('请选择 12 或 24 词生成新助记词。'),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 12, label: Text('12 词')),
            ButtonSegment(value: 24, label: Text('24 词')),
          ],
          selected: {_wordCount},
          onSelectionChanged: (selection) {
            setState(() {
              _wordCount = selection.first;
              _errorText = null;
            });
          },
        ),
        const SizedBox(height: 12),
        WalletPrimaryButton(label: '生成助记词', onPressed: _generateMnemonic),
      ],
    );
  }

  Widget _buildRecoverMode() {
    return Column(
      key: const ValueKey(_MnemonicMode.recover),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WalletTextField(
          label: '输入助记词',
          hintText: '请粘贴 12 或 24 个单词，以空格分隔',
          controller: _recoverController,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        WalletPrimaryButton(label: '校验并恢复', onPressed: _recoverMnemonic),
      ],
    );
  }

  Widget _buildMnemonicPreview(List<String> words) {
    return WalletCard(
      title: '助记词预览',
      trailing: Text(
        '${words.length} 词',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColorTokens.accent,
            ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < words.length; i++)
            Chip(label: Text('${i + 1}. ${words[i]}')),
        ],
      ),
    );
  }
}
