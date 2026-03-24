import { OfflineSigner } from "@cosmjs/proto-signing";
import { GasPrice, SigningStargateClient, StargateClient } from "@cosmjs/stargate";
import { NetworkConfig } from "./types.js";

export const createQueryClient = async (network: NetworkConfig): Promise<StargateClient> => {
  return StargateClient.connect(network.rpcEndpoint);
};

export const createSigningClient = async (
  network: NetworkConfig,
  signer: OfflineSigner
): Promise<SigningStargateClient> => {
  return SigningStargateClient.connectWithSigner(network.rpcEndpoint, signer, {
    gasPrice: GasPrice.fromString(network.gasPrice)
  });
};
