import { StargateClient } from "@cosmjs/stargate";

export type NonceManager = {
  sync(): Promise<number>;
  reserve(): Promise<number>;
  reset(): void;
};

export const createNonceManager = (client: StargateClient, address: string): NonceManager => {
  let nextNonce: number | null = null;

  const sync = async (): Promise<number> => {
    const sequenceState = await client.getSequence(address);
    nextNonce = sequenceState.sequence;
    return nextNonce;
  };

  const reserve = async (): Promise<number> => {
    if (nextNonce === null) {
      await sync();
    }
    const reserved = nextNonce ?? 0;
    nextNonce = reserved + 1;
    return reserved;
  };

  const reset = () => {
    nextNonce = null;
  };

  return {
    sync,
    reserve,
    reset
  };
};
