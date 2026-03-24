import 'package:flutter/material.dart';

import '../app/app_router.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_radius_tokens.dart';
import '../theme/tokens/app_spacing_tokens.dart';
import '../theme/tokens/app_typography_tokens.dart';

final class OvdAuthLoginPage extends StatefulWidget {
  const OvdAuthLoginPage({super.key});

  @override
  State<OvdAuthLoginPage> createState() => _OvdAuthLoginPageState();
}

class _OvdAuthLoginPageState extends State<OvdAuthLoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.trim().isNotEmpty && _password.text.trim().isNotEmpty;

  void _submit() {
    Navigator.pushReplacementNamed(context, WalletRoutes.ovdLauncher);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTokens.background,
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
                      '登录',
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
                      onChanged: (_) => setState(() {}),
                      obscureText: false,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _password,
                      hint: '密码',
                      onChanged: (_) => setState(() {}),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: '之前没有用过？ ',
                              style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary),
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: InkWell(
                                    onTap: () => Navigator.pushNamed(context, WalletRoutes.ovdAuthRegister),
                                    child: const Text('注册', style: TextStyle(color: AppColorTokens.accent, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon'))),
                          child: Text('忘记密码', style: AppTypographyTokens.body.copyWith(color: AppColorTokens.textSecondary, fontWeight: FontWeight.w800)),
                        ),
                      ],
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
                        child: const Text('登录', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
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
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColorTokens.background,
        borderRadius: BorderRadius.circular(AppRadiusTokens.lg),
        border: Border.all(color: AppColorTokens.border),
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
    );
  }
}

