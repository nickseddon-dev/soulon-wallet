import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import '../../theme/tokens/app_radius_tokens.dart';
import '../../theme/tokens/app_spacing_tokens.dart';
import '../../theme/tokens/app_typography_tokens.dart';
import 'replica_onboarding_store.dart';
import 'replica_onboarding_widgets.dart';

final class ReplicaOnboardingPasswordPage extends StatefulWidget {
  const ReplicaOnboardingPasswordPage({super.key});

  @override
  State<ReplicaOnboardingPasswordPage> createState() => _ReplicaOnboardingPasswordPageState();
}

class _ReplicaOnboardingPasswordPageState extends State<ReplicaOnboardingPasswordPage> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid {
    final p = _password.text;
    final c = _confirm.text;
    return p.length >= 8 && p == c;
  }

  void _submit() {
    if (!_valid) {
      setState(() => _error = '密码至少 8 位且两次输入一致');
      return;
    }
    final store = ReplicaOnboardingProvider.of(context);
    store.setPassword(_password.text);
    Navigator.pushNamed(context, WalletRoutes.replicaOnboardingSetupWallet);
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
        title: const ReplicaOnboardingDots(total: 5, currentIndex: 2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacingTokens.sm),
              const Text(
                '设置密码',
                style: TextStyle(
                  fontFamily: AppTypographyTokens.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColorTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.sm),
              Text(
                '用于解锁您的钱包。',
                style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacingTokens.xl),
              _Field(
                label: '密码',
                child: TextField(
                  controller: _password,
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                  style: AppTypographyTokens.body.copyWith(fontSize: 16),
                  decoration: _decoration('请输入密码'),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.lg),
              _Field(
                label: '确认密码',
                child: TextField(
                  controller: _confirm,
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                  style: AppTypographyTokens.body.copyWith(fontSize: 16),
                  decoration: _decoration('再次输入密码'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacingTokens.md),
                Text(_error!, style: AppTypographyTokens.body.copyWith(color: AppColorTokens.danger, fontWeight: FontWeight.w600)),
              ],
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorTokens.surfaceSubtle,
                    foregroundColor: AppColorTokens.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                    elevation: 0,
                  ),
                  child: const Text('继续', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacingTokens.sm),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }
}

final class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

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

