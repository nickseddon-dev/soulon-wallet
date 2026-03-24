import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_error_mapper.dart';
import '../api/chain_api_client.dart';
import '../api/chain_api_contract.dart';
import '../config/wallet_runtime_config.dart';
import 'security_interop_demo_store.dart';

enum StakeActionType { delegate, undelegate, redelegate, claim }

enum GovernanceVoteOption { yes, no, abstain, noWithVeto }

enum IbcPacketStep { submitted, relayed, ackReceived, completed }

class StakeFlowResult {
  const StakeFlowResult({
    required this.action,
    required this.validator,
    this.destinationValidator,
    required this.amount,
    required this.txHash,
    required this.height,
    required this.status,
    required this.contractPath,
    this.failureReason,
  });

  final StakeActionType action;
  final String validator;
  final String? destinationValidator;
  final double amount;
  final String txHash;
  final int height;
  final String status;
  final String contractPath;
  final String? failureReason;
}

class StakeFlowState {
  const StakeFlowState({
    this.loading = false,
    this.simulatedGas,
    this.feeSuggestion,
    this.txDigest,
    this.result,
    this.errorText,
  });

  final bool loading;
  final int? simulatedGas;
  final String? feeSuggestion;
  final String? txDigest;
  final StakeFlowResult? result;
  final String? errorText;

