import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';
import '../config/mock_data.dart';

class WalletConnectRequest {
  const WalletConnectRequest({
    required this.dappName,
    required this.topic,
    required this.chainId,
    required this.uri,
    required this.permissions,
    required this.riskHint,
  });

  final String dappName;
  final String topic;
  final String chainId;
  final String uri;
  final List<String> permissions;
  final String riskHint;
}

class WalletConnectSession {
  const WalletConnectSession({
    required this.sessionId,
    required this.dappName,
    required this.topic,
    required this.chainId,
    required this.connectedAt,
    required this.lastActiveAt,
  });

  final String sessionId;
  final String dappName;
  final String topic;
  final String chainId;
  final DateTime connectedAt;
  final DateTime lastActiveAt;

  WalletConnectSession copyWith({
    String? sessionId,
    String? dappName,
    String? topic,
    String? chainId,
    DateTime? connectedAt,
    DateTime? lastActiveAt,
  }) {
    return WalletConnectSession(
      sessionId: sessionId ?? this.sessionId,
      dappName: dappName ?? this.dappName,
      topic: topic ?? this.topic,
      chainId: chainId ?? this.chainId,
      connectedAt: connectedAt ?? this.connectedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

class WalletConnectAuthorizeReceipt {
  const WalletConnectAuthorizeReceipt({
    required this.requestId,
    required this.signatureDigest,
    required this.challengePath,
    required this.confirmPath,
    required this.authorizedAt,
  });

  final String requestId;
  final String signatureDigest;
  final String challengePath;
  final String confirmPath;
  final DateTime authorizedAt;
}

class WalletConnectState {
  const WalletConnectState({
    this.pendingRequest,
    required this.sessions,
    this.lastAuthorizeReceipt,
    this.loading = false,
    this.errorText,
    this.noticeText,
  });

  final WalletConnectRequest? pendingRequest;
  final List<WalletConnectSession> sessions;
  final WalletConnectAuthorizeReceipt? lastAuthorizeReceipt;
  final bool loading;
  final String? errorText;
  final String? noticeText;

  WalletConnectState copyWith({
    WalletConnectRequest? pendingRequest,
    bool clearPendingRequest = false,
    List<WalletConnectSession>? sessions,
    WalletConnectAuthorizeReceipt? lastAuthorizeReceipt,
    bool clearLastAuthorizeReceipt = false,
    bool? loading,
    String? errorText,
    bool clearErrorText = false,
    String? noticeText,
    bool clearNoticeText = false,
  }) {
    return WalletConnectState(
      pendingRequest: clearPendingRequest ? null : (pendingRequest ?? this.pendingRequest),
      sessions: sessions ?? this.sessions,
      lastAuthorizeReceipt: clearLastAuthorizeReceipt ? null : (lastAuthorizeReceipt ?? this.lastAuthorizeReceipt),
      loading: loading ?? this.loading,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      noticeText: clearNoticeText ? null : (noticeText ?? this.noticeText),
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
              dappName: MockData.walletConnectPendingDappName,
              topic: MockData.walletConnectPendingTopic,
              chainId: MockData.walletConnectPendingChainId,
              uri: MockData.walletConnectPendingUri,
              permissions: MockData.walletConnectPendingPermissions,
              riskHint: MockData.walletConnectPendingRiskHint,
            ),
            sessions: [
              WalletConnectSession(
                sessionId: 'WCS-8001',
                dappName: 'Governance Portal',
                topic: 'wc:gov-portal-session-2026',
                chainId: 'soulon-1',
                connectedAt: DateTime(2026, 3, 4, 14, 30),
                lastActiveAt: DateTime(2026, 3, 5, 9, 15),
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
    final pending = value.pendingRequest;
    if (pending == null) {
      throw const FormatException('当前没有待处理的 WalletConnect 请求');
    }
    value = value.copyWith(
      loading: true,
      clearErrorText: true,
      clearNoticeText: true,
    );

    try {
      final challenge = await _apiClient.postJson(
        ChainApiContract.authSignatureChallenge,
        body: {'accountId': _walletAddress},
      );
      final requestId = (challenge['requestId'] ?? '').toString();
      if (requestId.isEmpty) {
        throw const FormatException('签名挑战创建失败');
      }
      final digest = _digest('$requestId|${pending.topic}|${pending.dappName}');
      final signature = '$requestId.$_walletAddress.$digest';
      await _apiClient.postJson(
        ChainApiContract.authSignatureConfirm,
        body: {
          'accountId': _walletAddress,
          'requestId': requestId,
          'signature': signature,
        },
      );

      final now = DateTime.now();
      final session = WalletConnectSession(
        sessionId: 'WCS-${now.millisecondsSinceEpoch}',
        dappName: pending.dappName,
        topic: pending.topic,
        chainId: pending.chainId,
        connectedAt: now,
        lastActiveAt: now,
      );

      final receipt = WalletConnectAuthorizeReceipt(
        requestId: requestId,
        signatureDigest: digest,
        challengePath: ChainApiContract.authSignatureChallenge,
        confirmPath: ChainApiContract.authSignatureConfirm,
        authorizedAt: now,
      );

      value = value.copyWith(
        clearPendingRequest: true,
        sessions: [...value.sessions, session],
        lastAuthorizeReceipt: receipt,
        loading: false,
        noticeText: '已批准 ${pending.dappName} 的连接请求，会话已建立。',
      );
    } on ApiClientException catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
      rethrow;
    } on FormatException {
      value = value.copyWith(loading: false);
      rethrow;
    } catch (_) {
      value = value.copyWith(
        loading: false,
        errorText: '批准连接时发生未知错误，请稍后重试。',
      );
      throw const FormatException('批准连接时发生未知错误');
    }
  }

  Future<void> rejectPending() async {
    final pending = value.pendingRequest;
    if (pending == null) {
      throw const FormatException('当前没有待处理的 WalletConnect 请求');
    }
    value = value.copyWith(
      clearPendingRequest: true,
      clearErrorText: true,
      noticeText: '已拒绝 ${pending.dappName} 的连接请求。',
    );
  }

  void disconnect(String topic) {
    final sessions = value.sessions
        .where((session) => session.topic != topic)
        .toList(growable: false);
    value = value.copyWith(
      sessions: sessions,
      clearErrorText: true,
      noticeText: '已断开会话: $topic',
    );
  }

  void markActive(String topic) {
    _markActive(topic);
  }

  void _markActive(String topic) {
    final sessions = value.sessions.map((session) {
      if (session.topic == topic) {
        return session.copyWith(lastActiveAt: DateTime.now());
      }
      return session;
    }).toList(growable: false);
    value = value.copyWith(sessions: sessions, clearErrorText: true);
  }

  String _digest(String seed) {
    final bytes = utf8.encode('soulon.wallet.wc.v1:$seed');
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16).toUpperCase();
  }
}
