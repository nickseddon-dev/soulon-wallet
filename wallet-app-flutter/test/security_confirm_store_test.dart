import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app_flutter/state/security_interop_demo_store.dart';

void main() {
  final SecurityConfirmStore store = SecurityConfirmStore.instance;

  setUp(() {
    store.reset();
    store.resetBiometricFactor();
  });

  test('未完成生物识别时拒绝高风险确认', () async {
    final beforeCount = store.value.auditEvents.length;
    await expectLater(
      () => store.confirm(
        operation: '转账',
        amount: '1.25',
        pin: '123456',
        method: BiometricMethod.faceId,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(store.value.auditEvents.length, greaterThan(beforeCount));
    expect(store.value.auditEvents.first.success, isFalse);
  });

  test('完成双因子后生成授权结果与审计事件', () async {
    final beforeCount = store.value.auditEvents.length;
    await store.verifyBiometricFactor(
      operation: '转账',
      amount: '2.00',
      method: BiometricMethod.faceId,
    );
    await store.confirm(
      operation: '转账',
      amount: '2.00',
      pin: '123456',
      method: BiometricMethod.faceId,
    );
    final state = store.value;
    expect(state.pinVerified, isTrue);
    expect(state.biometricVerified, isTrue);
    expect(state.pinProvisioned, isTrue);
    expect(state.result, isNotNull);
    expect(state.result!.auditEventId, isNotEmpty);
    expect(state.auditEvents.length, greaterThan(beforeCount));
    expect(state.auditEvents.first.success, isTrue);
  });

  test('错误PIN会被拦截并记录失败审计', () async {
    await store.verifyBiometricFactor(
      operation: '质押',
      amount: '3.50',
      method: BiometricMethod.fingerprint,
    );
    await store.confirm(
      operation: '质押',
      amount: '3.50',
      pin: '123456',
      method: BiometricMethod.fingerprint,
    );
    final beforeCount = store.value.auditEvents.length;

    await store.verifyBiometricFactor(
      operation: '质押',
      amount: '3.50',
      method: BiometricMethod.fingerprint,
    );
    await expectLater(
      () => store.confirm(
        operation: '质押',
        amount: '3.50',
        pin: '000000',
        method: BiometricMethod.fingerprint,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(store.value.auditEvents.length, greaterThan(beforeCount));
    expect(store.value.auditEvents.first.success, isFalse);
    expect(store.value.auditEvents.first.reason, 'PIN 校验失败');
  });
}
