enum ChainApiMethod { get, post }

class ChainApiEndpoint {
  const ChainApiEndpoint({
    required this.method,
    required this.path,
  });

  final ChainApiMethod method;
  final String path;
}

final class ChainApiContract {
  const ChainApiContract._();

  static const String version = 'v1.4.0';
  static const bool frozen = true;

  static const String health = '/v1/health';
  static const String indexerEvents = '/v1/indexer/events';
  static const String indexerState = '/v1/indexer/state';
  static const String stakingValidators = '/v1/chain/staking/validators';
  static const String stakingDelegationsTemplate = '/v1/chain/staking/delegations/{delegatorAddress}';
  static const String distributionRewardsTemplate = '/v1/chain/distribution/delegators/{delegatorAddress}/rewards';
  static const String governanceProposals = '/v1/chain/gov/proposals';
  static const String governanceProposalTemplate = '/v1/chain/gov/proposals/{proposalId}';
  static const String governanceProposalVotesTemplate = '/v1/chain/gov/proposals/{proposalId}/votes';
  static const String chainTxTemplate = '/v1/chain/txs/{txHash}';
  static const String chainBroadcastTx = '/v1/chain/txs';
  static const String authSignatureChallenge = '/v1/auth/signature/challenge';
  static const String authSignatureConfirm = '/v1/auth/signature/confirm';
  static const String notifications = '/v1/notifications';
  static const String notificationsStream = '/v1/notifications/stream';
  static const String notificationsWebhook = '/v1/notifications/webhook';

  static const List<ChainApiEndpoint> endpoints = [
    ChainApiEndpoint(method: ChainApiMethod.get, path: health),
    ChainApiEndpoint(method: ChainApiMethod.get, path: indexerEvents),
    ChainApiEndpoint(method: ChainApiMethod.get, path: indexerState),
    ChainApiEndpoint(method: ChainApiMethod.get, path: stakingValidators),
    ChainApiEndpoint(method: ChainApiMethod.get, path: stakingDelegationsTemplate),
    ChainApiEndpoint(method: ChainApiMethod.get, path: distributionRewardsTemplate),
    ChainApiEndpoint(method: ChainApiMethod.get, path: governanceProposals),
    ChainApiEndpoint(method: ChainApiMethod.get, path: governanceProposalTemplate),
    ChainApiEndpoint(method: ChainApiMethod.get, path: governanceProposalVotesTemplate),
    ChainApiEndpoint(method: ChainApiMethod.get, path: chainTxTemplate),
    ChainApiEndpoint(method: ChainApiMethod.post, path: chainBroadcastTx),
    ChainApiEndpoint(method: ChainApiMethod.post, path: authSignatureChallenge),
    ChainApiEndpoint(method: ChainApiMethod.post, path: authSignatureConfirm),
    ChainApiEndpoint(method: ChainApiMethod.get, path: notifications),
    ChainApiEndpoint(method: ChainApiMethod.get, path: notificationsStream),
    ChainApiEndpoint(method: ChainApiMethod.post, path: notificationsWebhook),
  ];

  static String stakingDelegations(String delegatorAddress) =>
      stakingDelegationsTemplate.replaceFirst('{delegatorAddress}', delegatorAddress);

  static String distributionRewards(String delegatorAddress) =>
      distributionRewardsTemplate.replaceFirst('{delegatorAddress}', delegatorAddress);

  static String governanceProposal(int proposalId) =>
      governanceProposalTemplate.replaceFirst('{proposalId}', proposalId.toString());

  static String governanceProposalVotes(int proposalId) =>
      governanceProposalVotesTemplate.replaceFirst('{proposalId}', proposalId.toString());

  static String chainTx(String txHash) => chainTxTemplate.replaceFirst('{txHash}', txHash);
}
