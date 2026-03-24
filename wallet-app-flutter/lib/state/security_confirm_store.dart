import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum BiometricMethod { faceId, fingerprint }

enum SecureCredentialBackend { androidKeystore, iosKeychain, secureFallback }

enum RiskLevel { high, critical }

class SecureCredentialMeta {
  const SecureCredentialMeta({
    required this.backend,
    required this.alias,
    required this.createdAt,
  });

  final SecureCredentialBackend backend;
  final String alias;
  final DateTime createdAt;
}

abstract class PinCredentialStore {
  Future<void> provision(String alias, String digest);
  Future<String?> retrieve(String alias);
  Future<void> delete(String alias);
}

class MethodChannelPinCredentialStore implements PinCredentialStore {
  const MethodChannelPinCredentialStore(this._channel);

  final MethodChannel _channel;

  @override
  Future<void> provision(String alias, String digest) async {
    await _channel.invokeMethod<void>('provisionPin', {
      'alias': alias,
      'digest': digest,
    });
  }

  @override
  Future<String?> retrieve(String alias) async {
    final result = await _channel.invokeMethod<String>('retrievePin', {
      'alias': alias,
    });
    return result;
  }

  @override
  Future<void> delete(String alias) async {
    await _channel.invokeMethod<void>('deletePin', {
      'alias': alias,
    });
  }
}

class InMemoryPinCredentialStore implements PinCredentialStore {
  final Map<String, String> _store = {};

  @override
  Future<void> provision(String alias, String digest) async {
    _store[alias] = digest;
  }

  @override
  Future<String?> retrieve(String alias) async {
    return _store[alias];
  }

  @override
  Future<void> delete(String alias) async {
    _store.remove(alias);
  }
}

class HardwareKeyStoreFacade {
  HardwareKeyStoreFacade() : _pinStore = InMemoryPinCredentialStore();

  final PinCredentialStore _pinStore;

  SecureCredentialBackend get backend => SecureCredentialBackend.secureFallback;

  Future<void> provisionPin(String alias, String digest) {
    return _pinStore.provision(alias, digest);
  }

  Future<String?> retrievePin(String alias) {
    return _pinStore.retrieve(alias);
  }

  Future<void> deletePin(String alias) {
    return _pinStore.delete(alias);
  }
}

class BiometricAssertion {
  const BiometricAssertion({
    required this.method,
    required this.verified,
    required this.assertedAt,
  });

  final BiometricMethod method;
  final bool verified;
  final DateTime assertedAt;
}

abstract class BiometricVerifier {
  Future<BiometricAssertion> verify(BiometricMethod method);
}

class MethodChannelBiometricVerifier implements BiometricVerifier {
  const MethodChannelBiometricVerifier(this._channel);

  final MethodChannel _channel;

  @override
  Future<BiometricAssertion> verify(BiometricMethod method) async {
    final result = await _channel.invokeMethod<bool>('verifyBiometric', {
      'method': method.name,
    });
    return BiometricAssertion(
      method: method,
      verified: result ?? false,
      assertedAt: DateTime.now(),
    );
  }
}

class SimulatedBiometricVerifier implements BiometricVerifier {
  @override
  Future<BiometricAssertion> verify(BiometricMethod method) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return BiometricAssertion(
      method: method,
      verified: true,
      assertedAt: DateTime.now(),
    );
  }
}

class SecurityAuditEvent {
  const SecurityAuditEvent({
    required this.eventId,
    required this.operation,
    required this.amount,
    required this.riskLevel,
    required this.pinVerified,
    required this.biometricVerified,
    required this.success,
    required this.createdAt,
    this.reason,
  });

  final String eventId;
  final String operation;
  final String amount;
  final RiskLevel riskLevel;
  final bool pinVerified;
  final bool biometricVerified;
  final bool success;
  final DateTime createdAt;
  final String? reason;
}

abstract class SecurityAuditRepository {
  void append(SecurityAuditEvent event);
  List<SecurityAuditEvent> list();
  void clear();
}

class InMemorySecurityAuditRepository implements SecurityAuditRepository {
  final List<SecurityAuditEvent> _events = [];

