import manifest from "../../../deployments/arc-testnet.json";

export const CHAIN_ID = 5042002;
export const RPC = "https://rpc.testnet.arc.io";

export function fmtStock(raw: string) {
  return (Number(raw) / 1e8).toFixed(4);
}

export function fmtUsdc(raw: string) {
  return (Number(raw) / 1e6).toFixed(2);
}

export { manifest };
