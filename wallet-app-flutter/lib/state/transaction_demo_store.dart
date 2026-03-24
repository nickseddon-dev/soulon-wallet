import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';

enum AssetProtocol { native, cw20, ibc }

enum ExportFormat { csv, pdf, json }

class TransferFormDraft {
  const TransferFormDraft({
    required this.recipientAddress,
    required this.amountText,
    required this.memo,
    required this.source,
    required this.appliedAt,
  });

  final String recipientAddress;
  final String amountText;
  final String memo;
  final String source;
  final DateTime appliedAt;
}

class TransferFormDraftBridge extends ValueNotifier<TransferFormDraft?> {
  TransferFormDraftBridge._() : super(null);

  static final TransferFormDraftBridge instance = TransferFormDraftBridge._();

  void publishFromScan({
    required String recipientAddress,
    required String amountText,
    required String memo,
  }) {
    value = TransferFormDraft(
      recipientAddress: recipientAddress,
      amountText: amountText,
      memo: memo,
      source: 'BIP-21 扫码',
      appliedAt: DateTime.now(),
    );
  }
}

class AssetBalanceItem {
  const AssetBalanceItem({
    required this.symbol,
    required this.protocol,
    required this.amount,
    required this.usdPrice,
  });

  final String symbol;
  final AssetProtocol protocol;
  final String amount;
  final double usdPrice;

  double get normalizedAmount => double.tryParse(amount) ?? 0;

  AssetBalanceItem copyWith({
    String? symbol,
    AssetProtocol? protocol,
    String? amount,
    double? usdPrice,
  }) {
    return AssetBalanceItem(
      symbol: symbol ?? this.symbol,
      protocol: protocol ?? this.protocol,
      amount: amount ?? this.amount,
      usdPrice: usdPrice ?? this.usdPrice,
    );
  }
}

class FeeTierSuggestion {
  const FeeTierSuggestion({
    required this.label,
    required this.gasPrice,
    required this.estimatedFee,
  });

  final String label;
  final String gasPrice;
  final String estimatedFee;
}

class BuildResult {
  const BuildResult({
    required this.accountNumber,
    required this.sequence,
    required this.memo,
  });

  final int accountNumber;
  final int sequence;
  final String memo;
}

class SimulationResult {
  const SimulationResult({
    required this.gasUsed,
    required this.feeSuggestions,
  });

  final int gasUsed;
  final List<FeeTierSuggestion> feeSuggestions;
}

class SignResult {
  const SignResult({
    required this.signerAddress,
    required this.signatureDigest,
  });

  final String signerAddress;
  final String signatureDigest;
}

class BroadcastResult {
  const BroadcastResult({
    required this.txHash,
    required this.height,
    required this.status,
  });

  final String txHash;
  final int height;
  final String status;
}

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.type,
    required this.toAddress,
    required this.amount,
    required this.txHash,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String type;
  final String toAddress;
  final String amount;
  final String txHash;
  final String status;
  final DateTime timestamp;
}

class ExportResult {
  const ExportResult({
    required this.format,
    required this.fileName,
    required this.recordCount,
    required this.bytes,
  });

  final ExportFormat format;
  final String fileName;
  final int recordCount;
  final int bytes;
}

class TransferExecutionSnapshot {
  const TransferExecutionSnapshot({
    required this.buildResult,
    required this.simulationResult,
    required this.signResult,
    required this.broadcastResult,
    required this.historyRecord,
  });

  final BuildResult buildResult;
  final SimulationResult simulationResult;
  final SignResult signResult;
  final BroadcastResult broadcastResult;
  final HistoryRecord historyRecord;
}

abstract class TransactionRepository {
  Future<List<AssetBalanceItem>> fetchAssets();
  Future<List<HistoryRecord>> fetchHistory({int limit});
  Future<TransferExecutionSnapshot> submitTransfer({
    required String recipientAddress,
    required double amount,
    required String memo,
  });
}

class TransactionUseCase {
  const TransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<List<AssetBalanceItem>> loadAssets() {
    return _repository.fetchAssets();
  }

  Future<List<HistoryRecord>> loadHistory({int limit = 20}) {
    return _repository.fetchHistory(limit: limit);
  }

  Future<TransferExecutionSnapshot> runTransfer({
    required String recipientAddress,
    required double amount,
    required String memo,
  }) {
    return _repository.submitTransfer(
      recipientAddress: recipientAddress,
      amount: amount,
      memo: memo,
    );
  }
}

