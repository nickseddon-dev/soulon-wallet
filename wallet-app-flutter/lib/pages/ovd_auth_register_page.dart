import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class OvdAuthRegisterPage extends StatefulWidget {
  const OvdAuthRegisterPage({super.key});

  @override
  State<OvdAuthRegisterPage> createState() => _OvdAuthRegisterPageState();
}

class _OvdAuthRegisterPageState extends State<OvdAuthRegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _password.clear();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.trim().isNotEmpty && _password.text.trim().isNotEmpty;

  void _validate() {
    final email = _email.text.trim();
    final password = _password.text;
    String? emailErr;
    String? passwordErr;

    if (email.isNotEmpty && !_emailRegex.hasMatch(email)) {
      emailErr = '请输入有效的邮箱地址';
    }
    if (password.isNotEmpty && password.length < 8) {
      passwordErr = '密码至少 8 个字符';
    }
    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });
  }

  void _submit() {
    _validate();
    if (_emailError != null || _passwordError != null) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (!_emailRegex.hasMatch(email)) return;
    if (password.length < 8) return;
    Navigator.pushReplacementNamed(context, WalletRoutes.ovdLauncher);
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
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacingTokens.xl),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColorTokens.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColorTokens.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColorTokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColorTokens.border),
                      ),
                      child: const Icon(Icons.backpack_rounded, color: AppColorTokens.danger),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '注册',
                      style: TextStyle(
                        fontFamily: AppTypographyTokens.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      controller: _email,
                      hint: '电子邮件',
                      errorText: _emailError,
                      onChanged: (_) { _validate(); setState(() {}); },
                      obscureText: false,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _password,
                      hint: '密码',
                      errorText: _passwordError,
                      onChanged: (_) { _validate(); setState(() {}); },
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorTokens.surfaceSubtle,
                          foregroundColor: AppColorTokens.textPrimary,
                          disabledBackgroundColor: AppColorTokens.surfaceSubtle,
                          disabledForegroundColor: AppColorTokens.textMuted,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadiusTokens.lg)),
                        ),
                        child: const Text('创建账号', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.pushReplacementNamed(context, WalletRoutes.ovdAuthLogin),
                      child: Text('已有账号？去登录', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.obscureText,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColorTokens.background,
            borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
            border: Border.all(color: errorText != null ? AppColorTokens.danger : AppColorTokens.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: AppTypographyTokens.body.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypographyTokens.body.copyWith(color: AppColorTokens.textMuted, fontWeight: FontWeight.w600),
              border: InputBorder.none,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColorTokens.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
