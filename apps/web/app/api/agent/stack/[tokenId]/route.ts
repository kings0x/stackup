import { ASSETS, fmtStock, fmtUsdc, publicClient, STACK_UP, stageOf } from "../../../../../lib/stackup";
import { stackUpAbi } from "../../../../../lib/abi";
import { normStack, normHealth } from "../../../../../lib/stackup";
import { refuse } from "../../../../../lib/agent";

export async function GET(_req: Request, ctx: { params: Promise<{ tokenId: string }> }) {
  const { tokenId } = await ctx.params;
  let id: bigint;
  try { id = BigInt(tokenId); } catch { return Response.json(refuse("INVALID_INPUT", "tokenId must be an integer"), { status: 400 }); }
  const c = publicClient();
  const owner = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [id] }).catch(() => null);
  if (!owner) return Response.json(refuse("POSITION_NOT_FOUND", `Stack #${tokenId} does not exist`), { status: 404 });
  const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [id] }));
  const eff = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "effectiveStockOf", args: [id] }).catch(() => s.units)) as bigint;
  const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [id] }).catch(() => null);
  const h = hraw ? normHealth(hraw) : null;
  const a = ASSETS.find((x) => x.assetId === s.assetId);
  return Response.json({
    ok: true, tokenId, owner, asset: a?.name ?? `#${s.assetId}`, assetId: s.assetId,
    units: s.units.toString(), effectiveStock: eff.toString(), effectiveStockFmt: fmtStock(eff),
    principal: s.principal.toString(), accrued: s.accrued.toString(),
    debt: (h ? h.debt : s.principal + s.accrued).toString(),
    nav: h ? h.nav.toString() : null,
    stage: h ? stageOf(h.nav, h.debt) : "pricing_unavailable",
    delegate: s.delegate, note: await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "noteOf", args: [id] }).catch(() => ""),
  });
}