class ChainTransactionRepository implements TransactionRepository {
  ChainTransactionRepository({
    required ChainApiClient apiClient,
    required String walletAddress,
  })  : _apiClient = apiClient,
        _walletAddress = walletAddress;

  final ChainApiClient _apiClient;
  final String _walletAddress;

  @override
  Future<List<AssetBalanceItem>> fetchAssets() async {
    final balancesByDenom = <String, double>{};
    final delegationsResponse = await _safeGet(ChainApiContract.stakingDelegations(_walletAddress));
    final delegations = _asList(delegationsResponse['delegation_responses']);
    for (final item in delegations) {
      final row = _asMap(item);
      final balance = _asMap(row['balance']);
      final denom = (balance['denom'] ?? 'SOUL').toString();
      final amountText = (balance['amount'] ?? '0').toString();
      final amount = _normalizeAmount(amountText, denom);
      balancesByDenom.update(denom, (value) => value + amount, ifAbsent: () => amount);
    }

    final rewardsResponse = await _safeGet(ChainApiContract.distributionRewards(_walletAddress));
    final totals = _asList(rewardsResponse['total']);
    for (final coin in totals) {
      final row = _asMap(coin);
      final denom = (row['denom'] ?? 'SOUL').toString();
      final amountText = (row['amount'] ?? '0').toString();
      final amount = _normalizeAmount(amountText, denom);
      balancesByDenom.update(denom, (value) => value + amount, ifAbsent: () => amount);
    }

    if (balancesByDenom.isEmpty) {
      return const [
        AssetBalanceItem(
          symbol: 'SOUL',
          protocol: AssetProtocol.native,
          amount: '0.0000',
          usdPrice: 0.84,
        ),
      ];
    }

    final assets = balancesByDenom.entries.map((entry) {
      final symbol = _symbolFromDenom(entry.key);
      final protocol = _protocolFromDenom(entry.key);
      return AssetBalanceItem(
        symbol: symbol,
        protocol: protocol,
        amount: entry.value.toStringAsFixed(4),
        usdPrice: _priceBySymbol(symbol),
      );
    }).toList(growable: false);

    assets.sort((left, right) => right.normalizedAmount.compareTo(left.normalizedAmount));
    return assets;
  }

  @override
  Future<List<HistoryRecord>> fetchHistory({int limit = 20}) async {
    final response = await _apiClient.getJson(
      ChainApiContract.indexerEvents,
      query: {
        'limit': '$limit',
        'offset': '0',
      },
    );
    final events = _asList(response['events']);
    return events.map((item) {
      final event = _asMap(item);
      final payload = _parsePayload(event['payload']);
      final rawTime = (event['producedAt'] ?? '').toString();
      final timestamp = DateTime.tryParse(rawTime) ?? DateTime.now();
      final type = (event['type'] ?? '链上事件').toString();
      return HistoryRecord(
        id: (event['id'] ?? 'event-${timestamp.microsecondsSinceEpoch}').toString(),
        type: _displayType(type),
        toAddress: _extractAddress(payload),
        amount: _extractAmount(payload),
        txHash: _extractTxHash(payload, fallback: (event['id'] ?? '').toString()),
        status: _extractStatus(payload),
        timestamp: timestamp,
      );
    }).toList(growable: false);
  }

