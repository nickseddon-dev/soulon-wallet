import 'package:flutter/material.dart';

import '../state/identity_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_motion_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';

class ReplicaImportWalletPage extends StatefulWidget {
  const ReplicaImportWalletPage({super.key});

  @override
  State<ReplicaImportWalletPage> createState() => _ReplicaImportWalletPageState();
}

class _ReplicaImportWalletPageState extends State<ReplicaImportWalletPage> {
  final IdentityDemoStore _store = IdentityDemoStore.instance;
  final TextEditingController _walletNameController = TextEditingController(text: 'Wallet 2');
  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();

  bool _ackRisk = false;
  bool _isImporting = false;
  String? _errorText;
  bool _isValidMnemonic = false;

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_validateMnemonic);
  }

  @override
  void dispose() {
    _mnemonicController.removeListener(_validateMnemonic);
    _walletNameController.dispose();
    _mnemonicController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _validateMnemonic() {
    final text = _mnemonicController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isValidMnemonic = false;
        _errorText = null;
      });
      return;
    }

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final isValidCount = words.length == 12 || words.length == 24;
    
    setState(() {
      _isValidMnemonic = isValidCount;
      if (words.isNotEmpty && !isValidCount) {
        _errorText = '请输入 12 或 24 个单词 (当前: ${words.length})';
      } else {
        _errorText = null;
      }
    });
  }

  Future<void> _importWallet() async {
    if (!_canSubmit) return;
    setState(() {
      _isImporting = true;
      _errorText = null;
    });

    try {
      await Future.delayed(AppMotionTokens.fast);
      _store.recoverMnemonic(_mnemonicController.text.trim());
      _store.addHdAccount();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('钱包导入成功'),
          backgroundColor: AppColorTokens.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorText = e.toString().replaceFirst('Exception: ', '').replaceFirst('FormatException: ', '');
      });
    }
  }

  bool get _canSubmit {
    return _walletNameController.text.trim().isNotEmpty && _isValidMnemonic && _ackRisk && !_isImporting;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('导入钱包', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacingTokens.lg),
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                border: Border.all(color: AppColorTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('恢复助记词钱包', style: AppTypographyTokens.titleMedium),
                  const SizedBox(height: AppSpacingTokens.sm),
                  Text(
                    '请输入 12 或 24 个助记词，支持空格分隔',
                    style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                  ),
                  const SizedBox(height: AppSpacingTokens.lg),
                  _LabeledField(
                    label: '钱包名称',
                    child: TextField(
                      controller: _walletNameController,
                      onChanged: (_) => setState(() {}),
                      style: AppTypographyTokens.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColorTokens.surfaceSubtle,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacingTokens.lg),
                  _LabeledField(
                    label: '助记词',
                    child: TextField(
                      controller: _mnemonicController,
                      maxLines: 4,
                      style: AppTypographyTokens.body.copyWith(
                        fontSize: 16,
                        letterSpacing: 0.3,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'input twelve or twenty four words',
                        hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontSize: 16),
                        errorText: _errorText,
                        filled: true,
                        fillColor: AppColorTokens.surfaceSubtle,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacingTokens.lg),
                  _LabeledField(
                    label: 'BIP39 密码（可选）',
                    child: TextField(
                      controller: _passphraseController,
                      obscureText: false,
                      style: AppTypographyTokens.body.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Optional passphrase',
                        hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontSize: 16),
                        filled: true,
                        fillColor: AppColorTokens.surfaceSubtle,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                          borderSide: const BorderSide(color: AppColorTokens.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacingTokens.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacingTokens.md, vertical: AppSpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: AppColorTokens.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                      border: Border.all(color: AppColorTokens.border),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '我已知晓：恢复短语泄露会导致资产风险',
                            style: TextStyle(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Checkbox(
                          value: _ackRisk,
                          onChanged: (v) => setState(() => _ackRisk = v ?? false),
                          activeColor: AppColorTokens.accent,
                          checkColor: Colors.white,
                          side: const BorderSide(color: AppColorTokens.borderLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacingTokens.lg),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _importWallet : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorTokens.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                        disabledForegroundColor: AppColorTokens.textMuted,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                        elevation: 0,
                      ),
                      child: _isImporting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('导入钱包', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypographyTokens.label),
        const SizedBox(height: AppSpacingTokens.sm),
        child,
      ],
    );
  }
}