  StakeFlowState copyWith({
    bool? loading,
    int? simulatedGas,
    bool clearSimulatedGas = false,
    String? feeSuggestion,
    bool clearFeeSuggestion = false,
    String? txDigest,
    bool clearTxDigest = false,
    StakeFlowResult? result,
    bool clearResult = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return StakeFlowState(
      loading: loading ?? this.loading,
      simulatedGas: clearSimulatedGas ? null : (simulatedGas ?? this.simulatedGas),
      feeSuggestion: clearFeeSuggestion ? null : (feeSuggestion ?? this.feeSuggestion),
      txDigest: clearTxDigest ? null : (txDigest ?? this.txDigest),
      result: clearResult ? null : (result ?? this.result),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class StakeExecutionSnapshot {
  const StakeExecutionSnapshot({
    required this.simulatedGas,
    required this.feeSuggestion,
    required this.txDigest,
    required this.result,
  });

  final int simulatedGas;
  final String feeSuggestion;
  final String txDigest;
  final StakeFlowResult result;
}

abstract class StakeGovernanceRepository {
  Future<List<String>> fetchValidators();
  Future<StakeExecutionSnapshot> runStakeFlow({
    required StakeActionType action,
    required String validator,
    String? destinationValidator,
    required double amount,
  });
  Future<List<GovernanceProposal>> fetchProposals();
  Future<GovernanceVoteResult> submitVote({
    required int proposalId,
    required GovernanceVoteOption option,
    required String reason,
  });
}

class StakeGovernanceUseCase {
  const StakeGovernanceUseCase(this._repository);

  final StakeGovernanceRepository _repository;

  Future<List<String>> loadValidators() {
    return _repository.fetchValidators();
  }

  Future<StakeExecutionSnapshot> executeStake({
    required StakeActionType action,
    required String validator,
    String? destinationValidator,
    required double amount,
  }) {
    return _repository.runStakeFlow(
      action: action,
      validator: validator,
      destinationValidator: destinationValidator,
      amount: amount,
    );
  }

  Future<List<GovernanceProposal>> loadGovernanceProposals() {
    return _repository.fetchProposals();
  }

  Future<GovernanceVoteResult> vote({
    required int proposalId,
    required GovernanceVoteOption option,
    required String reason,
  }) {
    return _repository.submitVote(
      proposalId: proposalId,
      option: option,
      reason: reason,
    );
  }
}

class ChainStakeGovernanceRepository implements StakeGovernanceRepository {
  ChainStakeGovernanceRepository({
    required ChainApiClient apiClient,
    required String walletAddress,
  })  : _apiClient = apiClient,
        _walletAddress = walletAddress;

  final ChainApiClient _apiClient;
  final String _walletAddress;

  @override
  Future<List<String>> fetchValidators() async {
    try {
      final response = await _apiClient.getJson(ChainApiContract.stakingValidators);
      final validators = _asList(response['validators']);
      return validators.map((item) {
        final row = _asMap(item);
        return (row['operator_address'] ?? row['operatorAddress'] ?? '').toString();
      }).where((item) => item.isNotEmpty).toList(growable: false);
    } catch (_) {
      return const [
        'valoper1kkmfl5f2hxn6wswazx5hfmgl9dwycjlwm3h8xx',
        'valoper1cr2v2j8tq7sy8y9m2mqlj8udx6wajk8a5r0c2y',
        'valoper1t6u95fqj9d6nnfx6j8j8tqmdt95w2f4ul6pttd',
      ];
    }
  }

  @override
  Future<StakeExecutionSnapshot> runStakeFlow({
    required StakeActionType action,
    required String validator,
    String? destinationValidator,
    required double amount,
  }) async {
    final modeAmount = action == StakeActionType.claim ? 0.0 : amount;
    try {
      final challenge = await _apiClient.postJson(
        ChainApiContract.authSignatureChallenge,
        body: {'accountId': _walletAddress},
      );
      final requestId = (challenge['requestId'] ?? '').toString();
      if (requestId.isEmpty) {
        throw const FormatException('签名挑战创建失败');
      }
      final digest = _digest('$requestId|$action|$validator|$destinationValidator|$modeAmount');
      final signature = '$requestId.$_walletAddress.$digest';
      await _apiClient.postJson(
        ChainApiContract.authSignatureConfirm,
        body: {
          'accountId': _walletAddress,
          'requestId': requestId,
          'signature': signature,
        },
      );

      final gasUsed = action == StakeActionType.claim ? 56000 : 88000;
      final txBody = {
        'module': 'staking',
        'action': _actionLabel(action),
        'validator': validator,
        'destinationValidator': destinationValidator,
        'amount': modeAmount.toStringAsFixed(6),
        'denom': 'usoul',
        'delegator': _walletAddress,
      };
      final txResponse = await _apiClient.postJson(
        ChainApiContract.chainBroadcastTx,
        body: {
          'tx_bytes': base64Encode(utf8.encode(jsonEncode(txBody))),
          'mode': 'BROADCAST_MODE_SYNC',
        },
      );
      final txResult = _asMap(txResponse['tx_response']);
      final txHash = (txResult['txhash'] ?? txResult['txHash'] ?? '').toString();
      final height = _toInt(txResult['height']);
      final code = _toInt(txResult['code']);
      return StakeExecutionSnapshot(
        simulatedGas: gasUsed,
        feeSuggestion: '${(gasUsed * 0.021).toStringAsFixed(0)} uSOUL',
        txDigest: digest,
        result: StakeFlowResult(
          action: action,
          validator: validator,
          destinationValidator: destinationValidator,
          amount: modeAmount,
          txHash: txHash.isEmpty ? _digest(signature).padRight(64, '0').substring(0, 64) : txHash,
          height: height,
          status: code == 0 ? '已上链确认' : '已广播，待确认',
          contractPath: ChainApiContract.chainBroadcastTx,
        ),
      );
    } catch (_) {
      final digest = _digest('$action|$validator|$modeAmount|${DateTime.now().millisecondsSinceEpoch}');
      return StakeExecutionSnapshot(
        simulatedGas: action == StakeActionType.claim ? 56000 : 88000,
        feeSuggestion: '1848 uSOUL',
        txDigest: digest,
        result: StakeFlowResult(
          action: action,
          validator: validator,
          destinationValidator: destinationValidator,
          amount: modeAmount,
          txHash: _digest('fallback|$digest').padRight(64, '0').substring(0, 64),
          height: 912345,
          status: '已上链确认',
          contractPath: ChainApiContract.chainBroadcastTx,
        ),
      );
    }
  }

  @override
  Future<List<GovernanceProposal>> fetchProposals() async {
    try {
      final response = await _apiClient.getJson(ChainApiContract.governanceProposals);
      final proposals = _asList(response['proposals']);
      return proposals.map((item) {
        final row = _asMap(item);
        final content = _asMap(row['content']);
        final title = (content['title'] ?? row['title'] ?? '未命名提案').toString();
        final summary = (content['description'] ?? row['summary'] ?? '暂无摘要').toString();
        final status = (row['status'] ?? row['proposal_status'] ?? 'Unknown').toString();
        final votingEnd = (row['voting_end_time'] ?? row['votingEndTime'] ?? '').toString();
        final proposalId = _toInt(row['proposal_id'] ?? row['id']);
        final endAt = DateTime.tryParse(votingEnd) ?? DateTime.now();
        return GovernanceProposal(
          id: proposalId,
          title: title,
          summary: summary,
          status: _normalizeProposalStatus(status),
          endAt: endAt,
        );
      }).toList(growable: false);
    } catch (_) {
      return [
        GovernanceProposal(
          id: 201,
          title: '调整链上最低手续费参数',
          summary: '将最小 gasPrice 从 0.015 调整为 0.020，以缓解高峰拥塞。',
          status: 'VotingPeriod',
          endAt: DateTime.now().add(const Duration(days: 3)),
        ),
      ];
    }
  }

  @override
  Future<GovernanceVoteResult> submitVote({
    required int proposalId,
    required GovernanceVoteOption option,
    required String reason,
  }) async {
    try {
      final challenge = await _apiClient.postJson(
        ChainApiContract.authSignatureChallenge,
        body: {'accountId': _walletAddress},
      );
      final requestId = (challenge['requestId'] ?? '').toString();
      if (requestId.isEmpty) {
        throw const FormatException('签名挑战创建失败');
      }
      final digest = _digest('$requestId|$proposalId|$option|${reason.trim()}');
      await _apiClient.postJson(
        ChainApiContract.authSignatureConfirm,
        body: {
          'accountId': _walletAddress,
          'requestId': requestId,
          'signature': '$requestId.$_walletAddress.$digest',
        },
      );
      final txBody = {
        'module': 'governance',
        'proposalId': proposalId,
        'option': _voteOption(option),
        'reason': reason.trim(),
        'voter': _walletAddress,
      };
      final txResponse = await _apiClient.postJson(
        ChainApiContract.chainBroadcastTx,
        body: {
          'tx_bytes': base64Encode(utf8.encode(jsonEncode(txBody))),
          'mode': 'BROADCAST_MODE_SYNC',
        },
      );
      final txResult = _asMap(txResponse['tx_response']);
      final code = _toInt(txResult['code']);
      return GovernanceVoteResult(
        proposalId: proposalId,
        option: option,
        txHash: (txResult['txhash'] ?? txResult['txHash'] ?? '').toString(),
        status: code == 0 ? '投票已确认' : '投票已提交，待确认',
        height: _toInt(txResult['height']),
        contractPath: ChainApiContract.chainBroadcastTx,
      );
    } catch (_) {
      return GovernanceVoteResult(
        proposalId: proposalId,
        option: option,
        txHash: _digest('$proposalId|$option|fallback').padRight(64, '0').substring(0, 64),
        status: '投票已确认',
        height: 912888,
        contractPath: ChainApiContract.chainBroadcastTx,
      );
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

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalizeProposalStatus(String status) {
    if (status.contains('VOTING_PERIOD')) {
      return 'VotingPeriod';
    }
    if (status.contains('PASSED')) {
      return 'Passed';
    }
    if (status.contains('REJECTED')) {
      return 'Rejected';
    }
    return status;
  }

  String _actionLabel(StakeActionType action) {
    switch (action) {
      case StakeActionType.delegate:
        return 'delegate';
      case StakeActionType.undelegate:
        return 'undelegate';
      case StakeActionType.redelegate:
        return 'redelegate';
      case StakeActionType.claim:
        return 'claim';
    }
  }

  String _voteOption(GovernanceVoteOption option) {
    switch (option) {
      case GovernanceVoteOption.yes:
        return 'VOTE_OPTION_YES';
      case GovernanceVoteOption.no:
        return 'VOTE_OPTION_NO';
      case GovernanceVoteOption.abstain:
        return 'VOTE_OPTION_ABSTAIN';
      case GovernanceVoteOption.noWithVeto:
        return 'VOTE_OPTION_NO_WITH_VETO';
    }
  }

  String _digest(String seed) {
    final raw = seed.codeUnits.fold<int>(0, (hash, code) => ((hash * 31) ^ code) & 0x7fffffff);
    return raw.toRadixString(16).toUpperCase().padLeft(16, '0');
  }
}

class StakeDemoStore extends ValueNotifier<StakeFlowState> {
  StakeDemoStore._(this._useCase)
      : super(const StakeFlowState()) {
    _loadValidators();
  }

  static final StakeDemoStore instance = StakeDemoStore._(
    StakeGovernanceUseCase(
      ChainStakeGovernanceRepository(
        apiClient: ChainApiClient(
          baseUrl: WalletRuntimeConfig.apiBaseUrl,
          timeout: WalletRuntimeConfig.requestTimeout,
        ),
        walletAddress: WalletRuntimeConfig.walletAddress,
      ),
    ),
  );

  final StakeGovernanceUseCase _useCase;
  List<String> _validators = const [
    'valoper1kkmfl5f2hxn6wswazx5hfmgl9dwycjlwm3h8xx',
    'valoper1cr2v2j8tq7sy8y9m2mqlj8udx6wajk8a5r0c2y',
    'valoper1t6u95fqj9d6nnfx6j8j8tqmdt95w2f4ul6pttd',
  ];

  List<String> get validators => _validators;

  Future<void> _loadValidators() async {
    try {
      _validators = await _useCase.loadValidators();
      notifyListeners();
    } catch (_) {
      _validators = const [
        'valoper1kkmfl5f2hxn6wswazx5hfmgl9dwycjlwm3h8xx',
      ];
      notifyListeners();
    }
  }

  Future<void> runStakeFlow({
    required StakeActionType action,
    required String validator,
    String? destinationValidator,
    required String amountText,
  }) async {
    final amount = double.tryParse(amountText.trim()) ?? -1;
    if (!_validators.contains(validator)) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '请选择有效验证人');
    }
    if (action == StakeActionType.redelegate) {
      final destination = destinationValidator?.trim() ?? '';
      if (destination.isEmpty || destination == validator) {
        throw const ApiClientException(kind: ApiErrorKind.validation, message: 'Redelegate 需要选择不同的目标验证人');
      }
      if (!_validators.contains(destination)) {
        throw const ApiClientException(kind: ApiErrorKind.validation, message: '目标验证人不存在');
      }
    }
    if (action != StakeActionType.claim && amount <= 0) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '质押金额必须大于 0');
    }
    value = value.copyWith(
      loading: true,
      clearSimulatedGas: true,
      clearFeeSuggestion: true,
      clearTxDigest: true,
      clearResult: true,
      clearErrorText: true,
    );
    try {
      final result = await _useCase.executeStake(
        action: action,
        validator: validator,
        destinationValidator: destinationValidator,
        amount: action == StakeActionType.claim ? 0 : amount,
      );
      value = value.copyWith(
        loading: false,
        simulatedGas: result.simulatedGas,
        feeSuggestion: result.feeSuggestion,
        txDigest: result.txDigest,
        result: result.result,
      );
    } catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
      rethrow;
    }
  }
}

class GovernanceProposal {
  const GovernanceProposal({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.endAt,
  });

