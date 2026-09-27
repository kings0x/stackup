"use client";
import { useEffect, useState } from "react";
import type { Address } from "viem";
import { ASSETS, STACK_UP, fmtStock, fmtUsdc, stageOf, cardImage, publicClient, normStack, normHealth } from "../../lib/stackup";
import { stackUpAbi } from "../../lib/abi";

export default function Explore() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    (async () => {
      try {
        const c = publicClient();
        const opened = await c.getContractEvents({ address: STACK_UP, abi: stackUpAbi, eventName: "StackOpened", fromBlock: 0n });
        const ids = [...new Set(opened.map((e: any) => e.args.tokenId as bigint))].slice(-60).reverse();
        const out: any[] = [];
        for (const id of ids) {
          try {
            const owner = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [id] })) as Address;
            const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [id] }));
            const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [id] }).catch(() => null);
            const h = hraw ? normHealth(hraw) : null;
            const a = ASSETS.find((x) => x.assetId === s.assetId);
            out.push({ id: String(id), owner, asset: a?.name ?? "", symbol: a?.symbol ?? "", stock: fmtStock(s.stockAmount), stage: h ? stageOf(h.nav, h.debt) : "stacked" });
          } catch { /* burned */ }
        }
        setRows(out);
      } finally { setLoading(false); }
    })();
  }, []);
  return (
    <div>
      <h1>Explore stacks</h1>
      {loading && <p>Loading…</p>}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(220px,1fr))", gap: 12 }}>
        {rows.map((r) => (
          <a key={r.id} href={`/stack/${r.id}`} style={{ border: "1px solid #2a2d34", borderRadius: 12, padding: 12, color: "#fff", textDecoration: "none" }}>
            <img src={cardImage(r.symbol, r.stage)} alt="" width="100%" style={{ borderRadius: 8 }} />
            <div style={{ marginTop: 8, fontWeight: 700 }}>#{r.id} · {r.asset}</div>
            <div style={{ fontSize: 13, color: "#bbb" }}>{r.stock} stock · {r.stage}</div>
            <div style={{ fontSize: 11, color: "#666" }}>{r.owner.slice(0, 10)}…</div>
          </a>
        ))}
      </div>
    </div>
  );
}