  @override
  void append(SecurityAuditEvent event) {
    _events.insert(0, event);
  }

  @override
  List<SecurityAuditEvent> list() {
    return List.unmodifiable(_events);
  }

  @override
  void clear() {
    _events.clear();
  }
}

class SecurityConfirmResult {
  const SecurityConfirmResult({
    required this.operation,
    required this.amount,
    required this.biometricMethod,
    required this.requestId,
    required this.auditEventId,
    required this.storageBackend,
    required this.authorizedAt,
  });

  final String operation;
  final String amount;
  final BiometricMethod biometricMethod;
  final String requestId;
  final String auditEventId;
  final SecureCredentialBackend storageBackend;
  final DateTime authorizedAt;
}

class SecurityConfirmState {
  const SecurityConfirmState({
    required this.pinVerified,
    required this.biometricVerified,
    required this.pinProvisioned,
    required this.secureBackend,
    required this.auditEvents,
    this.result,
    this.loading = false,
    this.errorText,
  });

  final bool pinVerified;
  final bool biometricVerified;
  final bool pinProvisioned;
  final SecureCredentialBackend secureBackend;
  final List<SecurityAuditEvent> auditEvents;
  final SecurityConfirmResult? result;
  final bool loading;
  final String? errorText;

  SecurityConfirmState copyWith({
    bool? pinVerified,
    bool? biometricVerified,
    bool? pinProvisioned,
    SecureCredentialBackend? secureBackend,
    List<SecurityAuditEvent>? auditEvents,
    SecurityConfirmResult? result,
    bool clearResult = false,
    bool? loading,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return SecurityConfirmState(
      pinVerified: pinVerified ?? this.pinVerified,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      pinProvisioned: pinProvisioned ?? this.pinProvisioned,
      secureBackend: secureBackend ?? this.secureBackend,
      auditEvents: auditEvents ?? this.auditEvents,
      result: clearResult ? null : (result ?? this.result),
      loading: loading ?? this.loading,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class SecurityConfirmStore extends ValueNotifier<SecurityConfirmState> {
  SecurityConfirmStore._({
    required HardwareKeyStoreFacade keyStore,
    required BiometricVerifier biometricVerifier,
    required SecurityAuditRepository auditRepository,
  })  : _keyStore = keyStore,
        _biometricVerifier = biometricVerifier,
        _auditRepository = auditRepository,
        _random = Random.secure(),
        super(
          SecurityConfirmState(
            pinVerified: false,
            biometricVerified: false,
            pinProvisioned: false,
            secureBackend: keyStore.backend,
            auditEvents: const [],
          ),
        );

  static final SecurityConfirmStore instance = SecurityConfirmStore._(
    keyStore: HardwareKeyStoreFacade(),
    biometricVerifier: SimulatedBiometricVerifier(),
    auditRepository: InMemorySecurityAuditRepository(),
  );

  final HardwareKeyStoreFacade _keyStore;
  final BiometricVerifier _biometricVerifier;
  final SecurityAuditRepository _auditRepository;
  final Random _random;

  static const _pinAlias = 'soulon_wallet_pin';
  static const _biometricTtl = Duration(minutes: 2);

  static const _highRiskOperations = {
    '转账',
    '质押',
    '治理投票',
    'IBC 跨链',
    '多签提交',
  };

  DateTime? _lastBiometricAt;

  Future<void> verifyBiometricFactor({
    required String operation,
    required String amount,
    required BiometricMethod method,
  }) async {
    value = value.copyWith(loading: true, clearErrorText: true);
    try {
      final assertion = await _biometricVerifier.verify(method);
      if (!assertion.verified) {
        throw const FormatException('生物识别校验失败');
      }
      _lastBiometricAt = assertion.assertedAt;
      value = value.copyWith(
        biometricVerified: true,
        loading: false,
      );
    } catch (error) {
      value = value.copyWith(loading: false);
      if (error is FormatException) {
        rethrow;
      }
      throw const FormatException('生物识别校验失败');
    }
  }

  void resetBiometricFactor() {
    _lastBiometricAt = null;
    value = value.copyWith(
      biometricVerified: false,
      clearResult: true,
      clearErrorText: true,
    );
  }

  Future<void> confirm({
    required String operation,
    required String amount,
    required String pin,
    required BiometricMethod method,
  }) async {
    _requireOperation(operation);
    _requireAmount(amount);
    _requirePin(pin);

    final riskLevel = _highRiskOperations.contains(operation)
        ? RiskLevel.high
        : RiskLevel.critical;

    if (!_validateBiometricAssertion()) {
      final event = SecurityAuditEvent(
        eventId: 'AUD-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}',
        operation: operation,
        amount: amount,
        riskLevel: riskLevel,
        pinVerified: false,
        biometricVerified: false,
        success: false,
        createdAt: DateTime.now(),
        reason: '生物识别未通过或已过期',
      );
      _auditRepository.append(event);
      value = value.copyWith(auditEvents: _auditRepository.list());
      throw const FormatException('请先完成生物识别校验');
    }

    value = value.copyWith(loading: true, clearErrorText: true);

    try {
      final pinOk = await _verifyOrProvisionPin(pin);
      if (!pinOk) {
        final event = SecurityAuditEvent(
          eventId: 'AUD-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}',
          operation: operation,
          amount: amount,
          riskLevel: riskLevel,
          pinVerified: false,
          biometricVerified: true,
          success: false,
          createdAt: DateTime.now(),
          reason: 'PIN 校验失败',
        );
        _auditRepository.append(event);
        value = value.copyWith(
          loading: false,
          auditEvents: _auditRepository.list(),
        );
        throw const FormatException('PIN 校验失败');
      }

      final auditEventId = 'AUD-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}';
      final requestId = _digest('${DateTime.now().microsecondsSinceEpoch}|$operation|$amount');

      final confirmResult = SecurityConfirmResult(
        operation: operation,
        amount: amount,
        biometricMethod: method,
        requestId: requestId,
        auditEventId: auditEventId,
        storageBackend: _keyStore.backend,
        authorizedAt: DateTime.now(),
      );

      final event = SecurityAuditEvent(
        eventId: auditEventId,
        operation: operation,
        amount: amount,
        riskLevel: riskLevel,
        pinVerified: true,
        biometricVerified: true,
        success: true,
        createdAt: DateTime.now(),
      );
      _auditRepository.append(event);

      value = value.copyWith(
        pinVerified: true,
        pinProvisioned: true,
        loading: false,
        result: confirmResult,
        auditEvents: _auditRepository.list(),
      );
    } catch (error) {
      if (error is FormatException) {
        value = value.copyWith(loading: false);
        rethrow;
      }
      value = value.copyWith(loading: false);
      throw const FormatException('确认流程失败，请稍后重试');
    }
  }

  void reset() {
    _lastBiometricAt = null;
    _auditRepository.clear();
    value = SecurityConfirmState(
      pinVerified: false,
      biometricVerified: false,
      pinProvisioned: false,
      secureBackend: _keyStore.backend,
      auditEvents: const [],
    );
  }

  String _digest(String seed) {
    final bytes = utf8.encode('soulon.wallet.pin.v1:$seed');
    final hash = sha256.convert(bytes);
    return base64Url.encode(hash.bytes);
  }

  void _requireOperation(String operation) {
    if (operation.trim().isEmpty) {
      throw const FormatException('操作类型不能为空');
    }
  }

  void _requireAmount(String amount) {
    final parsed = double.tryParse(amount.trim());
    if (parsed == null || parsed <= 0) {
      throw const FormatException('金额必须大于 0');
    }
  }

  void _requirePin(String pin) {
    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('PIN 必须为 6 位数字');
    }
  }

  Future<bool> _verifyOrProvisionPin(String pin) async {
    final pinDigest = _digest(pin);
    final stored = await _keyStore.retrievePin(_pinAlias);
    if (stored == null) {
      await _keyStore.provisionPin(_pinAlias, pinDigest);
      return true;
    }
    return stored == pinDigest;
  }

  bool _validateBiometricAssertion() {
    if (_lastBiometricAt == null) {
      return false;
    }
    final elapsed = DateTime.now().difference(_lastBiometricAt!);
    return elapsed <= _biometricTtl;
  }
}