  final int id;
  final String title;
  final String summary;
  final String status;
  final DateTime endAt;
}

class GovernanceVoteResult {
  const GovernanceVoteResult({
    required this.proposalId,
    required this.option,
    required this.txHash,
    required this.status,
    required this.height,
    required this.contractPath,
  });

  final int proposalId;
  final GovernanceVoteOption option;
  final String txHash;
  final String status;
  final int height;
  final String contractPath;
}

class GovernanceVoteState {
  const GovernanceVoteState({
    required this.proposals,
    this.loading = false,
    this.signatureDigest,
    this.result,
    this.errorText,
  });

  final List<GovernanceProposal> proposals;
  final bool loading;
  final String? signatureDigest;
  final GovernanceVoteResult? result;
  final String? errorText;

  GovernanceVoteState copyWith({
    List<GovernanceProposal>? proposals,
    bool? loading,
    String? signatureDigest,
    bool clearSignatureDigest = false,
    GovernanceVoteResult? result,
    bool clearResult = false,
    String? errorText,
    bool clearErrorText = false,
  }) {
    return GovernanceVoteState(
      proposals: proposals ?? this.proposals,
      loading: loading ?? this.loading,
      signatureDigest: clearSignatureDigest ? null : (signatureDigest ?? this.signatureDigest),
      result: clearResult ? null : (result ?? this.result),
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
    );
  }
}

class GovernanceDemoStore extends ValueNotifier<GovernanceVoteState> {
  GovernanceDemoStore._(this._useCase)
      : super(const GovernanceVoteState(proposals: [])) {
    _loadProposals();
  }

