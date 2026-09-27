import { encodeFunctionData, type Address } from "viem";
import { ASSETS, CHAIN, LEVELS, STACK_UP, USDC, publicClient } from "./stackup";
import { stackUpAbi, erc20Abi, stackVaultAbi, stackPriceAbi } from "./abi";

export type Refusal = { ok: false; code: string; message: string };
export const refuse = (code: string, message: string): Refusal => ({ ok: false, code, message });

const BPS = 10000n;
const SPOT = 10000;
const ADVERSE = 9900n;

export function levLabel(bps: number) {
  return LEVELS.find((l) => l.bps === bps)?.label ?? `${bps / 10000}x`;
}

export function resolveAsset(asset?: string, assetId?: number) {
  if (assetId) return ASSETS.find((a) => a.assetId === assetId);
  if (asset) return ASSETS.find((a) => a.name.toLowerCase() === asset.toLowerCase() || a.symbol.toLowerCase() === asset.toLowerCase());
  return undefined;
}

export async function vaultAddress(): Promise<Address> {
  const c = publicClient();
  return (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "vault" })) as unknown as Address;
}

export async function marketState(assetId: number) {
  const c = publicClient();
  const l: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "listing", args: [BigInt(assetId)] });
  const stock = l[0] as Address;
  const priceAddr = l[2] as Address;
  const openable = l[4] as boolean;
  const shareMode = l[5] as boolean;
  let pricing: "live" | "unavailable" = "unavailable";
  try {
    const q: any = await c.readContract({ address: priceAddr, abi: stackPriceAbi, functionName: "latest" });
    if (Number(q[0]) === 0) pricing = "live";
  } catch {}
  return { stock, priceAddr, openable, shareMode, pricing, canOpenLeveraged: pricing === "live" && openable };
}

/// Size a prospective open exactly like the contracts do (floor math).
export async function quoteStack(assetId: number, stockAmount: bigint, leverage: number) {
  const a = ASSETS.find((x) => x.assetId === assetId);
  if (!a) return refuse("UNKNOWN_ASSET", `Unknown assetId ${assetId}`);
  if (!LEVELS.some((l) => l.bps === leverage)) return refuse("UNSUPPORTED_LEVERAGE", `Leverage must be one of 10000/11000/12500/14000/15000`);
  const c = publicClient();
  const l: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "listing", args: [BigInt(assetId)] }).catch(() => null);
  if (!l || l[0] === "0x0000000000000000000000000000000000000000") return refuse("UNKNOWN_ASSET", `Asset ${assetId} not listed`);
  if (!l[4]) return refuse("ASSET_OPENING_DISABLED", `New positions are paused for ${a.name}`);
  const financed = leverage !== SPOT;
  if (!financed) {
    return { ok: true as const, asset: a.name, leverage, leverageLabel: levLabel(leverage), financed: false, stockAmount: stockAmount.toString(), estimatedPrincipal: "0" };
  }
  const q: any = await c.readContract({ address: l[2] as Address, abi: stackPriceAbi, functionName: "latest" }).catch(() => null);
  if (!q || Number(q[0]) !== 0) return refuse("PRICING_UNAVAILABLE", "Fresh pricing is unavailable; leveraged opens are paused.");
  const contrib: bigint = await c.readContract({ address: l[2] as Address, abi: stackPriceAbi, functionName: "valueUsdc", args: [stockAmount, q[1] as bigint] });
  const ideal = (contrib * (BigInt(leverage) - BPS)) / BPS;
  const principal = (ideal * ADVERSE) / BPS;
  if (principal === 0n) return refuse("CONTRIBUTION_TOO_SMALL", "Contribution too small to size a loan.");
  const v = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "vault" }).catch(() => null)) as Address | null;
  const avail: bigint = v ? await c.readContract({ address: v, abi: stackVaultAbi, functionName: "available" }).catch(() => 0n) : 0n;
  if (principal > avail) return refuse("INSUFFICIENT_CREDIT", `Pool holds ${avail} but this open needs ${principal}.`);
  return { ok: true as const, asset: a.name, leverage, leverageLabel: levLabel(leverage), financed: true, pricing: "live", stockAmount: stockAmount.toString(), contributionValue: contrib.toString(), estimatedPrincipal: principal.toString(), estimatedExposure: (contrib + principal).toString(), availableCredit: avail.toString() };
}

export async function prepareOpen(wallet: string, assetId: number, stockAmount: bigint, leverage: number, note: string) {
  if (!/^0x[0-9a-fA-F]{40}$/.test(wallet)) return refuse("INVALID_INPUT", "wallet must be a 0x address");
  if (note && new TextEncoder().encode(note).length > 280) return refuse("NOTE_TOO_LONG", "Note exceeds 280 UTF-8 bytes.");
  const q = await quoteStack(assetId, stockAmount, leverage);
  if (!("ok" in q && q.ok)) return q;
  const c = publicClient();
  const a = ASSETS.find((x) => x.assetId === assetId)!;
  const l: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "listing", args: [BigInt(assetId)] });
  const bal: bigint = await c.readContract({ address: l[0] as Address, abi: erc20Abi, functionName: "balanceOf", args: [wallet as Address] }).catch(() => 0n);
  if (bal < stockAmount) return refuse("INSUFFICIENT_BALANCE", `Wallet holds ${bal} but needs ${stockAmount} of ${a.name}.`);
  const allow: bigint = await c.readContract({ address: l[0] as Address, abi: erc20Abi, functionName: "allowance", args: [wallet as Address, STACK_UP] }).catch(() => 0n);
  const txs: any[] = [];
  if (allow < stockAmount) {
    txs.push({
      kind: "approve",
      to: l[0],
      data: encodeFunctionData({ abi: erc20Abi, functionName: "approve", args: [STACK_UP, stockAmount] }),
      value: "0",
      chainId: CHAIN.id,
      description: `Approve StackUp to move ${stockAmount} ${a.name}.`,
    });
  }
  txs.push({
    kind: "open",
    to: STACK_UP,
    data: encodeFunctionData({ abi: stackUpAbi, functionName: "openStack", args: [BigInt(assetId), stockAmount, BigInt(leverage), 0n, note ?? ""] }),
    value: "0",
    chainId: CHAIN.id,
    description: `Open a ${levLabel(leverage)} ${a.name} stack.`,
  });
  return { ok: true as const, wallet, asset: a.name, leverage, financed: leverage !== SPOT, stockAmount: stockAmount.toString(), note, transactions: txs, warning: "Unsigned. Submit in order from the wallet; StackUp never signs or broadcasts." };
}
