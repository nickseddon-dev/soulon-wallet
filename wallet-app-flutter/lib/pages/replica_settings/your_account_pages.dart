import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../theme/tokens/app_color_tokens.dart';
import 'replica_settings_widgets.dart';

final class ReplicaYourAccountPage extends StatelessWidget {
  const ReplicaYourAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Your Account',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReplicaSettingsPlaceholderCard(
            title: 'Account 1',
            description: '0x71C...978b',
          ),
          const SizedBox(height: 24),
          ReplicaSettingsGroup(
            title: 'Account',
            children: [
              ReplicaSettingsActionTile(
                icon: Icons.edit_outlined,
                title: 'Update Account Name',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsAccountUpdateName),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsAccountChangePassword),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.warning_amber_rounded,
                title: 'Show Recovery Phrase',
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsShowRecoveryPhraseWarning),
              ),
              const ReplicaSettingsDivider(),
              ReplicaSettingsActionTile(
                icon: Icons.delete_outline,
                title: 'Remove Account',
                textColor: AppColorTokens.danger,
                iconColor: AppColorTokens.danger,
                onTap: () => Navigator.pushNamed(context, WalletRoutes.replicaSettingsAccountRemove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class ReplicaUpdateAccountNamePage extends StatefulWidget {
  const ReplicaUpdateAccountNamePage({super.key});

  @override
  State<ReplicaUpdateAccountNamePage> createState() => _ReplicaUpdateAccountNamePageState();
}

class _ReplicaUpdateAccountNamePageState extends State<ReplicaUpdateAccountNamePage> {
  final TextEditingController _controller = TextEditingController(text: 'Account 1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Update Account Name',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            style: const TextStyle(color: AppColorTokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: AppColorTokens.textSecondary),
              filled: true,
              fillColor: AppColorTokens.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColorTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColorTokens.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.primary,
              foregroundColor: AppColorTokens.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

final class ReplicaChangePasswordPage extends StatefulWidget {
  const ReplicaChangePasswordPage({super.key});

  @override
  State<ReplicaChangePasswordPage> createState() => _ReplicaChangePasswordPageState();
}

class _ReplicaChangePasswordPageState extends State<ReplicaChangePasswordPage> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final next = _next.text.trim();
    if (next.length < 6 || next != _confirm.text.trim()) {
      setState(() => _error = 'Mock 校验失败：密码至少 6 位且两次输入一致');
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Change Password',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PasswordField(controller: _current, label: 'Current Password'),
          const SizedBox(height: 12),
          _PasswordField(controller: _next, label: 'New Password'),
          const SizedBox(height: 12),
          _PasswordField(controller: _confirm, label: 'Confirm Password'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColorTokens.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.primary,
              foregroundColor: AppColorTokens.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

final class ReplicaShowRecoveryPhraseWarningPage extends StatelessWidget {
  const ReplicaShowRecoveryPhraseWarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Show Recovery Phrase',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReplicaSettingsPlaceholderCard(
            title: '警告',
            description: '恢复短语可以完全控制你的资产。请确保周围无人窥视，且不要截图、不要分享。',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColorTokens.surface,
                  title: const Text('Mock 模式', style: TextStyle(color: AppColorTokens.textPrimary)),
                  content: const Text(
                    '此项目当前为 UI 复刻占位，不展示真实恢复短语。',
                    style: TextStyle(color: AppColorTokens.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: AppColorTokens.accent)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.primary,
              foregroundColor: AppColorTokens.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

final class ReplicaRemoveAccountPage extends StatelessWidget {
  const ReplicaRemoveAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReplicaSettingsScaffold(
      title: 'Remove Account',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ReplicaSettingsPlaceholderCard(
            title: '确认移除账户（占位）',
            description: '该操作将移除本地账户数据。此处仅提供 UI 占位，不执行真实删除。',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorTokens.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: AppColorTokens.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColorTokens.textSecondary),
        filled: true,
        fillColor: AppColorTokens.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColorTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColorTokens.accent),
        ),
      ),
    );
  }
}

