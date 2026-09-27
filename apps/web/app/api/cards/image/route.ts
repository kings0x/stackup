import { portraitSvg } from "../../../../lib/portrait";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const symbol = searchParams.get("symbol") ?? "STACK";
  const stage = searchParams.get("stage") ?? "stacked";
  const svg = portraitSvg(symbol, stage);
  return new Response(svg, { headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=60" } });
}
