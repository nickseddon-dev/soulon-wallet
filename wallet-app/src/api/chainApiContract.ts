export type ChainApiMethod = 'GET' | 'POST'

export type ChainApiEndpoint = {
  method: ChainApiMethod
  path: string
}

export const chainApiContractVersion = 'v1.4.0'
export const chainApiContractFrozen = true

export const chainApiPaths = {
  health: '/v1/health',
  indexerEvents: '/v1/indexer/events',
  indexerState: '/v1/indexer/state',
  stakingValidators: '/v1/chain/staking/validators',
  stakingDelegationsTemplate: '/v1/chain/staking/delegations/{delegatorAddress}',
  distributionRewardsTemplate: '/v1/chain/distribution/delegators/{delegatorAddress}/rewards',
  governanceProposals: '/v1/chain/gov/proposals',
  governanceProposalTemplate: '/v1/chain/gov/proposals/{proposalId}',
  governanceProposalVotesTemplate: '/v1/chain/gov/proposals/{proposalId}/votes',
  chainTxTemplate: '/v1/chain/txs/{txHash}',
  chainBroadcastTx: '/v1/chain/txs',
  authSignatureChallenge: '/v1/auth/signature/challenge',
  authSignatureConfirm: '/v1/auth/signature/confirm',
  notifications: '/v1/notifications',
  notificationsStream: '/v1/notifications/stream',
  notificationsWebhook: '/v1/notifications/webhook',
} as const

export const chainApiEndpoints: ChainApiEndpoint[] = [
  { method: 'GET', path: chainApiPaths.health },
  { method: 'GET', path: chainApiPaths.indexerEvents },
  { method: 'GET', path: chainApiPaths.indexerState },
  { method: 'GET', path: chainApiPaths.stakingValidators },
  { method: 'GET', path: chainApiPaths.stakingDelegationsTemplate },
  { method: 'GET', path: chainApiPaths.distributionRewardsTemplate },
  { method: 'GET', path: chainApiPaths.governanceProposals },
  { method: 'GET', path: chainApiPaths.governanceProposalTemplate },
  { method: 'GET', path: chainApiPaths.governanceProposalVotesTemplate },
  { method: 'GET', path: chainApiPaths.chainTxTemplate },
  { method: 'POST', path: chainApiPaths.chainBroadcastTx },
  { method: 'POST', path: chainApiPaths.authSignatureChallenge },
  { method: 'POST', path: chainApiPaths.authSignatureConfirm },
  { method: 'GET', path: chainApiPaths.notifications },
  { method: 'GET', path: chainApiPaths.notificationsStream },
  { method: 'POST', path: chainApiPaths.notificationsWebhook },
]
