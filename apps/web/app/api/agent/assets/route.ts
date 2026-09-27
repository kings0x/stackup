import { CHAIN, STACK_UP, USDC, ASSETS, LEVELS } from "../../../../lib/stackup";

export async function GET() {
  return Response.json({
    ok: true,
    chainId: CHAIN.id,
    network: "arc-testnet",
    contracts: { stackUp: STACK_UP, usdc: USDC },
    decimals: { usdc: 6 },
    leveragePresets: LEVELS.map((l) => ({ label: l.label, bps: l.bps, financed: l.bps !== 10000 })),
    assets: ASSETS.map((a) => ({ name: a.name, symbol: a.symbol, assetId: a.assetId, stock: a.stock })),
  });
}
