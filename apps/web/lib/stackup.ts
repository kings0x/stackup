import { createPublicClient, http, type Address } from "viem";

export const CHAIN = {
  id: 5042002,
  name: "Arc Testnet",
  nativeCurrency: { name: "USDC", symbol: "USDC", decimals: 18 },
  rpcUrls: { default: { http: [process.env.NEXT_PUBLIC_ARC_RPC ?? "https://rpc.testnet.arc.io"] } },
  blockExplorers: { default: { name: "Arcscan", url: "https://testnet.arcscan.app" } },
} as const;

const ZERO = "0x0000000000000000000000000000000000000000" as Address;
export const STACK_UP = (process.env.NEXT_PUBLIC_STACK_UP ?? ZERO) as Address;
export const USDC = (process.env.NEXT_PUBLIC_USDC ?? ZERO) as Address;

export type Asset = { name: string; symbol: string; assetId: number; stock: Address };
function envStocks(): Asset[] {
  try {
    const raw = process.env.NEXT_PUBLIC_STOCKS ?? "";
    if (!raw) return [];
    return (JSON.parse(raw) as any[]).map((a) => ({ name: a.name, symbol: a.symbol, assetId: a.assetId, stock: a.stock as Address }));
  } catch {
    return [];
  }
}
// Canonical addresses live in deployments/arc-testnet.json — copy them into
// apps/web/.env.local as NEXT_PUBLIC_STACK_UP / NEXT_PUBLIC_USDC / NEXT_PUBLIC_STOCKS after deploy.
const FALLBACK: Asset[] = [
  { name: "sNVDA", symbol: "NVDA", assetId: 1, stock: ZERO },
  { name: "sAAPL", symbol: "AAPL", assetId: 2, stock: ZERO },
];
export const ASSETS: Asset[] = (() => {
  const e = envStocks();
  return e.length ? e : FALLBACK;
})();

export const LEVELS = [
  { label: "1.0x", bps: 10000, hint: "Spot — no debt" },
  { label: "1.1x", bps: 11000, hint: "Light" },
  { label: "1.25x", bps: 12500, hint: "Balanced" },
  { label: "1.4x", bps: 14000, hint: "Pushing" },
  { label: "1.5x", bps: 15000, hint: "Max" },
];

export function publicClient() {
  return createPublicClient({ chain: CHAIN as any, transport: http(CHAIN.rpcUrls.default.http[0]) });
}

export const fmtStock = (raw: bigint) => (Number(raw) / 1e8).toFixed(4);
export const fmtUsdc = (raw: bigint) => (Number(raw) / 1e6).toFixed(2);

export type Stage = "stacked" | "watching" | "at-risk";
export function stageOf(nav: bigint, debt: bigint): Stage {
  if (debt === 0n) return "stacked";
  if (debt >= nav) return "at-risk";
  const equity = nav - debt;
  const ratio = Number((equity * 10000n) / nav) / 10000;
  if (ratio < 0.3) return "at-risk";
  if (ratio < 0.45) return "watching";
  return "stacked";
}

export const cardImage = (symbol: string, stage: string) =>
  `/api/cards/image?symbol=${symbol}&stage=${stage}`;

// viem returns plain arrays for tuple results — normalize by index.
export type NormStack = { assetId: number; stockAmount: bigint; principal: bigint; accrued: bigint; updatedAt: bigint; delegate: Address };
export const normStack = (s: any): NormStack => ({
  assetId: Number(s[0]),
  stockAmount: s[1] as bigint,
  principal: s[2] as bigint,
  accrued: s[3] as bigint,
  updatedAt: s[4] as bigint,
  delegate: s[5] as Address,
});
export type NormHealth = { nav: bigint; debt: bigint; unwindable: boolean };
export const normHealth = (h: any): NormHealth => ({ nav: h[0] as bigint, debt: h[1] as bigint, unwindable: h[2] as boolean });
