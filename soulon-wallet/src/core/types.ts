export type ChainEnvironment = "dev" | "testnet" | "mainnet";

export type NetworkConfig = {
  chainId: string;
  bech32Prefix: string;
  rpcEndpoint: string;
  restEndpoint: string;
  grpcEndpoint: string;
  denom: string;
  gasPrice: string;
};

export type TransferInput = {
  fromAddress: string;
  toAddress: string;
  amount: string;
  memo?: string;
};

export type WalletAccount = {
  name: string;
  address: string;
};

export type DerivationPathConfig = {
  coinType: number;
  account?: number;
  change?: number;
  addressIndex?: number;
};

export type WalletSecurityPolicy = {
  requireHardwareBackedKey: boolean;
  allowMnemonicExport: boolean;
};

export type VoteOptionType = "yes" | "no" | "abstain" | "no_with_veto";

export type DelegateInput = {
  delegatorAddress: string;
  validatorAddress: string;
  amount: string;
  memo?: string;
};

export type UndelegateInput = {
  delegatorAddress: string;
  validatorAddress: string;
  amount: string;
  memo?: string;
};

export type RedelegateInput = {
  delegatorAddress: string;
  validatorSrcAddress: string;
  validatorDstAddress: string;
  amount: string;
  memo?: string;
};

export type WithdrawRewardsInput = {
  delegatorAddress: string;
  validatorAddress: string;
  memo?: string;
};

export type IBCTransferInput = {
  senderAddress: string;
  receiverAddress: string;
  sourcePort: string;
  sourceChannel: string;
  amount: string;
  timeoutSeconds?: number;
  memo?: string;
};

export type AuthzGrantInput = {
  granterAddress: string;
  granteeAddress: string;
  msgTypeUrl: string;
  expiration?: Date;
  memo?: string;
};

export type AuthzExecMessage = {
  typeUrl: string;
  value: Uint8Array;
};

export type AuthzExecInput = {
  granteeAddress: string;
  messages: AuthzExecMessage[];
  memo?: string;
};

export type AuthzRevokeInput = {
  granterAddress: string;
  granteeAddress: string;
  msgTypeUrl: string;
  memo?: string;
};

export type VoteInput = {
  voterAddress: string;
  proposalId: bigint;
  option: VoteOptionType;
  memo?: string;
};

export type TxPollStatus = "pending" | "confirmed" | "timeout";

export type TxPollResult = {
  hash: string;
  status: TxPollStatus;
  height?: number;
};
