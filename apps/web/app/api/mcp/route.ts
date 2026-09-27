import { ASSETS, CHAIN, STACK_UP, USDC, LEVELS, publicClient } from "../../../lib/stackup";
import { stackUpAbi, stackVaultAbi } from "../../../lib/abi";
import { resolveAsset, marketState, quoteStack, prepareOpen, vaultAddress, levLabel } from "../../../lib/agent";

const TOOLS = [
  { name: "get_assets", description: "Supported stocks, canonical addresses, leverage presets on Arc testnet.", inputSchema: { type: "object", properties: {}, additionalProperties: false } },
  { name: "get_market_state", description: "Whether an asset can back a financed open right now.", inputSchema: { type: "object", properties: { asset: { type: "string" }, assetId: { type: "number" } }, additionalProperties: false } },
  { name: "get_vault", description: "USDC the protocol vault can still lend.", inputSchema: { type: "object", properties: {}, additionalProperties: false } },
  { name: "quote_stack", description: "Size a prospective open (no wallet needed).", inputSchema: { type: "object", properties: { asset: { type: "string" }, assetId: { type: "number" }, stockAmount: { type: "string" }, leverage: { type: "number" } }, required: ["stockAmount", "leverage"], additionalProperties: false } },
  { name: "get_stack", description: "Live Stack NFT state: owner, stock, debt, health.", inputSchema: { type: "object", properties: { tokenId: { type: "string" } }, required: ["tokenId"], additionalProperties: false } },
  { name: "prepare_open", description: "Unsigned Arc transactions opening a stack for a wallet you control.", inputSchema: { type: "object", properties: { wallet: { type: "string" }, asset: { type: "string" }, assetId: { type: "number" }, stockAmount: { type: "string" }, leverage: { type: "number" }, note: { type: "string" } }, required: ["wallet", "stockAmount", "leverage"], additionalProperties: false } },
];

async function callTool(name: string, a: any) {
  const c = publicClient();
  switch (name) {
    case "get_assets":
      return { ok: true, chainId: CHAIN.id, network: "arc-testnet", contracts: { stackUp: STACK_UP, usdc: USDC }, leveragePresets: LEVELS, assets: ASSETS };
    case "get_market_state": {
      const t = resolveAsset(a.asset, a.assetId);
      if (!t) return { ok: false, code: "UNKNOWN_ASSET", message: "Provide asset or assetId" };
      return { ok: true, asset: t.name, ...(await marketState(t.assetId)) };
    }
    case "get_vault": {
      const v = await vaultAddress();
      const avail: bigint = await c.readContract({ address: v, abi: stackVaultAbi, functionName: "available" });
      return { ok: true, availableCredit: avail.toString(), vault: v };
    }
    case "quote_stack": {
      const t = resolveAsset(a.asset, a.assetId);
      if (!t) return { ok: false, code: "UNKNOWN_ASSET", message: "Provide asset or assetId" };
      return quoteStack(t.assetId, BigInt(a.stockAmount), Number(a.leverage));
    }
    case "get_stack": {
      const id = BigInt(a.tokenId);
      const owner = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [id] }).catch(() => null);
      if (!owner) return { ok: false, code: "POSITION_NOT_FOUND", message: `Stack #${a.tokenId} does not exist` };
      const { normStack, normHealth } = await import("../../../lib/stackup");
      const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [id] }));
      const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [id] }).catch(() => null);
      const h = hraw ? normHealth(hraw) : null;
      return { ok: true, tokenId: a.tokenId, owner, assetId: s.assetId, units: s.units.toString(), debt: (h ? h.debt : s.principal + s.accrued).toString(), nav: h ? h.nav.toString() : null, pricing: h ? "live" : "unavailable" };
    }
    case "prepare_open": {
      const t = resolveAsset(a.asset, a.assetId);
      if (!t) return { ok: false, code: "UNKNOWN_ASSET", message: "Provide asset or assetId" };
      return prepareOpen(a.wallet, t.assetId, BigInt(a.stockAmount), Number(a.leverage), a.note ?? "");
    }
    default:
      return { ok: false, code: "UNKNOWN_TOOL", message: `No tool ${name}` };
  }
}

export async function POST(req: Request) {
  let body: any;
  try { body = await req.json(); } catch { return Response.json({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "Parse error" } }); }
  const { method, params, id } = body;
  if (method === "initialize") {
    return Response.json({ jsonrpc: "2.0", id, result: { protocolVersion: "2024-11-05", capabilities: { tools: {} }, serverInfo: { name: "stackup", version: "0.1.0" } } });
  }
  if (method === "notifications/initialized") return new Response(null, { status: 202 });
  if (method === "ping") return Response.json({ jsonrpc: "2.0", id, result: {} });
  if (method === "tools/list") return Response.json({ jsonrpc: "2.0", id, result: { tools: TOOLS } });
  if (method === "tools/call") {
    try {
      const result = await callTool(params?.name, params?.arguments ?? {});
      const isErr = typeof result === "object" && result !== null && "ok" in result && !(result as any).ok;
      return Response.json({ jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(result) }], isError: !!isErr } });
    } catch (e: any) {
      return Response.json({ jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify({ ok: false, code: "BASE_UNAVAILABLE", message: String(e?.message ?? e).slice(0, 300) }) }], isError: true } });
    }
  }
  return Response.json({ jsonrpc: "2.0", id, error: { code: -32601, message: `Unknown method ${method}` } });
}

export async function GET() {
  return Response.json({ ok: true, mcp: "https://stackup.fun/api/mcp", transports: ["streamable-http"], tools: TOOLS.map((t) => t.name) });
}
