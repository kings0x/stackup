import { resolveAsset, quoteStack, refuse } from "../../../../lib/agent";

export async function POST(req: Request) {
  let b: any;
  try { b = await req.json(); } catch { return Response.json(refuse("INVALID_INPUT", "Body must be JSON"), { status: 400 }); }
  const a = resolveAsset(b.asset, b.assetId);
  if (!a) return Response.json(refuse("UNKNOWN_ASSET", "Provide asset or assetId"), { status: 400 });
  let amt: bigint;
  try { amt = BigInt(b.stockAmount); } catch { return Response.json(refuse("INVALID_INPUT", "stockAmount must be a base-unit integer string"), { status: 400 }); }
  const lev = Number(b.leverage);
  const r = await quoteStack(a.assetId, amt, lev);
  if (!("ok" in r && r.ok)) {
    const status = ["PRICING_UNAVAILABLE", "INSUFFICIENT_CREDIT", "ASSET_OPENING_DISABLED"].includes((r as any).code) ? 200 : 400;
    return Response.json(r, { status });
  }
  return Response.json(r);
}
