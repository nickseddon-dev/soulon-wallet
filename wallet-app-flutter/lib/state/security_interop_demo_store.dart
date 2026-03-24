import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';
import 'transaction_demo_store.dart';

enum BiometricMethod { faceId, fingerprint }

enum SecureCredentialBackend { androidKeystore, iosKeychain, secureFallback }

enum RiskLevel { high, critical }

class SecureCredentialMeta {
  const SecureCredentialMeta({
    required this.backend,
    required this.keyAlias,
    required this.storedAt,
  });

  final SecureCredentialBackend backend;
  final String keyAlias;
  final DateTime storedAt;
}

abstract class PinCredentialStore {
  Future<SecureCredentialMeta> writePinDigest({
    required String alias,
    required String digest,
  });

  Future<String?> readPinDigest(String alias);
}

class MethodChannelPinCredentialStore implements PinCredentialStore {
  MethodChannelPinCredentialStore()
      : _channel = const MethodChannel('soulon.wallet/security.keystore');

  final MethodChannel _channel;

  @override
  Future<SecureCredentialMeta> writePinDigest({
    required String alias,
    required String digest,
  }) async {
    final response =
        await _channel.invokeMethod<Map<Object?, Object?>>('writePinDigest', {
      'alias': alias,
      'digest': digest,
    });
    if (response == null) {
      throw MissingPluginException('Keystore/Keychain channel unavailable');
    }
    final backendName = (response['backend'] as String?) ?? 'secureFallback';
    final storedAtText = (response['storedAt'] as String?) ?? DateTime.now().toIso8601String();
    return SecureCredentialMeta(
      backend: _backendFromText(backendName),
      keyAlias: (response['keyAlias'] as String?) ?? alias,
      storedAt: DateTime.tryParse(storedAtText) ?? DateTime.now(),
    );
  }

  @override
  Future<String?> readPinDigest(String alias) async {
    final response = await _channel
        .invokeMethod<Map<Object?, Object?>>('readPinDigest', {'alias': alias});
    if (response == null) {
      throw MissingPluginException('Keystore/Keychain channel unavailable');
    }
    return response['digest'] as String?;
  }

  SecureCredentialBackend _backendFromText(String input) {
    switch (input) {
      case 'androidKeystore':
        return SecureCredentialBackend.androidKeystore;
      case 'iosKeychain':
        return SecureCredentialBackend.iosKeychain;
      default:
        return SecureCredentialBackend.secureFallback;
    }
  }
}

class InMemoryPinCredentialStore implements PinCredentialStore {
  final Map<String, String> _pinDigestByAlias = <String, String>{};
  final Map<String, SecureCredentialMeta> _metaByAlias = <String, SecureCredentialMeta>{};

  @override
  Future<SecureCredentialMeta> writePinDigest({
    required String alias,
    required String digest,
  }) async {
    _pinDigestByAlias[alias] = digest;
    final meta = SecureCredentialMeta(
      backend: SecureCredentialBackend.secureFallback,
      keyAlias: alias,
      storedAt: DateTime.now(),
    );
    _metaByAlias[alias] = meta;
    return meta;
  }

  @override
  Future<String?> readPinDigest(String alias) async => _pinDigestByAlias[alias];
}

class HardwareKeyStoreFacade {
  HardwareKeyStoreFacade({
    PinCredentialStore? platformStore,
    PinCredentialStore? fallbackStore,
  })  : _platformStore = platformStore ?? MethodChannelPinCredentialStore(),
        _fallbackStore = fallbackStore ?? InMemoryPinCredentialStore();

  static const String pinAlias = 'wallet.high_risk.pin.v1';
  final PinCredentialStore _platformStore;
  final PinCredentialStore _fallbackStore;
  SecureCredentialMeta? _lastMeta;

  SecureCredentialBackend get lastBackend =>
      _lastMeta?.backend ?? SecureCredentialBackend.secureFallback;

  Future<SecureCredentialMeta> writePinDigest(String digest) async {
    try {
      final meta = await _platformStore.writePinDigest(alias: pinAlias, digest: digest);
      _lastMeta = meta;
      return meta;
    } catch (_) {
      final meta = await _fallbackStore.writePinDigest(alias: pinAlias, digest: digest);
      _lastMeta = meta;
      return meta;
    }
  }

