import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/identity_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_motion_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  final IdentityDemoStore _store = IdentityDemoStore.instance;

  // State
  int _currentStep = 0;
  bool _agreedToRisk = false;
  int _mnemonicLength = 12;
  List<String> _mnemonic = [];
  List<int> _verifyIndices = [];
  final List<TextEditingController> _verifyControllers = [];
  final TextEditingController _walletNameController = TextEditingController();
  bool _savedOffline = false;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-generate mnemonic but don't show it yet
    _generateMnemonic();
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    for (final controller in _verifyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _generateMnemonic() {
    try {
      _store.generateMnemonic(wordCount: _mnemonicLength);
      _mnemonic = _store.value.mnemonicWords;
      // Pick 2 random indices for verification
      final random = Random();
      final index1 = random.nextInt(_mnemonicLength);
      var index2 = random.nextInt(_mnemonicLength);
      while (index1 == index2) {
        index2 = random.nextInt(_mnemonicLength);
      }
      _verifyIndices = [index1, index2]..sort();
      
      // Initialize controllers
      for (final controller in _verifyControllers) {
        controller.dispose();
      }
      _verifyControllers.clear();
      _verifyControllers.add(TextEditingController());
      _verifyControllers.add(TextEditingController());
      _savedOffline = false;
      _errorText = null;
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  void _copyMnemonic() {
    Clipboard.setData(ClipboardData(text: _mnemonic.join(' ')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('助记词已复制到剪贴板'),
        backgroundColor: AppColorTokens.surfaceSubtle,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verifyMnemonic() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    // Simulate network/processing delay
    await Future.delayed(AppMotionTokens.normal);

    final word1 = _verifyControllers[0].text.trim().toLowerCase();
    final word2 = _verifyControllers[1].text.trim().toLowerCase();

    if (word1 != _mnemonic[_verifyIndices[0]] || 
        word2 != _mnemonic[_verifyIndices[1]]) {
      setState(() {
        _errorText = '助记词验证失败，请检查拼写';
        _isLoading = false;
      });
      return;
    }

    // Success
    setState(() {
      _isLoading = false;
      _currentStep = 2;
    });
    
    // Actually add the account to the store
    try {
      _store.addHdAccount();
    } catch (_) {
      // Ignore if already added or other issues for this UI demo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
      appBar: AppBar(
        backgroundColor: AppColorTokens.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorTokens.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('创建钱包流程', style: AppTypographyTokens.titleMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          children: [
            _InfoCard(
              icon: Icons.description_outlined,
              text: '创建新的钱包账户并生成助记词，请先确认备份安全风险。',
            ),
            const SizedBox(height: AppSpacingTokens.lg),
            _buildStepCard(),
            const SizedBox(height: AppSpacingTokens.lg),
            _buildStatusCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.lg),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTabs(currentStep: _currentStep),
          const SizedBox(height: AppSpacingTokens.lg),
          if (_currentStep == 0) _buildFillStep(),
          if (_currentStep == 1) _buildConfirmStep(),
          if (_currentStep == 2) _buildCompleteStep(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep == 2) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.lg),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.primary,
              foregroundColor: AppColorTokens.primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
              ),
              elevation: 0,
            ),
            child: const Text('完成', style: AppTypographyTokens.titleMedium),
          ),
        ),
      );
    }

    final canProceedFill = _agreedToRisk && _walletNameController.text.trim().isNotEmpty;
    final canProceedConfirm = _savedOffline && !_isLoading;
    return Padding(
      padding: const EdgeInsets.all(AppSpacingTokens.lg),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep == 0) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _currentStep--);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorTokens.surfaceSubtle,
                  foregroundColor: AppColorTokens.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                  ),
                  elevation: 0,
                ),
                child: const Text('取消', style: AppTypographyTokens.titleMedium),
              ),
            ),
          ),
          const SizedBox(width: AppSpacingTokens.md),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _currentStep == 0
                    ? (canProceedFill
                        ? () {
                            setState(() {
                              _currentStep = 1;
                              _savedOffline = false;
                              _errorText = null;
                              for (final controller in _verifyControllers) {
                                controller.text = '';
                              }
                            });
                          }
                        : null)
                    : (canProceedConfirm ? _verifyMnemonic : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorTokens.primary,
                  foregroundColor: AppColorTokens.primaryText,
                  disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                  disabledForegroundColor: AppColorTokens.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColorTokens.textPrimary),
                      )
                    : Text(_currentStep == 0 ? '下一步' : '创建', style: AppTypographyTokens.titleMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('钱包名称', style: AppTypographyTokens.label),
        const SizedBox(height: AppSpacingTokens.sm),
        TextField(
          controller: _walletNameController,
          style: AppTypographyTokens.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '例如：主钱包',
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
        const SizedBox(height: AppSpacingTokens.lg),
        const Text('助记词长度', style: AppTypographyTokens.label),
        const SizedBox(height: AppSpacingTokens.sm),
        Row(
          children: [
            Expanded(
              child: _PillChoice(
                selected: _mnemonicLength == 12,
                label: '12 词',
                onTap: () {
                  if (_mnemonicLength == 12) return;
                  setState(() {
                    _mnemonicLength = 12;
                    _generateMnemonic();
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacingTokens.md),
            Expanded(
              child: _PillChoice(
                selected: _mnemonicLength == 24,
                label: '24 词',
                onTap: () {
                  if (_mnemonicLength == 24) return;
                  setState(() {
                    _mnemonicLength = 24;
                    _generateMnemonic();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacingTokens.md),
          decoration: BoxDecoration(
            color: AppColorTokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(color: AppColorTokens.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('我已确认助记词需要离线备份', style: TextStyle(color: AppColorTokens.textPrimary, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('未确认前不可创建', style: TextStyle(color: AppColorTokens.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Switch(
                value: _agreedToRisk,
                onChanged: (v) => setState(() => _agreedToRisk = v),
                activeColor: AppColorTokens.accent,
                activeTrackColor: AppColorTokens.accent.withValues(alpha: 0.25),
                inactiveThumbColor: AppColorTokens.textSecondary,
                inactiveTrackColor: AppColorTokens.surface,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('助记词', style: AppTypographyTokens.label),
        const SizedBox(height: AppSpacingTokens.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacingTokens.md),
          decoration: BoxDecoration(
            color: AppColorTokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(color: AppColorTokens.border),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_mnemonic.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(AppRadiusTokens.md),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Text(
                  '${index + 1}. ${_mnemonic[index]}',
                  style: const TextStyle(color: AppColorTokens.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: AppSpacingTokens.md),
        TextButton.icon(
          onPressed: _copyMnemonic,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('复制助记词'),
          style: TextButton.styleFrom(foregroundColor: AppColorTokens.textSecondary),
        ),
        const SizedBox(height: AppSpacingTokens.lg),
        _InfoCard(
          icon: Icons.check_circle_outline,
          text: '请将助记词离线抄写备份。不要截图、不要分享。',
        ),
        const SizedBox(height: AppSpacingTokens.lg),
        const Text('验证', style: AppTypographyTokens.label),
        const SizedBox(height: AppSpacingTokens.sm),
        if (_errorText != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacingTokens.md),
            decoration: BoxDecoration(
              color: AppColorTokens.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
              border: Border.all(color: AppColorTokens.danger.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColorTokens.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorText!, style: const TextStyle(color: AppColorTokens.danger, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: AppSpacingTokens.md),
        ],
        _buildVerifyInput(0),
        const SizedBox(height: AppSpacingTokens.md),
        _buildVerifyInput(1),
        const SizedBox(height: AppSpacingTokens.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacingTokens.md),
          decoration: BoxDecoration(
            color: AppColorTokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(color: AppColorTokens.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '我已确认助记词需要离线备份',
                  style: TextStyle(color: AppColorTokens.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _savedOffline,
                onChanged: (v) => setState(() => _savedOffline = v),
                activeColor: AppColorTokens.accent,
                activeTrackColor: AppColorTokens.accent.withValues(alpha: 0.25),
                inactiveThumbColor: AppColorTokens.textSecondary,
                inactiveTrackColor: AppColorTokens.surface,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyInput(int index) {
    final wordIndex = _verifyIndices[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '单词 #${wordIndex + 1}',
          style: const TextStyle(
            color: AppColorTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _verifyControllers[index],
          style: const TextStyle(color: AppColorTokens.textPrimary),
          decoration: InputDecoration(
            hintText: '请输入第 ${wordIndex + 1} 个单词',
            hintStyle: const TextStyle(color: AppColorTokens.textMuted),
            filled: true,
            fillColor: AppColorTokens.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
              borderSide: BorderSide.none,
            ),
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
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColorTokens.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: AppColorTokens.success),
        ),
        const SizedBox(height: AppSpacingTokens.lg),
        const Text('待创建', style: AppTypographyTokens.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacingTokens.sm),
        Text(
          '钱包：${_walletNameController.text.trim().isEmpty ? '-' : _walletNameController.text.trim()}',
          style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacingTokens.sm),
        const Text(
          '钱包创建成功（Demo）。',
          style: AppTypographyTokens.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final title = _currentStep == 0 ? '待创建' : (_currentStep == 1 ? '确认信息' : '完成');
    final subtitle = _currentStep == 0 ? '请先填写钱包信息' : (_currentStep == 1 ? '请确认助记词已离线备份' : '流程已完成');
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.lg),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypographyTokens.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary)),
        ],
      ),
    );
  }
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.lg),
      decoration: BoxDecoration(
        color: AppColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColorTokens.textSecondary),
          const SizedBox(width: AppSpacingTokens.md),
          Expanded(
            child: Text(
              text,
              style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

final class _StepTabs extends StatelessWidget {
  const _StepTabs({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool active) {
      return Expanded(
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColorTokens.surfaceSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
            border: Border.all(color: active ? AppColorTokens.borderLight : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColorTokens.textPrimary : AppColorTokens.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(AppRadiusTokens.pill),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Row(
        children: [
          tab('步骤 1 · 填写', currentStep == 0),
          const SizedBox(width: 6),
          tab('步骤 2 · 确认', currentStep == 1),
          const SizedBox(width: 6),
          tab('步骤 3 · 完成', currentStep == 2),
        ],
      ),
    );
  }
}

final class _PillChoice extends StatelessWidget {
  const _PillChoice({required this.selected, required this.label, required this.onTap});

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColorTokens.accent.withValues(alpha: 0.22) : AppColorTokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
          border: Border.all(color: selected ? AppColorTokens.accent : AppColorTokens.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColorTokens.textPrimary : AppColorTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
