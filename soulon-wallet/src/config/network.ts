import { ChainEnvironment, NetworkConfig } from "../core/types.js";

const NETWORKS: Record<ChainEnvironment, NetworkConfig> = {
  dev: {
    chainId: "soulon-dev-1",
    bech32Prefix: "soulon",
    rpcEndpoint: "http://127.0.0.1:26657",
    restEndpoint: "http://127.0.0.1:1317",
    grpcEndpoint: "http://127.0.0.1:9090",
    denom: "usoul",
    gasPrice: "0.025usoul"
  },
  testnet: {
    chainId: "soulon-testnet-1",
    bech32Prefix: "soulon",
    rpcEndpoint: "https://rpc-testnet.soulon.io",
    restEndpoint: "https://api-testnet.soulon.io",
    grpcEndpoint: "https://grpc-testnet.soulon.io",
    denom: "usoul",
    gasPrice: "0.025usoul"
  },
  mainnet: {
    chainId: "soulon-mainnet-1",
    bech32Prefix: "soulon",
    rpcEndpoint: "https://rpc.soulon.io",
    restEndpoint: "https://api.soulon.io",
    grpcEndpoint: "https://grpc.soulon.io",
    denom: "usoul",
    gasPrice: "0.025usoul"
  }
};

export const getNetworkConfig = (env: ChainEnvironment): NetworkConfig => {
  return NETWORKS[env];
};