  Future<String?> readPinDigest() async {
    try {
      return await _platformStore.readPinDigest(pinAlias);
    } catch (_) {
      return _fallbackStore.readPinDigest(pinAlias);
    }
  }
}

class BiometricAssertion {
  const BiometricAssertion({
    required this.operation,
    required this.amount,
    required this.method,
    required this.provider,
    required this.assertionId,
    required this.verifiedAt,
  });

  final String operation;
  final String amount;
  final BiometricMethod method;
  final String provider;
  final String assertionId;
  final DateTime verifiedAt;
}

abstract class BiometricVerifier {
  Future<BiometricAssertion> verify({
    required String operation,
    required String amount,
    required BiometricMethod method,
  });
}

class MethodChannelBiometricVerifier implements BiometricVerifier {
  MethodChannelBiometricVerifier()
      : _channel = const MethodChannel('soulon.wallet/security.biometric');

  final MethodChannel _channel;

  @override
  Future<BiometricAssertion> verify({
    required String operation,
    required String amount,
    required BiometricMethod method,
  }) async {
    final response =
        await _channel.invokeMethod<Map<Object?, Object?>>('verifyBiometric', {
      'operation': operation,
      'amount': amount,
      'method': method.name,
    });
    if (response == null) {
      throw MissingPluginException('Biometric channel unavailable');
    }
    return BiometricAssertion(
      operation: operation,
      amount: amount,
      method: method,
      provider: (response['provider'] as String?) ?? 'native_biometric',
      assertionId: (response['assertionId'] as String?) ?? 'native-assertion',
      verifiedAt: DateTime.tryParse((response['verifiedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class SimulatedBiometricVerifier implements BiometricVerifier {
  SimulatedBiometricVerifier({required Random random}) : _random = random;

  final Random _random;

  @override
  Future<BiometricAssertion> verify({
    required String operation,
    required String amount,
    required BiometricMethod method,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final suffix = (_random.nextInt(900000) + 100000).toString();
    return BiometricAssertion(
      operation: operation,
      amount: amount,
      method: method,
      provider: 'simulated-secure-enclave',
      assertionId: 'bio-$suffix',
      verifiedAt: DateTime.now(),
    );
  }
}

class SecurityAuditEvent {
  const SecurityAuditEvent({
    required this.eventId,
    required this.operation,
    required this.amount,
    required this.success,
    required this.riskLevel,
    required this.pinVerified,
    required this.biometricVerified,
    required this.storageBackend,
    required this.occurredAt,
    this.reason,
  });

  final String eventId;
  final String operation;
  final String amount;
  final bool success;
  final RiskLevel riskLevel;
  final bool pinVerified;
  final bool biometricVerified;
  final SecureCredentialBackend storageBackend;
  final DateTime occurredAt;
  final String? reason;
}

abstract class SecurityAuditRepository {
  Future<void> append(SecurityAuditEvent event);

  List<SecurityAuditEvent> latest({int limit = 8});
}

class InMemorySecurityAuditRepository implements SecurityAuditRepository {
  final List<SecurityAuditEvent> _events = <SecurityAuditEvent>[];

  @override
  Future<void> append(SecurityAuditEvent event) async {
    _events.insert(0, event);
  }

  @override
  List<SecurityAuditEvent> latest({int limit = 8}) {
    return _events.take(limit).toList(growable: false);
  }
}

class SecurityConfirmResult {
  const SecurityConfirmResult({
    required this.operation,
    required this.amount,
    required this.biometricMethod,
    required this.requestId,
    required this.authorizedAt,
    required this.auditEventId,
    required this.storageBackend,
  });

  final String operation;
  final String amount;
  final BiometricMethod biometricMethod;
  final String requestId;
  final DateTime authorizedAt;
  final String auditEventId;
  final SecureCredentialBackend storageBackend;
}

class SecurityConfirmState {
  const SecurityConfirmState({
    this.loading = false,
    this.pinVerified = false,
    this.biometricVerified = false,
    this.result,
    this.errorText,
    this.biometricAssertion,
    this.auditEvents = const <SecurityAuditEvent>[],
    this.secureBackend = SecureCredentialBackend.secureFallback,
    this.pinProvisioned = false,
  });

  final bool loading;
  final bool pinVerified;
  final bool biometricVerified;
  final SecurityConfirmResult? result;
  final String? errorText;
  final BiometricAssertion? biometricAssertion;
  final List<SecurityAuditEvent> auditEvents;
  final SecureCredentialBackend secureBackend;
  final bool pinProvisioned;

  SecurityConfirmState copyWith({
    bool? loading,
    bool? pinVerified,
    bool? biometricVerified,
    SecurityConfirmResult? result,
    bool clearResult = false,
    String? errorText,
    bool clearErrorText = false,
    BiometricAssertion? biometricAssertion,
    bool clearBiometricAssertion = false,
    List<SecurityAuditEvent>? auditEvents,
    SecureCredentialBackend? secureBackend,
    bool? pinProvisioned,
  }) {
    return SecurityConfirmState(
      loading: loading ?? this.loading,
      pinVerified: pinVerified ?? this.pinVerified,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      result: clearResult ? null : (result ?? this.result),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      biometricAssertion:
          clearBiometricAssertion ? null : (biometricAssertion ?? this.biometricAssertion),
      auditEvents: auditEvents ?? this.auditEvents,
      secureBackend: secureBackend ?? this.secureBackend,
      pinProvisioned: pinProvisioned ?? this.pinProvisioned,
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
        super(
          SecurityConfirmState(
            secureBackend: keyStore.lastBackend,
            auditEvents: auditRepository.latest(),
          ),
        );

  static const Set<String> _highRiskOperations = <String>{
    '转账',
    '质押',
    '治理投票',
    'IBC 跨链',
    '多签提交',
  };
  static const Duration _biometricTtl = Duration(minutes: 2);

  static final SecurityConfirmStore instance = SecurityConfirmStore._(
    keyStore: HardwareKeyStoreFacade(),
    biometricVerifier: SimulatedBiometricVerifier(random: Random.secure()),
    auditRepository: InMemorySecurityAuditRepository(),
  );

  final HardwareKeyStoreFacade _keyStore;
  final BiometricVerifier _biometricVerifier;
  final SecurityAuditRepository _auditRepository;

  Future<void> verifyBiometricFactor({
    required String operation,
    required String amount,
    required BiometricMethod method,
  }) async {
    _requireOperation(operation);
    _requireAmount(amount);
    value = value.copyWith(
      loading: true,
      clearErrorText: true,
      clearBiometricAssertion: true,
      biometricVerified: false,
    );
    final assertion = await _biometricVerifier.verify(
      operation: operation.trim(),
      amount: amount.trim(),
      method: method,
    );
    value = value.copyWith(
      loading: false,
      biometricVerified: true,
      biometricAssertion: assertion,
    );
  }

  void resetBiometricFactor() {
    value = value.copyWith(
      biometricVerified: false,
      clearBiometricAssertion: true,
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
    final normalizedOperation = operation.trim();
    final normalizedAmount = amount.trim();

    value = value.copyWith(
      loading: true,
      pinVerified: false,
      biometricVerified: false,
      clearResult: true,
      clearErrorText: true,
    );
    try {
      final backend = await _verifyOrProvisionPin(pin: pin.trim());
      await Future<void>.delayed(const Duration(milliseconds: 120));
      value = value.copyWith(
        pinVerified: true,
        secureBackend: backend,
        pinProvisioned: true,
      );

      final assertion = _validateBiometricAssertion(
        operation: normalizedOperation,
        amount: normalizedAmount,
        method: method,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      value = value.copyWith(biometricVerified: true, biometricAssertion: assertion);

      final now = DateTime.now();
      final requestId =
          _digest('auth|$normalizedOperation|$normalizedAmount|${now.millisecondsSinceEpoch}');
      final eventId = _digest('audit|$requestId|success');
      await _auditRepository.append(
        SecurityAuditEvent(
          eventId: eventId,
          operation: normalizedOperation,
          amount: normalizedAmount,
          success: true,
          riskLevel: RiskLevel.critical,
          pinVerified: true,
          biometricVerified: true,
          storageBackend: backend,
          occurredAt: now,
        ),
      );
      value = value.copyWith(
        loading: false,
        auditEvents: _auditRepository.latest(),
        result: SecurityConfirmResult(
          operation: normalizedOperation,
          amount: normalizedAmount,
          biometricMethod: method,
          requestId: requestId,
          authorizedAt: now,
          auditEventId: eventId,
          storageBackend: backend,
        ),
      );
    } on FormatException catch (error) {
      final eventId = _digest(
        'audit|$normalizedOperation|$normalizedAmount|failed|${DateTime.now().millisecondsSinceEpoch}',
      );
      await _auditRepository.append(
        SecurityAuditEvent(
          eventId: eventId,
          operation: normalizedOperation,
          amount: normalizedAmount,
          success: false,
          riskLevel: RiskLevel.critical,
          pinVerified: value.pinVerified,
          biometricVerified: value.biometricVerified,
          storageBackend: value.secureBackend,
          reason: error.message,
          occurredAt: DateTime.now(),
        ),
      );
      value = value.copyWith(
        loading: false,
        auditEvents: _auditRepository.latest(),
        errorText: error.message,
      );
      rethrow;
    }
  }

  void reset() {
    value = SecurityConfirmState(
      secureBackend: value.secureBackend,
      pinProvisioned: value.pinProvisioned,
      auditEvents: _auditRepository.latest(),
    );
  }

  String _digest(String seed) {
    final bytes = utf8.encode(seed);
    final raw = bytes.fold<int>(0, (hash, code) => ((hash * 131) ^ code) & 0x7fffffff);
    return base64Url.encode(utf8.encode(raw.toRadixString(16))).replaceAll('=', '').toUpperCase();
  }

  void _requireOperation(String operation) {
    final normalizedOperation = operation.trim();
    if (normalizedOperation.isEmpty) {
      throw const FormatException('请选择资产变更操作');
    }
    if (!_highRiskOperations.contains(normalizedOperation)) {
      throw const FormatException('该操作未纳入高风险审计策略');
    }
  }

  void _requireAmount(String amount) {
    final normalizedAmount = amount.trim();
    if (normalizedAmount.isEmpty) {
      throw const FormatException('请输入变更金额');
    }
    final parsed = double.tryParse(normalizedAmount);
    if (parsed == null || parsed <= 0) {
      throw const FormatException('变更金额必须大于 0');
    }
  }

  void _requirePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin.trim())) {
      throw const FormatException('PIN 必须为 6 位数字');
    }
  }

  Future<SecureCredentialBackend> _verifyOrProvisionPin({required String pin}) async {
    final inputDigest = _digest(pin);
    final storedDigest = await _keyStore.readPinDigest();
    if (storedDigest == null) {
      final meta = await _keyStore.writePinDigest(inputDigest);
      return meta.backend;
    }
    if (storedDigest != inputDigest) {
      throw const FormatException('PIN 校验失败');
    }
    return _keyStore.lastBackend;
  }

  BiometricAssertion _validateBiometricAssertion({
    required String operation,
    required String amount,
    required BiometricMethod method,
  }) {
    final assertion = value.biometricAssertion;
    if (assertion == null) {
      throw const FormatException('请先完成生物识别校验');
    }
    if (assertion.method != method) {
      throw const FormatException('生物识别方式已变更，请重新校验');
    }
    if (assertion.operation != operation || assertion.amount != amount) {
      throw const FormatException('操作上下文已变更，请重新执行生物识别');
    }
    final elapsed = DateTime.now().difference(assertion.verifiedAt);
    if (elapsed > _biometricTtl) {
      throw const FormatException('生物识别已超时，请重新校验');
    }
    return assertion;
  }
}

class WalletConnectRequest {
  const WalletConnectRequest({
    required this.topic,
    required this.dappName,
    required this.uri,
    required this.chainId,
    required this.permissions,
    required this.riskHint,
  });

  final String topic;
  final String dappName;
  final String uri;
  final String chainId;
  final List<String> permissions;
  final String riskHint;
}

class WalletConnectSession {
  const WalletConnectSession({
    required this.sessionId,
    required this.topic,
    required this.dappName,
    required this.chainId,
    required this.connectedAt,
    required this.lastActiveAt,
  });

  final String sessionId;
  final String topic;
  final String dappName;
  final String chainId;
  final DateTime connectedAt;
  final DateTime lastActiveAt;

  WalletConnectSession copyWith({
    String? sessionId,
    DateTime? connectedAt,
    DateTime? lastActiveAt,
  }) {
    return WalletConnectSession(
      sessionId: sessionId ?? this.sessionId,
      topic: topic,
      dappName: dappName,
      chainId: chainId,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

class WalletConnectAuthorizeReceipt {
  const WalletConnectAuthorizeReceipt({
    required this.requestId,
    required this.signatureDigest,
    required this.authorizedAt,
    required this.challengePath,
    required this.confirmPath,
  });

  final String requestId;
  final String signatureDigest;
  final DateTime authorizedAt;
  final String challengePath;
  final String confirmPath;
}

class WalletConnectState {
  const WalletConnectState({
    required this.pendingRequest,
    required this.sessions,
    this.lastAuthorizeReceipt,
    this.loading = false,
    this.noticeText,
    this.errorText,
  });

  final WalletConnectRequest? pendingRequest;
  final List<WalletConnectSession> sessions;
  final WalletConnectAuthorizeReceipt? lastAuthorizeReceipt;
  final bool loading;
  final String? noticeText;
  final String? errorText;

  WalletConnectState copyWith({
    WalletConnectRequest? pendingRequest,
    bool clearPendingRequest = false,
    List<WalletConnectSession>? sessions,
    WalletConnectAuthorizeReceipt? lastAuthorizeReceipt,
    bool clearLastAuthorizeReceipt = false,
    bool? loading,
    String? noticeText,
    bool clearNoticeText = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return WalletConnectState(
      pendingRequest: clearPendingRequest ? null : (pendingRequest ?? this.pendingRequest),
      sessions: sessions ?? this.sessions,
      lastAuthorizeReceipt:
          clearLastAuthorizeReceipt ? null : (lastAuthorizeReceipt ?? this.lastAuthorizeReceipt),
      loading: loading ?? this.loading,
      noticeText: clearNoticeText ? null : (noticeText ?? this.noticeText),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class WalletConnectStore extends ValueNotifier<WalletConnectState> {
  WalletConnectStore._({
    required ChainApiClient apiClient,
    required String walletAddress,
  })  : _apiClient = apiClient,
        _walletAddress = walletAddress,
        super(
          WalletConnectState(
            pendingRequest: const WalletConnectRequest(
              topic: 'topic_840a',
              dappName: 'YieldHub Web DApp',
              uri: 'wc:topic_840a@2?relay-protocol=irn&symKey=***',
              chainId: 'soulon-testnet-1',
              permissions: ['cosmos_signDirect', 'cosmos_sendTx', 'cosmos_getAccounts'],
              riskHint: '授权后 DApp 可请求签名与交易广播，请确认域名可信。',
            ),
            sessions: [
              WalletConnectSession(
                sessionId: 'session-live-1',
                topic: 'topic_live_1',
                dappName: 'Governance Portal',
                chainId: 'soulon-testnet-1',
                connectedAt: DateTime(2026, 3, 5, 10, 20),
                lastActiveAt: DateTime(2026, 3, 5, 10, 48),
              ),
            ],
          ),
        );

  static final WalletConnectStore instance = WalletConnectStore._(
    apiClient: ChainApiClient(
      baseUrl: WalletRuntimeConfig.apiBaseUrl,
      timeout: WalletRuntimeConfig.requestTimeout,
    ),
    walletAddress: WalletRuntimeConfig.walletAddress,
  );
  final ChainApiClient _apiClient;
  final String _walletAddress;

  Future<void> approvePending() async {
    final request = value.pendingRequest;
    if (request == null) {
      throw const FormatException('当前没有待处理 WalletConnect 请求');
    }
    value = value.copyWith(
      loading: true,
      clearNoticeText: true,
      clearErrorText: true,
      clearLastAuthorizeReceipt: true,
    );
    final challenge = await _apiClient.postJson(
      ChainApiContract.authSignatureChallenge,
      body: {
        'accountId': _walletAddress,
        'topic': request.topic,
        'chainId': request.chainId,
        'dappName': request.dappName,
      },
    );
    final requestId = (challenge['requestId'] ?? '').toString();
    if (requestId.isEmpty) {
      throw const FormatException('WalletConnect 挑战创建失败');
    }
    final digest = _digest(
      '$requestId|${request.topic}|${request.chainId}|${request.permissions.join(",")}',
    );
    final signature = '$requestId.$_walletAddress.$digest';
    final confirm = await _apiClient.postJson(
      ChainApiContract.authSignatureConfirm,
      body: {
        'accountId': _walletAddress,
        'requestId': requestId,
        'signature': signature,
      },
    );
    final authorizedAt = DateTime.tryParse((confirm['authorizedAt'] ?? '').toString()) ?? DateTime.now();
    value = value.copyWith(
      loading: false,
      clearPendingRequest: true,
      sessions: [
        WalletConnectSession(
          sessionId: requestId,
          topic: request.topic,
          dappName: request.dappName,
          chainId: request.chainId,
          connectedAt: authorizedAt,
          lastActiveAt: authorizedAt,
        ),
        ...value.sessions,
      ],
      lastAuthorizeReceipt: WalletConnectAuthorizeReceipt(
        requestId: requestId,
        signatureDigest: digest,
        authorizedAt: authorizedAt,
        challengePath: ChainApiContract.authSignatureChallenge,
        confirmPath: ChainApiContract.authSignatureConfirm,
      ),
      noticeText: '已完成 ${request.dappName} 鉴权签名，会话已建立。',
    );
  }

  Future<void> rejectPending() async {
    final request = value.pendingRequest;
    if (request == null) {
      throw const FormatException('当前没有待处理 WalletConnect 请求');
    }
    value = value.copyWith(
      loading: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 160));
    value = value.copyWith(
      loading: false,
      clearPendingRequest: true,
      noticeText: '已拒绝 ${request.dappName} 的连接请求。',
    );
  }

  void disconnect(String topic) {
    final sessions = value.sessions.where((item) => item.topic != topic).toList(growable: false);
    value = value.copyWith(
      sessions: sessions,
      noticeText: '会话已断开：$topic',
      clearErrorText: true,
    );
  }

  void markActive(String topic) {
    unawaited(_markActive(topic));
  }

  Future<void> _markActive(String topic) async {
    try {
      await _apiClient.getJson(ChainApiContract.health);
      final sessions = value.sessions
          .map(
            (item) => item.topic == topic ? item.copyWith(lastActiveAt: DateTime.now()) : item,
          )
          .toList(growable: false);
      value = value.copyWith(
        sessions: sessions,
        noticeText: '已刷新会话活跃时间：$topic',
        clearErrorText: true,
      );
    } catch (error) {
      value = value.copyWith(errorText: mapApiErrorMessage(error));
    }
  }

  String _digest(String seed) {
    final raw = seed.codeUnits.fold<int>(0, (hash, code) => ((hash * 31) ^ code) & 0x7fffffff);
    return raw.toRadixString(16).toUpperCase().padLeft(16, '0');
  }
}

class SuggestChainRequest {
  const SuggestChainRequest({
    required this.chainName,
    required this.chainId,
    required this.rpc,
    required this.rest,
    required this.bech32Prefix,
    required this.denom,
  });

  final String chainName;
  final String chainId;
  final String rpc;
  final String rest;
  final String bech32Prefix;
  final String denom;
}

class BIP21ScanResult {
  const BIP21ScanResult({
    required this.scheme,
    required this.address,
    required this.amount,
    required this.memo,
  });

  final String scheme;
  final String address;
  final String? amount;
  final String? memo;
}

class ReorgNotice {
  const ReorgNotice({
    required this.txHash,
    required this.previousHeight,
    required this.currentHeight,
    required this.status,
    required this.detectedAt,
  });

  final String txHash;
  final int previousHeight;
  final int currentHeight;
  final String status;
  final DateTime detectedAt;
}

class DappInteropState {
  const DappInteropState({
    required this.pendingSuggestChain,
    required this.approvedChains,
    required this.reorgNotice,
    this.loading = false,
    this.scanResult,
    this.noticeText,
    this.errorText,
  });

  final SuggestChainRequest? pendingSuggestChain;
  final List<SuggestChainRequest> approvedChains;
  final ReorgNotice reorgNotice;
  final bool loading;
  final BIP21ScanResult? scanResult;
  final String? noticeText;
  final String? errorText;

  DappInteropState copyWith({
    SuggestChainRequest? pendingSuggestChain,
    bool clearPendingSuggestChain = false,
    List<SuggestChainRequest>? approvedChains,
    ReorgNotice? reorgNotice,
    bool? loading,
    BIP21ScanResult? scanResult,
    bool clearScanResult = false,
    String? noticeText,
    bool clearNoticeText = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return DappInteropState(
      pendingSuggestChain:
          clearPendingSuggestChain ? null : (pendingSuggestChain ?? this.pendingSuggestChain),
      approvedChains: approvedChains ?? this.approvedChains,
      reorgNotice: reorgNotice ?? this.reorgNotice,
      loading: loading ?? this.loading,
      scanResult: clearScanResult ? null : (scanResult ?? this.scanResult),
      noticeText: clearNoticeText ? null : (noticeText ?? this.noticeText),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class DappInteropStore extends ValueNotifier<DappInteropState> {
  DappInteropStore._({
    required ChainApiClient apiClient,
  })  : _apiClient = apiClient,
        _random = Random.secure(),
        super(
          DappInteropState(
            pendingSuggestChain: const SuggestChainRequest(
              chainName: 'Overdrive Chian',
              chainId: 'soulon-testnet-1',
              rpc: 'https://rpc.testnet.soulon.io:443',
              rest: 'https://api.testnet.soulon.io:443',
              bech32Prefix: 'soulon',
              denom: 'usoul',
            ),
            approvedChains: const [],
            reorgNotice: ReorgNotice(
              txHash: '9A83FC1D2BFA56D900E1160A43D2B8F3CC19AD0156C90F1BDCCF13012E9A1102',
              previousHeight: 902155,
              currentHeight: 902154,
              status: '检测到重组，交易状态待刷新',
              detectedAt: DateTime(2026, 3, 5, 11, 6),
            ),
          ),
        );

  static final DappInteropStore instance = DappInteropStore._(
    apiClient: ChainApiClient(
      baseUrl: WalletRuntimeConfig.apiBaseUrl,
      timeout: WalletRuntimeConfig.requestTimeout,
    ),
  );
  final ChainApiClient _apiClient;
  final Random _random;
  int? _lastReorgCount;
  String? _trackedTxHash;

  void startAutoRefresh() {
    unawaited(_refreshReorgStatusInternal());
  }

  Future<void> approveSuggestChain() async {
    final request = value.pendingSuggestChain;
    if (request == null) {
      throw const FormatException('当前没有待处理 SuggestChain 请求');
    }
    value = value.copyWith(
      loading: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    final health = await _apiClient.getJson(ChainApiContract.health);
    final indexerState = await _apiClient.getJson(ChainApiContract.indexerState);
    final status = (health['status'] ?? 'unknown').toString();
    final tipHeight = _toInt(indexerState['tipHeight']);
    if (status.toLowerCase() != 'ok') {
      throw const ApiClientException(kind: ApiErrorKind.network, message: '目标链健康检查失败');
    }
    value = value.copyWith(
      loading: false,
      clearPendingSuggestChain: true,
      approvedChains: [request, ...value.approvedChains],
      noticeText: '已添加链：${request.chainName} (${request.chainId})，最新高度 $tipHeight',
    );
  }

  Future<void> rejectSuggestChain() async {
    final request = value.pendingSuggestChain;
    if (request == null) {
      throw const FormatException('当前没有待处理 SuggestChain 请求');
    }
    value = value.copyWith(
      loading: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    value = value.copyWith(
      loading: false,
      clearPendingSuggestChain: true,
      noticeText: '已拒绝链请求：${request.chainId}',
    );
  }

  void parseBip21(String rawUri) {
    final uriText = rawUri.trim();
    if (uriText.isEmpty) {
      throw const FormatException('请输入扫码 URI');
    }
    final separatorIndex = uriText.indexOf(':');
    if (separatorIndex <= 0) {
      throw const FormatException('URI 缺少协议头');
    }
    final scheme = uriText.substring(0, separatorIndex).toLowerCase();
    const supportedSchemes = {'soulon', 'cosmos', 'bitcoin'};
    if (!supportedSchemes.contains(scheme)) {
      throw const FormatException('仅支持 soulon/cosmos/bitcoin 协议');
    }
    final payload = uriText.substring(separatorIndex + 1);
    final queryIndex = payload.indexOf('?');
    final address = (queryIndex >= 0 ? payload.substring(0, queryIndex) : payload).trim();
    if (!RegExp(r'^[a-z0-9]{8,}$').hasMatch(address.toLowerCase())) {
      throw const FormatException('扫码地址格式错误');
    }
    String? amount;
    String? memo;
    if (queryIndex >= 0) {
      final query = payload.substring(queryIndex + 1);
      final params = Uri.splitQueryString(query);
      amount = params['amount'];
      memo = params['memo'] ?? params['message'];
      if (amount != null && amount.isNotEmpty && double.tryParse(amount) == null) {
        throw const FormatException('amount 参数格式错误');
      }
    }
    final normalizedAmount = amount?.trim().isNotEmpty == true ? amount!.trim() : '0.00';
    final normalizedMemo = memo?.trim().isNotEmpty == true ? memo!.trim() : '';
    if (RegExp(r'^(cosmos|soulon)1[0-9a-z]{20,}$').hasMatch(address.toLowerCase())) {
      TransferFormDraftBridge.instance.publishFromScan(
        recipientAddress: address,
        amountText: normalizedAmount,
        memo: normalizedMemo,
      );
    }
    value = value.copyWith(
      scanResult: BIP21ScanResult(
        scheme: scheme,
        address: address,
        amount: amount?.isEmpty ?? true ? null : amount,
        memo: memo?.isEmpty ?? true ? null : memo,
      ),
      noticeText: '扫码解析成功，已联动交易构建表单。',
      clearErrorText: true,
    );
  }

  void bindTrackedTx(String txHash) {
    final normalizedHash = txHash.trim().toUpperCase();
    if (normalizedHash.isEmpty) {
      return;
    }
    _trackedTxHash = normalizedHash;
    value = value.copyWith(
      reorgNotice: ReorgNotice(
        txHash: normalizedHash,
        previousHeight: value.reorgNotice.currentHeight,
        currentHeight: value.reorgNotice.currentHeight,
        status: '已绑定 IBC 交易，等待 Reorg 监控',
        detectedAt: DateTime.now(),
      ),
      clearErrorText: true,
    );
    unawaited(_runAutoRefreshBurst());
  }

  Future<void> refreshReorgStatus() async {
    await _refreshReorgStatusInternal(forceNotice: true);
  }

  Future<void> _refreshReorgStatusInternal({bool forceNotice = false}) async {
    final previousHeight = value.reorgNotice.currentHeight;
    value = value.copyWith(
      loading: true,
      clearNoticeText: true,
      clearErrorText: true,
    );
    try {
      final state = await _apiClient.getJson(ChainApiContract.indexerState);
      final tipHeight = _toInt(state['tipHeight']);
      final reorgCount = _toInt(state['reorgs']);
      final previousReorgCount = _lastReorgCount ?? reorgCount;
      _lastReorgCount = reorgCount;
      var status = '链状态稳定，已同步最新高度';
      if (reorgCount > previousReorgCount) {
        status = '检测到链重组，已自动刷新交易状态';
      }
      var syncedHeight = tipHeight > 0 ? tipHeight : previousHeight + 1 + _random.nextInt(2);
      if (_trackedTxHash != null) {
        final tx = await _safeGetChainTx(_trackedTxHash!);
        final txHeight = _toInt(tx['height']);
        if (txHeight > 0) {
          syncedHeight = txHeight > syncedHeight ? txHeight : syncedHeight;
        }
      }
      value = value.copyWith(
        loading: false,
        reorgNotice: ReorgNotice(
          txHash: _trackedTxHash ?? value.reorgNotice.txHash,
          previousHeight: previousHeight,
          currentHeight: syncedHeight,
          status: status,
          detectedAt: DateTime.now(),
        ),
        noticeText: (forceNotice || reorgCount > previousReorgCount)
            ? 'Reorg 监控已刷新：高度 $previousHeight → $syncedHeight'
            : value.noticeText,
      );
    } catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
    }
  }

  Future<Map<String, dynamic>> _safeGetChainTx(String txHash) async {
    try {
      return await _apiClient.getJson(ChainApiContract.chainTx(txHash));
    } on ApiClientException catch (error) {
      if (error.kind == ApiErrorKind.notFound) {
        return const <String, dynamic>{};
      }
      rethrow;
    }
  }

  int _toInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  Future<void> _runAutoRefreshBurst() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      await _refreshReorgStatusInternal(forceNotice: i == 2);
    }
  }
}
