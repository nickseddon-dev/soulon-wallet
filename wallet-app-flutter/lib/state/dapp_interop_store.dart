import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';
import '../config/mock_data.dart';
import 'transaction_demo_store.dart';

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
    this.amount,
    this.memo,
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

  ReorgNotice copyWith({
    String? txHash,
    int? previousHeight,
    int? currentHeight,
    String? status,
    DateTime? detectedAt,
  }) {
    return ReorgNotice(
      txHash: txHash ?? this.txHash,
      previousHeight: previousHeight ?? this.previousHeight,
      currentHeight: currentHeight ?? this.currentHeight,
      status: status ?? this.status,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }
}

class DappInteropState {
  const DappInteropState({
    this.pendingSuggestChain,
    required this.approvedChains,
    this.scanResult,
    required this.reorgNotice,
    this.loading = false,
    this.errorText,
    this.noticeText,
  });

  final SuggestChainRequest? pendingSuggestChain;
  final List<SuggestChainRequest> approvedChains;
  final BIP21ScanResult? scanResult;
  final ReorgNotice reorgNotice;
  final bool loading;
  final String? errorText;
  final String? noticeText;

  DappInteropState copyWith({
    SuggestChainRequest? pendingSuggestChain,
    bool clearPendingSuggestChain = false,
    List<SuggestChainRequest>? approvedChains,
    BIP21ScanResult? scanResult,
    bool clearScanResult = false,
    ReorgNotice? reorgNotice,
    bool? loading,
    String? errorText,
    bool clearErrorText = false,
    String? noticeText,
    bool clearNoticeText = false,
  }) {
    return DappInteropState(
      pendingSuggestChain: clearPendingSuggestChain ? null : (pendingSuggestChain ?? this.pendingSuggestChain),
      approvedChains: approvedChains ?? this.approvedChains,
      scanResult: clearScanResult ? null : (scanResult ?? this.scanResult),
      reorgNotice: reorgNotice ?? this.reorgNotice,
      loading: loading ?? this.loading,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      noticeText: clearNoticeText ? null : (noticeText ?? this.noticeText),
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
              chainName: MockData.suggestChainName,
              chainId: MockData.suggestChainId,
              rpc: MockData.suggestChainRpc,
              rest: MockData.suggestChainRest,
              bech32Prefix: MockData.suggestChainBech32,
              denom: MockData.suggestChainDenom,
            ),
            approvedChains: const [],
            reorgNotice: ReorgNotice(
              txHash: '-',
              previousHeight: 0,
              currentHeight: 0,
              status: '未绑定交易',
              detectedAt: DateTime(2026, 3, 5),
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
  Timer? _autoRefreshTimer;
  Timer? _autoStopTimer;

  static const _maxRefreshDuration = Duration(minutes: 10);

  void startAutoRefresh() {
    if (_autoRefreshTimer != null) {
      return;
    }
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _runAutoRefreshBurst();
    });
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(_maxRefreshDuration, stopAutoRefresh);
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }

