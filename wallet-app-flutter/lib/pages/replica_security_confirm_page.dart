import 'package:flutter/material.dart';

import '../theme/tokens/app_color_tokens.dart';
import '../theme/tokens/app_motion_tokens.dart';

class ReplicaSecurityConfirmPage extends StatefulWidget {
  const ReplicaSecurityConfirmPage({super.key});

  @override
  State<ReplicaSecurityConfirmPage> createState() => _ReplicaSecurityConfirmPageState();
}

class _ReplicaSecurityConfirmPageState extends State<ReplicaSecurityConfirmPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _biometricPassed = false;
  bool _verifying = false;
  String? _errorText;
  String? _resultText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      appBar: AppBar(
        title: const Text('安全确认'),
        backgroundColor: const Color(0xFF070B12),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A101A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1D2430)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PIN 码', style: TextStyle(color: AppColorTokens.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '输入 6 位 PIN',
                    filled: true,
                    fillColor: const Color(0xFF121B2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF253348)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF253348)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111A28),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF243247)),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('生物识别已通过', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: AnimatedSwitcher(
                      duration: AppMotionTokens.fast,
                      child: Text(
                        _biometricPassed ? '已通过本地生物识别校验' : '请先完成生物识别验证',
                        key: ValueKey(_biometricPassed),
                      ),
                    ),
                    value: _biometricPassed,
                    onChanged: _verifying ? null : (value) => setState(() => _biometricPassed = value),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D7BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_verifying ? '验证中...' : '验证并确认', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotionTokens.normal,
                  reverseDuration: AppMotionTokens.fast,
                  child: _errorText != null
                      ? Container(
                          key: ValueKey(_errorText),
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x2AEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x66EF4444)),
                          ),
                          child: Text(
                            _errorText!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.danger),
                          ),
                        )
                      : _resultText != null
                          ? Container(
                              key: ValueKey(_resultText),
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x2222C55E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0x6642D77D)),
                              ),
                              child: Text(
                                _resultText!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorTokens.success),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    await Future<void>.delayed(AppMotionTokens.fast);
    if (!mounted) {
      return;
    }
    final pin = _pinController.text.trim();
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() {
        _verifying = false;
        _errorText = 'PIN 需为 6 位数字';
        _resultText = null;
      });
      return;
    }
    if (!_biometricPassed) {
      setState(() {
        _verifying = false;
        _errorText = '请先完成人脸或指纹确认';
        _resultText = null;
      });
      return;
    }
    setState(() {
      _verifying = false;
      _errorText = null;
      _resultText = '安全确认通过，可继续执行敏感操作';
    });
  }
}
