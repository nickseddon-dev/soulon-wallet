import 'package:flutter/material.dart';

import '../state/security_interop_demo_store.dart';
import '../theme/tokens/app_color_tokens.dart';
import '../widgets/buttons/wallet_primary_button.dart';
import '../widgets/cards/wallet_card.dart';
import '../widgets/inputs/wallet_text_field.dart';

class PinBiometricConfirmPage extends StatefulWidget {
  const PinBiometricConfirmPage({super.key});

  @override
  State<PinBiometricConfirmPage> createState() => _PinBiometricConfirmPageState();
}

class _PinBiometricConfirmPageState extends State<PinBiometricConfirmPage> {
  final SecurityConfirmStore _store = SecurityConfirmStore.instance;
  final TextEditingController _amountController = TextEditingController(text: '18.80');
  final TextEditingController _pinController = TextEditingController();
  String _operation = '转账';
  BiometricMethod _method = BiometricMethod.faceId;
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _simulateBiometricCheck() async {
    setState(() => _errorText = null);
    try {
      await _store.verifyBiometricFactor(
        operation: _operation,
        amount: _amountController.text,
        method: _method,
      );
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  Future<void> _confirm() async {
    setState(() => _errorText = null);
    try {
      await _store.confirm(
        operation: _operation,
        amount: _amountController.text,
        pin: _pinController.text,
        method: _method,
      );
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SecurityConfirmState>(
      valueListenable: _store,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('PIN/生物识别二次确认')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WalletCard(
                title: '资产变更确认',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_operation),
                      initialValue: _operation,
                      items: const [
                        DropdownMenuItem(value: '转账', child: Text('转账')),
                        DropdownMenuItem(value: '质押', child: Text('质押')),
                        DropdownMenuItem(value: '治理投票', child: Text('治理投票')),
                        DropdownMenuItem(value: 'IBC 跨链', child: Text('IBC 跨链')),
                        DropdownMenuItem(value: '多签提交', child: Text('多签提交')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _operation = value;
                          _errorText = null;
                        });
                        _store.resetBiometricFactor();
                      },
                      decoration: const InputDecoration(labelText: '操作类型'),
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '变更金额（SOUL）',
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      controller: _amountController,
                    ),
                    const SizedBox(height: 10),
                    WalletTextField(
                      label: '6位 PIN',
                      hintText: '请输入 6 位数字',
                      keyboardType: TextInputType.number,
                      controller: _pinController,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<BiometricMethod>(
                      key: ValueKey(_method),
                      initialValue: _method,
                      items: const [
                        DropdownMenuItem(value: BiometricMethod.faceId, child: Text('FaceID')),
                        DropdownMenuItem(value: BiometricMethod.fingerprint, child: Text('Fingerprint')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _method = value;
                          _errorText = null;
                        });
                        _store.resetBiometricFactor();
                      },
                      decoration: const InputDecoration(labelText: '生物识别方式'),
                    ),
                    const SizedBox(height: 12),
                    WalletPrimaryButton(
                      label: state.biometricVerified ? '生物识别校验已通过' : '模拟生物识别校验',
                      onPressed: state.loading ? null : _simulateBiometricCheck,
                    ),
                    const SizedBox(height: 10),
                    WalletPrimaryButton(
                      label: '确认资产变更',
                      loading: state.loading,
                      onPressed: state.loading ? null : _confirm,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '确认进度',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _stageChip('PIN 校验', state.pinVerified),
                    _stageChip('生物识别', state.biometricVerified),
                    _stageChip('Keystore/Keychain', state.pinProvisioned),
                    _stageChip('签名授权', state.result != null),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WalletCard(
                title: '密钥安全状态',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN 存储状态: ${state.pinProvisioned ? '已写入硬件安全存储' : '尚未初始化'}'),
                    Text('安全后端: ${_backendLabel(state.secureBackend)}'),
                  ],
                ),
              ),
              if (state.result != null) ...[
                const SizedBox(height: 16),
                WalletCard(
                  title: '授权结果',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('操作: ${state.result!.operation}'),
                      Text('金额: ${state.result!.amount} SOUL'),
                      Text('识别方式: ${_methodLabel(state.result!.biometricMethod)}'),
                      Text('requestId: ${state.result!.requestId}'),
                      Text('auditEventId: ${state.result!.auditEventId}'),
                      Text('密钥后端: ${_backendLabel(state.result!.storageBackend)}'),
                      Text('授权时间: ${state.result!.authorizedAt.toIso8601String()}'),
                    ],
                  ),
                ),
              ],
              if (state.auditEvents.isNotEmpty) ...[
                const SizedBox(height: 16),
                WalletCard(
                  title: '高风险操作审计事件',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final event in state.auditEvents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '[${event.success ? '通过' : '拦截'}] ${event.operation} ${event.amount} SOUL'
                            ' | ${_riskLabel(event.riskLevel)} | PIN:${event.pinVerified ? 'Y' : 'N'}'
                            ' BIO:${event.biometricVerified ? 'Y' : 'N'} | ${event.eventId}'
                            '${event.reason == null ? '' : ' | ${event.reason}'}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stageChip(String label, bool done) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        done ? Icons.check_circle_rounded : Icons.schedule_rounded,
        size: 18,
        color: done ? AppColorTokens.success : AppColorTokens.warning,
      ),
    );
  }

  String _methodLabel(BiometricMethod method) {
    switch (method) {
      case BiometricMethod.faceId:
        return 'FaceID';
      case BiometricMethod.fingerprint:
        return 'Fingerprint';
    }
  }

  String _backendLabel(SecureCredentialBackend backend) {
    switch (backend) {
      case SecureCredentialBackend.androidKeystore:
        return 'Android Keystore';
      case SecureCredentialBackend.iosKeychain:
        return 'iOS Keychain';
      case SecureCredentialBackend.secureFallback:
        return 'Secure Fallback';
    }
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }
}