  Future<void> approveSuggestChain() async {
    final chain = value.pendingSuggestChain;
    if (chain == null) {
      throw const FormatException('当前没有待处理的加链请求');
    }
    value = value.copyWith(
      loading: true,
      clearErrorText: true,
      clearNoticeText: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    value = value.copyWith(
      clearPendingSuggestChain: true,
      approvedChains: [...value.approvedChains, chain],
      loading: false,
      noticeText: '已批准加链请求: ${chain.chainName} (${chain.chainId})',
    );
  }

  Future<void> rejectSuggestChain() async {
    final chain = value.pendingSuggestChain;
    if (chain == null) {
      throw const FormatException('当前没有待处理的加链请求');
    }
    value = value.copyWith(
      clearPendingSuggestChain: true,
      clearErrorText: true,
      noticeText: '已拒绝加链请求: ${chain.chainName}',
    );
  }

  void parseBip21(String uri) {
    if (uri.trim().isEmpty) {
      throw const FormatException('扫码内容不能为空');
    }
    final colonIndex = uri.indexOf(':');
    if (colonIndex <= 0) {
      throw const FormatException('无效的 BIP-21 URI 格式');
    }
    final scheme = uri.substring(0, colonIndex);
    final rest = uri.substring(colonIndex + 1);

    final questionIndex = rest.indexOf('?');
    String address;
    String? amount;
    String? memo;

    if (questionIndex < 0) {
      address = rest;
    } else {
      address = rest.substring(0, questionIndex);
      final queryString = rest.substring(questionIndex + 1);
      final params = Uri.splitQueryString(queryString);
      amount = params['amount'];
      memo = params['memo'];
    }

    if (address.trim().isEmpty) {
      throw const FormatException('地址不能为空');
    }

    final scanResult = BIP21ScanResult(
      scheme: scheme,
      address: address,
      amount: amount,
      memo: memo,
    );

    value = value.copyWith(scanResult: scanResult, clearErrorText: true);

    TransferFormDraftBridge.instance.publishFromScan(
      recipientAddress: address,
      amountText: amount ?? '',
      memo: memo ?? '',
    );
  }

  void bindTrackedTx(String txHash) {
    value = value.copyWith(
      reorgNotice: value.reorgNotice.copyWith(
        txHash: txHash,
        status: '已绑定，等待刷新',
        detectedAt: DateTime.now(),
      ),
      clearErrorText: true,
    );
  }

  Future<void> refreshReorgStatus() async {
    final txHash = value.reorgNotice.txHash;
    if (txHash == '-' || txHash.isEmpty) {
      return;
    }
    value = value.copyWith(loading: true, clearErrorText: true);
    await _refreshReorgStatusInternal(txHash);
    value = value.copyWith(loading: false);
  }

  Future<void> _refreshReorgStatusInternal(String txHash) async {
    try {
      final txResponse = await _safeGetChainTx(txHash);
      final txBody = _asMap(txResponse['tx_response']);
      final chainHeight = _toInt(txBody['height']);

      final indexer = await _apiClient.getJson(ChainApiContract.indexerState);
      final tipHeight = _toInt(indexer['tipHeight']);

      final previousHeight = value.reorgNotice.previousHeight;
      final newPreviousHeight = previousHeight > 0 ? previousHeight : chainHeight;

      String status;
      if (chainHeight <= 0 && tipHeight <= 0) {
        status = '链端无数据';
      } else if (chainHeight > 0 && tipHeight >= chainHeight) {
        status = '已确认，高度一致';
      } else if (chainHeight > 0 && tipHeight < chainHeight) {
        status = '疑似 Reorg，高度回退';
      } else {
        status = '等待链上确认';
      }

      value = value.copyWith(
        reorgNotice: ReorgNotice(
          txHash: txHash,
          previousHeight: newPreviousHeight,
          currentHeight: tipHeight > 0 ? tipHeight : chainHeight,
          status: status,
          detectedAt: DateTime.now(),
        ),
        noticeText: '交易状态已刷新：$status',
      );
    } on ApiClientException catch (error) {
      value = value.copyWith(
        reorgNotice: value.reorgNotice.copyWith(
          status: '查询失败',
          detectedAt: DateTime.now(),
        ),
        errorText: mapApiErrorMessage(error),
      );
    } catch (_) {
      value = value.copyWith(
        reorgNotice: value.reorgNotice.copyWith(
          status: '查询失败',
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _safeGetChainTx(String txHash) async {
    try {
      return await _apiClient.getJson(ChainApiContract.chainTx(txHash));
    } on ApiClientException catch (error) {
      if (error.kind == ApiErrorKind.notFound) {
        return <String, dynamic>{};
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

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return const <String, dynamic>{};
  }

  void _runAutoRefreshBurst() {
    final txHash = value.reorgNotice.txHash;
    if (txHash == '-' || txHash.isEmpty) {
      return;
    }
    unawaited(_refreshReorgStatusInternal(txHash));
  }
}
