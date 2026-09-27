import { createPublicClient, http, type Address } from "viem";
import { CHAIN, STACK_UP, ASSETS, fmtStock, fmtUsdc, stageOf, normStack, normHealth } from "../../../../lib/stackup";
import { stackUpAbi } from "../../../../lib/abi";

export async function GET(_req: Request, ctx: { params: Promise<{ tokenId: string }> }) {
  const { tokenId } = await ctx.params;
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? "https://stackup.fun";
  try {
    const c = createPublicClient({ chain: CHAIN as any, transport: http(CHAIN.rpcUrls.default.http[0]) });
    const id = BigInt(tokenId);
    await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [id] });
    const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [id] }));
    const eff = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "effectiveStockOf", args: [id] }).catch(() => s.units)) as bigint;
    const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [id] }).catch(() => null);
    const h = hraw ? normHealth(hraw) : null;
    const note = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "noteOf", args: [id] }).catch(() => "")) as string;
    const a = ASSETS.find((x) => x.assetId === s.assetId);
    const stage = h ? stageOf(h.nav, h.debt) : "stacked";
    const image = `${base}/api/cards/image?symbol=${a?.symbol ?? "STACK"}&stage=${stage}`;
    const debt = h ? h.debt : s.principal + s.accrued;
    return Response.json({
      name: `StackUp #${tokenId} — ${a?.name ?? "unknown"} ${h ? "" : "(pricing stale)"}`,
      description: `${fmtStock(eff)} ${a?.name} in custody. Debt $${fmtUsdc(debt)}. ${note}`.trim(),
      image,
      attributes: [
        { trait_type: "Asset", value: a?.name ?? "unknown" },
        { trait_type: "Stage", value: h ? stage : "pricing unavailable" },
        { trait_type: "Stock", value: fmtStock(eff) },
      ],
    });
  } catch (e: any) {
    return Response.json({ error: "stack lookup failed", detail: String(e?.message ?? e).slice(0, 500) }, { status: 404 });
  }
}
