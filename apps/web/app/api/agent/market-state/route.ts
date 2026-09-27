import { resolveAsset, marketState, refuse } from "../../../../lib/agent";

export async function GET(req: Request) {
  const u = new URL(req.url);
  const a = resolveAsset(u.searchParams.get("asset") ?? undefined, Number(u.searchParams.get("assetId") ?? 0) || undefined);
  if (!a) return Response.json(refuse("UNKNOWN_ASSET", "Pass ?asset=sNVDA or ?assetId=1"), { status: 400 });
  try {
    const m = await marketState(a.assetId);
    return Response.json({ ok: true, asset: a.name, ...m });
  } catch {
    return Response.json(refuse("BASE_UNAVAILABLE", "Arc RPC unreachable"), { status: 502 });
  }
}
