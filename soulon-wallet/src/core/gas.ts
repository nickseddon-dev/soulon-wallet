import { EncodeObject } from "@cosmjs/proto-signing";
import { calculateFee, GasPrice, SigningStargateClient } from "@cosmjs/stargate";

export type GasEstimateInput = {
  client: SigningStargateClient;
  senderAddress: string;
  messages: readonly EncodeObject[];
  memo?: string;
  gasPrice: string;
  multiplier?: number;
};

export const estimateFee = async (input: GasEstimateInput) => {
  const estimatedGas = await input.client.simulate(
    input.senderAddress,
    input.messages,
    input.memo ?? ""
  );
  const gasLimit = Math.ceil(estimatedGas * (input.multiplier ?? 1.2));
  const gasPrice = GasPrice.fromString(input.gasPrice);
  return calculateFee(gasLimit, gasPrice);
};