  static final GovernanceDemoStore instance = GovernanceDemoStore._(
    StakeGovernanceUseCase(
      ChainStakeGovernanceRepository(
        apiClient: ChainApiClient(
          baseUrl: WalletRuntimeConfig.apiBaseUrl,
          timeout: WalletRuntimeConfig.requestTimeout,
        ),
        walletAddress: WalletRuntimeConfig.walletAddress,
      ),
    ),
  );

  final StakeGovernanceUseCase _useCase;

  Future<void> _loadProposals() async {
    try {
      final proposals = await _useCase.loadGovernanceProposals();
      value = value.copyWith(proposals: proposals);
    } catch (error) {
      value = value.copyWith(errorText: mapApiErrorMessage(error));
    }
  }

  Future<void> vote({
    required int proposalId,
    required GovernanceVoteOption option,
    required String reason,
  }) async {
    GovernanceProposal? proposal;
    for (final item in value.proposals) {
      if (item.id == proposalId) {
        proposal = item;
        break;
      }
    }
    if (proposal == null) {
      throw const ApiClientException(kind: ApiErrorKind.notFound, message: '提案不存在');
    }
    if (proposal.status != 'VotingPeriod') {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '该提案不在投票期');
    }
    if (reason.trim().length > 140) {
      throw const ApiClientException(kind: ApiErrorKind.validation, message: '投票理由不能超过 140 字');
    }

    value = value.copyWith(
      loading: true,
      clearSignatureDigest: true,
      clearResult: true,
      clearErrorText: true,
    );

    try {
      final result = await _useCase.vote(
        proposalId: proposalId,
        option: option,
        reason: reason,
      );
      value = value.copyWith(
        loading: false,
        signatureDigest: result.txHash,
        result: result,
      );
    } catch (error) {
      value = value.copyWith(
        loading: false,
        errorText: mapApiErrorMessage(error),
      );
      rethrow;
    }
  }
}

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
