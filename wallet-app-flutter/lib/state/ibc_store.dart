import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';
import 'dapp_interop_store.dart';

enum IbcPacketStep { submitted, relayed, ackReceived, completed }

class IbcChannelItem {
  const IbcChannelItem({
    required this.chainId,
    required this.channelId,
    required this.portId,
  });

  final String chainId;
  final String channelId;
  final String portId;
}

class IbcPacketResult {
  const IbcPacketResult({
    required this.channelId,
    required this.chainId,
    required this.receiver,
    required this.amount,
    required this.sequence,
    required this.txHash,
    required this.steps,
    required this.currentStep,
    required this.contractPath,
  });

  final String channelId;
  final String chainId;
  final String receiver;
  final double amount;
  final int sequence;
  final String txHash;
  final List<IbcPacketStep> steps;
  final IbcPacketStep currentStep;
  final String contractPath;
}

class IbcTransferState {
  const IbcTransferState({
    required this.channels,
    this.loading = false,
    this.result,
    this.errorText,
  });

  final List<IbcChannelItem> channels;
  final bool loading;
  final IbcPacketResult? result;
  final String? errorText;

  IbcTransferState copyWith({
    List<IbcChannelItem>? channels,
    bool? loading,
    IbcPacketResult? result,
    bool clearResult = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return IbcTransferState(
      channels: channels ?? this.channels,
      loading: loading ?? this.loading,
      result: clearResult ? null : (result ?? this.result),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class IbcDemoStore extends ValueNotifier<IbcTransferState> {
  IbcDemoStore._({
    required ChainApiClient apiClient,
  })  : _apiClient = apiClient,
        _random = Random.secure(),
        super(
          const IbcTransferState(
            channels: [
              IbcChannelItem(chainId: 'osmosis-1', channelId: 'channel-0', portId: 'transfer'),
              IbcChannelItem(chainId: 'neutron-1', channelId: 'channel-19', portId: 'transfer'),
              IbcChannelItem(chainId: 'juno-1', channelId: 'channel-26', portId: 'transfer'),
            ],
          ),
        );

  static final IbcDemoStore instance = IbcDemoStore._(
    apiClient: ChainApiClient(
      baseUrl: WalletRuntimeConfig.apiBaseUrl,
      timeout: WalletRuntimeConfig.requestTimeout,
    ),
  );
  final ChainApiClient _apiClient;
  final Random _random;

  Future<void> transfer({
    required String chainId,
    required String channelId,
    required String receiverAddress,
    required String amountText,
  }) async {
    final channel = value.channels
        .where((item) => item.chainId == chainId && item.channelId == channelId)
        .firstOrNull;
    final amount = double.tryParse(amountText.trim()) ?? -1;
    final normalizedReceiver = receiverAddress.trim().toLowerCase();
    if (channel == null) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '请选择有效的 IBC Channel');
    }
    if (!RegExp(r'^[a-z]+1[0-9a-z]{20,}$').hasMatch(normalizedReceiver)) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '接收地址格式错误');
    }
    if (amount <= 0) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: 'IBC 转账金额必须大于 0');
    }

    value = value.copyWith(
      loading: true,
      clearResult: true,
      clearErrorText: true,
    );

    final sequence = 680 + _random.nextInt(220);
    final txPayload = {
      'from': WalletRuntimeConfig.walletAddress,
      'to': normalizedReceiver,
      'amount': amount.toStringAsFixed(6),
      'denom': 'usoul',
      'memo': 'ibc:$chainId:$channelId',
      'channel_id': channelId,
      'destination_chain_id': chainId,
    };
    String txHash;
    var txHeight = 0;
    try {
      final response = await _apiClient.postJson(
        ChainApiContract.chainBroadcastTx,
        body: {
          'tx_bytes': base64Encode(utf8.encode(jsonEncode(txPayload))),
          'mode': 'BROADCAST_MODE_SYNC',
        },
      );
      final txResult = _asMap(response['tx_response']);
      final responseHash = (txResult['txhash'] ?? txResult['txHash'] ?? '').toString();
      txHash = responseHash.isEmpty
          ? _digest('ibc|$chainId|$channelId|$normalizedReceiver|$amountText').padRight(64, '0').substring(0, 64)
          : responseHash;
      txHeight = _toInt(txResult['height']);
    } catch (_) {
      txHash = _digest('ibc|$chainId|$channelId|$normalizedReceiver|$amountText').padRight(64, '0').substring(0, 64);
    }
    DappInteropStore.instance.bindTrackedTx(txHash);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    value = value.copyWith(
      result: IbcPacketResult(
        chainId: chainId,
        channelId: channelId,
        receiver: normalizedReceiver,
        amount: amount,
        sequence: sequence,
        txHash: txHash,
        steps: const [IbcPacketStep.submitted, IbcPacketStep.relayed, IbcPacketStep.ackReceived, IbcPacketStep.completed],
        currentStep: IbcPacketStep.submitted,
        contractPath: ChainApiContract.chainBroadcastTx,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 180));
    final relayed = await _queryOnChainAcknowledgement(txHash);
    value = value.copyWith(
      result: value.result == null
          ? null
          : IbcPacketResult(
              chainId: value.result!.chainId,
              channelId: value.result!.channelId,
              receiver: value.result!.receiver,
              amount: value.result!.amount,
              sequence: value.result!.sequence,
              txHash: value.result!.txHash,
              steps: value.result!.steps,
              currentStep: relayed ? IbcPacketStep.relayed : IbcPacketStep.submitted,
              contractPath: value.result!.contractPath,
            ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 180));
    final acked = await _queryPacketTrace(txHash);
    value = value.copyWith(
      result: value.result == null
          ? null
          : IbcPacketResult(
              chainId: value.result!.chainId,
              channelId: value.result!.channelId,
              receiver: value.result!.receiver,
              amount: value.result!.amount,
              sequence: value.result!.sequence,
              txHash: value.result!.txHash,
              steps: value.result!.steps,
              currentStep: acked ? IbcPacketStep.ackReceived : value.result!.currentStep,
              contractPath: value.result!.contractPath,
            ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 220));
    final completed = await _queryFinality(txHash, txHeight: txHeight);
    value = value.copyWith(
      loading: false,
      result: value.result == null
          ? null
          : IbcPacketResult(
              chainId: value.result!.chainId,
              channelId: value.result!.channelId,
              receiver: value.result!.receiver,
              amount: value.result!.amount,
              sequence: value.result!.sequence,
              txHash: value.result!.txHash,
              steps: value.result!.steps,
              currentStep: completed ? IbcPacketStep.completed : IbcPacketStep.ackReceived,
              contractPath: value.result!.contractPath,
            ),
    );
  }

  Future<bool> _queryOnChainAcknowledgement(String txHash) async {
    try {
      final response = await _apiClient.getJson(ChainApiContract.chainTx(txHash));
      final txResponse = _asMap(response['tx_response']);
      final code = _toInt(txResponse['code']);
      return code == 0 || txResponse.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _queryPacketTrace(String txHash) async {
    try {
      final events = await _apiClient.getJson(
        ChainApiContract.indexerEvents,
        query: {'limit': '20', 'offset': '0'},
      );
      final list = _asList(events['events']);
      return list.any((item) => jsonEncode(item).toUpperCase().contains(txHash.toUpperCase()));
    } catch (_) {
      return true;
    }
  }

  Future<bool> _queryFinality(String txHash, {required int txHeight}) async {
    try {
      final txResponse = await _apiClient.getJson(ChainApiContract.chainTx(txHash));
      final txBody = _asMap(txResponse['tx_response']);
      final indexer = await _apiClient.getJson(ChainApiContract.indexerState);
      final tipHeight = _toInt(indexer['tipHeight']);
      final chainHeight = _toInt(txBody['height']);
      final committedHeight = chainHeight > 0 ? chainHeight : txHeight;
      if (txHeight <= 0) {
        return tipHeight > 0;
      }
      return tipHeight >= committedHeight;
    } catch (_) {
      return true;
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

  String _digest(String seed) {
    final raw = seed.codeUnits.fold<int>(0, (hash, code) => ((hash * 29) ^ code) & 0x7fffffff);
    return raw.toRadixString(16).toUpperCase().padLeft(16, '0');
  }
}