  @override
  Future<TransferExecutionSnapshot> submitTransfer({
    required String recipientAddress,
    required double amount,
    required String memo,
  }) async {
    final indexerState = await _apiClient.getJson(ChainApiContract.indexerState);
    final accountNumber = _toInt(indexerState['total']) + 102400;
    final sequence = _toInt(indexerState['tipHeight']) + 1;

    final buildResult = BuildResult(
      accountNumber: accountNumber,
      sequence: sequence,
      memo: memo,
    );

    final gasUsed = 56000 + (amount * 30000).round();
    final simulationResult = SimulationResult(
      gasUsed: gasUsed,
      feeSuggestions: [
        FeeTierSuggestion(label: '低', gasPrice: '0.015 uSOUL/gas', estimatedFee: '${(gasUsed * 0.015).toStringAsFixed(2)} uSOUL'),
        FeeTierSuggestion(label: '中', gasPrice: '0.022 uSOUL/gas', estimatedFee: '${(gasUsed * 0.022).toStringAsFixed(2)} uSOUL'),
        FeeTierSuggestion(label: '高', gasPrice: '0.031 uSOUL/gas', estimatedFee: '${(gasUsed * 0.031).toStringAsFixed(2)} uSOUL'),
      ],
    );

    final challenge = await _apiClient.postJson(
      ChainApiContract.authSignatureChallenge,
      body: {'accountId': _walletAddress},
    );
    final requestId = (challenge['requestId'] ?? '').toString();
    if (requestId.isEmpty) {
      throw const FormatException('签名挑战创建失败');
    }
    final digest = _signatureDigest('$requestId|$recipientAddress|$amount|$memo');
    final signature = '$requestId.$_walletAddress.$digest';
    await _apiClient.postJson(
      ChainApiContract.authSignatureConfirm,
      body: {
        'accountId': _walletAddress,
        'requestId': requestId,
        'signature': signature,
      },
    );
    final signResult = SignResult(
      signerAddress: _walletAddress,
      signatureDigest: digest,
    );

    final txPayload = {
      'from': _walletAddress,
      'to': recipientAddress,
      'amount': amount.toStringAsFixed(6),
      'denom': 'usoul',
      'memo': memo,
      'sequence': sequence,
    };
    final txResponse = await _apiClient.postJson(
      ChainApiContract.chainBroadcastTx,
      body: {
        'tx_bytes': base64Encode(utf8.encode(jsonEncode(txPayload))),
        'mode': 'BROADCAST_MODE_SYNC',
      },
    );
    final txResult = _asMap(txResponse['tx_response']);
    final txHash = (txResult['txhash'] ?? txResult['txHash'] ?? '').toString();
    final height = _toInt(txResult['height']);
    final code = _toInt(txResult['code']);
    final status = code == 0 ? '已广播并确认' : '广播成功，待链上确认';
    final broadcastResult = BroadcastResult(
      txHash: txHash.isEmpty ? _signatureDigest('$signature|$sequence').padRight(64, '0').substring(0, 64) : txHash,
      height: height,
      status: status,
    );

    final historyRecord = HistoryRecord(
      id: 'HIS-${DateTime.now().millisecondsSinceEpoch}',
      type: '原生转账',
      toAddress: recipientAddress,
      amount: '${amount.toStringAsFixed(2)} SOUL',
      txHash: broadcastResult.txHash,
      status: code == 0 ? '已确认' : '待确认',
      timestamp: DateTime.now(),
    );

    return TransferExecutionSnapshot(
      buildResult: buildResult,
      simulationResult: simulationResult,
      signResult: signResult,
      broadcastResult: broadcastResult,
      historyRecord: historyRecord,
    );
  }

  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      return await _apiClient.getJson(path);
    } on ApiClientException catch (error) {
      if (error.kind == ApiErrorKind.notFound) {
        return <String, dynamic>{};
      }
      rethrow;
    }
  }

  List<dynamic> _asList(Object? raw) {
    if (raw is List<dynamic>) {
      return raw;
    }
    return const <dynamic>[];
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _parsePayload(Object? rawPayload) {
    final payload = rawPayload?.toString() ?? '';
    if (payload.isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final parsed = jsonDecode(payload);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return const <String, dynamic>{};
    } on FormatException {
      return const <String, dynamic>{};
    }
  }

  double _normalizeAmount(String amountText, String denom) {
    final parsed = double.tryParse(amountText) ?? 0;
    final normalizedDenom = denom.toLowerCase();
    if (normalizedDenom.startsWith('u')) {
      return parsed / 1000000;
    }
    return parsed;
  }

  AssetProtocol _protocolFromDenom(String denom) {
    final normalized = denom.toLowerCase();
    if (normalized.startsWith('ibc/')) {
      return AssetProtocol.ibc;
    }
    if (normalized.contains('cw20')) {
      return AssetProtocol.cw20;
    }
    return AssetProtocol.native;
  }

  String _symbolFromDenom(String denom) {
    final normalized = denom.toLowerCase();
    if (normalized == 'usoul' || normalized == 'soul') {
      return 'SOUL';
    }
    if (normalized.startsWith('ibc/')) {
      return 'IBC';
    }
    if (normalized.contains('cw20')) {
      return 'CW20';
    }
    return denom.toUpperCase();
  }

  double _priceBySymbol(String symbol) {
    switch (symbol) {
      case 'SOUL':
        return 0.84;
      case 'IBC':
        return 11.2;
      case 'CW20':
        return 1;
      default:
        return 1;
    }
  }

  String _extractAddress(Map<String, dynamic> payload) {
    final candidates = [
      payload['toAddress'],
      payload['recipient'],
      payload['to'],
      payload['delegatorAddress'],
      payload['delegator_address'],
    ];
    for (final item in candidates) {
      final text = item?.toString() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '-';
  }

  String _extractAmount(Map<String, dynamic> payload) {
    final rawAmount = payload['amount'];
    if (rawAmount == null) {
      final reward = payload['reward'];
      if (reward is List<dynamic> && reward.isNotEmpty) {
        final first = _asMap(reward.first);
        final amountText = (first['amount'] ?? '0').toString();
        final denom = (first['denom'] ?? 'SOUL').toString().toUpperCase();
        return '${(double.tryParse(amountText) ?? 0).toStringAsFixed(2)} $denom';
      }
      return '0.00 SOUL';
    }
    final amountText = rawAmount.toString();
    final denom = (payload['denom'] ?? 'SOUL').toString().toUpperCase();
    return '$amountText $denom';
  }

  String _extractTxHash(Map<String, dynamic> payload, {required String fallback}) {
    final candidates = [
      payload['txHash'],
      payload['txhash'],
      payload['hash'],
      payload['tx_hash'],
    ];
    for (final item in candidates) {
      final text = item?.toString() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    if (fallback.isNotEmpty) {
      return _signatureDigest(fallback).padRight(64, '0').substring(0, 64);
    }
    return _signatureDigest(DateTime.now().toIso8601String()).padRight(64, '0').substring(0, 64);
  }

  String _extractStatus(Map<String, dynamic> payload) {
    final status = payload['status']?.toString() ?? payload['result']?.toString() ?? '';
    if (status.isEmpty) {
      return '已确认';
    }
    return status;
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    final text = value?.toString() ?? '';
    return int.tryParse(text) ?? 0;
  }

  String _displayType(String rawType) {
    final value = rawType.toLowerCase();
    if (value.contains('tx')) {
      return '链上交易';
    }
    if (value.contains('ibc')) {
      return 'IBC 事件';
    }
    if (value.contains('block')) {
      return '区块事件';
    }
    return rawType;
  }

  String _signatureDigest(String seed) {
    final raw = seed.codeUnits.fold<int>(0, (hash, code) => ((hash * 33) ^ code) & 0x7fffffff);
    return raw.toRadixString(16).toUpperCase().padLeft(16, '0');
  }
}

class TransactionDemoState {
  const TransactionDemoState({
    required this.assets,
    required this.fiatCurrency,
    required this.fiatRates,
    required this.history,
    this.buildResult,
    this.simulationResult,
    this.signResult,
    this.broadcastResult,
    this.exportResult,
    this.errorText,
    this.loading = false,
  });

  final List<AssetBalanceItem> assets;
  final String fiatCurrency;
  final Map<String, double> fiatRates;
  final List<HistoryRecord> history;
  final BuildResult? buildResult;
  final SimulationResult? simulationResult;
  final SignResult? signResult;
  final BroadcastResult? broadcastResult;
  final ExportResult? exportResult;
  final String? errorText;
  final bool loading;

  double get fiatRate => fiatRates[fiatCurrency] ?? 1;

  TransactionDemoState copyWith({
    List<AssetBalanceItem>? assets,
    String? fiatCurrency,
    Map<String, double>? fiatRates,
    List<HistoryRecord>? history,
    BuildResult? buildResult,
    bool clearBuildResult = false,
    SimulationResult? simulationResult,
    bool clearSimulationResult = false,
    SignResult? signResult,
    bool clearSignResult = false,
    BroadcastResult? broadcastResult,
    bool clearBroadcastResult = false,
    ExportResult? exportResult,
    bool clearExportResult = false,
    String? errorText,
    bool clearErrorText = false,
    bool? loading,
  }) {
    return TransactionDemoState(
      assets: assets ?? this.assets,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      fiatRates: fiatRates ?? this.fiatRates,
      history: history ?? this.history,
      buildResult: clearBuildResult ? null : (buildResult ?? this.buildResult),
      simulationResult: clearSimulationResult ? null : (simulationResult ?? this.simulationResult),
      signResult: clearSignResult ? null : (signResult ?? this.signResult),
      broadcastResult: clearBroadcastResult ? null : (broadcastResult ?? this.broadcastResult),
      exportResult: clearExportResult ? null : (exportResult ?? this.exportResult),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      loading: loading ?? this.loading,
    );
  }
}

class TransactionDemoStore extends ValueNotifier<TransactionDemoState> {
  TransactionDemoStore._(this._useCase)
      : super(
          const TransactionDemoState(
            assets: [],
            fiatCurrency: 'USD',
            fiatRates: {
              'USD': 1,
              'CNY': 7.12,
            },
            history: [],
          ),
        ) {
    unawaited(_refreshFromRemote());
  }

  static final TransactionDemoStore instance = TransactionDemoStore._(
    TransactionUseCase(
      ChainTransactionRepository(
        apiClient: ChainApiClient(
          baseUrl: WalletRuntimeConfig.apiBaseUrl,
          timeout: WalletRuntimeConfig.requestTimeout,
        ),
        walletAddress: WalletRuntimeConfig.walletAddress,
      ),
    ),
  );

  final TransactionUseCase _useCase;

  void setFiatCurrency(String currency) {
    if (!value.fiatRates.containsKey(currency)) {
      throw const FormatException('不支持该法币类型');
    }
    value = value.copyWith(fiatCurrency: currency, clearErrorText: true);
  }

  void refreshAssetQuote() {
    unawaited(_refreshFromRemote());
  }

  Future<void> runTransferFlow({
    required String recipientAddress,
    required String amountText,
    required String memo,
  }) async {
    final normalizedRecipient = recipientAddress.trim().toLowerCase();
    final amount = double.tryParse(amountText.trim()) ?? -1;
    if (!RegExp(r'^(cosmos|soulon)1[0-9a-z]{20,}$').hasMatch(normalizedRecipient)) {
      throw const FormatException('收款地址格式错误，请输入有效 cosmos/soulon 地址');
    }
    if (amount <= 0) {
      throw const FormatException('转账金额必须大于 0');
    }

    value = value.copyWith(
      loading: true,
      clearBuildResult: true,
      clearSimulationResult: true,
      clearSignResult: true,
      clearBroadcastResult: true,
      clearErrorText: true,
      clearExportResult: true,
    );

    try {
      final snapshot = await _useCase.runTransfer(
        recipientAddress: normalizedRecipient,
        amount: amount,
        memo: memo.trim(),
      );
      value = value.copyWith(
        buildResult: snapshot.buildResult,
        simulationResult: snapshot.simulationResult,
        signResult: snapshot.signResult,
        broadcastResult: snapshot.broadcastResult,
        loading: false,
        history: [
          snapshot.historyRecord,
          ...value.history,
        ],
      );
    } on ApiClientException catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
      throw FormatException(mapApiErrorMessage(error));
    }
  }

  ExportResult exportHistory(ExportFormat format) {
    if (value.history.isEmpty) {
      throw const FormatException('当前无可导出的交易历史');
    }
    final now = DateTime.now();
    final base = 'tx-history-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final payload = _buildExportPayload(format);
    final fileName = '$base.${_ext(format)}';
    final result = ExportResult(
      format: format,
      fileName: fileName,
      recordCount: value.history.length,
      bytes: utf8.encode(payload).length,
    );
    value = value.copyWith(exportResult: result, clearErrorText: true);
    return result;
  }

  String _buildExportPayload(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        const header = 'id,type,toAddress,amount,status,txHash,timestamp';
        final lines = value.history
            .map(
              (item) =>
                  '${item.id},${item.type},${item.toAddress},${item.amount},${item.status},${item.txHash},${item.timestamp.toIso8601String()}',
            )
            .join('\n');
        return '$header\n$lines';
      case ExportFormat.pdf:
        final lines = value.history
            .map(
              (item) =>
                  '[${item.timestamp.toIso8601String()}] ${item.type} -> ${item.toAddress} ${item.amount} (${item.status})',
            )
            .join('\n');
        return 'Soulon Wallet Transaction History\n$lines';
      case ExportFormat.json:
        final records = value.history
            .map(
              (item) => {
                'id': item.id,
                'type': item.type,
                'toAddress': item.toAddress,
                'amount': item.amount,
                'status': item.status,
                'txHash': item.txHash,
                'timestamp': item.timestamp.toIso8601String(),
              },
            )
            .toList(growable: false);
        return jsonEncode({'records': records, 'total': records.length});
    }
  }

  String _ext(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.pdf:
        return 'pdf';
      case ExportFormat.json:
        return 'json';
    }
  }

  Future<void> _refreshFromRemote() async {
    value = value.copyWith(loading: true, clearErrorText: true);
    try {
      final assets = await _useCase.loadAssets();
      final history = await _useCase.loadHistory(limit: 20);
      value = value.copyWith(
        assets: assets,
        history: history,
        loading: false,
      );
    } catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
    }
  }
}
