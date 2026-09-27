"use client";
import { useEffect, useState } from "react";
import { createPublicClient, http, type Address } from "viem";
import { ASSETS, CHAIN, STACK_UP, fmtStock, fmtUsdc, stageOf, cardImage, publicClient, normStack, normHealth } from "../lib/stackup";
import { stackUpAbi } from "../lib/abi";
import { useWallet } from "../components/wallet";

type Row = { id: bigint; asset: string; symbol: string; stock: string; debt: string; nav: string; stage: string };

export default function Portfolio() {
  const { addr, connect } = useWallet();
  const [rows, setRows] = useState<Row[]>([]);
  const [manual, setManual] = useState("");
  const [loading, setLoading] = useState(false);

  async function load(who: string) {
    setLoading(true);
    try {
      const c = publicClient();
      const zero = "0x0000000000000000000000000000000000000000" as Address;
      const fromBlock = 0n;
      const opened = await c.getContractEvents({ address: STACK_UP, abi: stackUpAbi, eventName: "StackOpened", args: { owner: who as Address }, fromBlock });
      const ids = [...new Set(opened.map((e: any) => e.args.tokenId as bigint))];
      const out: Row[] = [];
      for (const id of ids) {
        try {
          const owner = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [id] })) as Address;
          if (owner.toLowerCase() !== who.toLowerCase()) continue;
          const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [id] }));
          const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [id] }).catch(() => null);
          const h = hraw ? normHealth(hraw) : null;
          const a = ASSETS.find((x) => x.assetId === s.assetId);
          out.push({ id, asset: a?.name ?? `#${s.assetId}`, symbol: a?.symbol ?? "???", stock: fmtStock(s.stockAmount), debt: fmtUsdc(h ? h.debt : s.principal + s.accrued), nav: h ? fmtUsdc(h.nav) : "—", stage: h ? stageOf(h.nav, h.debt) : "stacked" });
        } catch {}
      }
      setRows(out);
    } finally { setLoading(false); }
  }

  useEffect(() => { if (addr) load(addr); }, [addr]);

  return (
    <div>
      <h1>Your stacks</h1>
      {!addr ? <button onClick={connect}>Connect wallet</button> : <p style={{ color: "#888" }}>{addr} · <button onClick={() => load(addr)}>Refresh</button></p>}
      {loading && <p>Loading…</p>}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(220px,1fr))", gap: 12, marginTop: 12 }}>
        {rows.map((r) => (
          <a key={String(r.id)} href={`/stack/${String(r.id)}`} style={{ border: "1px solid #2a2d34", borderRadius: 12, padding: 12, color: "#fff", textDecoration: "none" }}>
            <img src={cardImage(r.symbol, r.stage)} alt="" width="100%" style={{ borderRadius: 8 }} />
            <div style={{ marginTop: 8, fontWeight: 700 }}>#{String(r.id)} · {r.asset}</div>
            <div style={{ fontSize: 13, color: "#bbb" }}>{r.stock} stock · ${r.debt} debt · NAV ${r.nav}</div>
            <div style={{ fontSize: 12, color: "#888" }}>stage: {r.stage}</div>
          </a>
        ))}
      </div>
      {addr && rows.length === 0 && !loading && <p style={{ color: "#888" }}>No stacks found for this wallet.</p>}
      <div style={{ marginTop: 20 }}>
        <input value={manual} onChange={(e) => setManual(e.target.value)} placeholder="Open stack # by id" style={{ padding: 8 }} />
        <button onClick={() => manual && (window.location.href = `/stack/${manual}`)}>Go</button>
      </div>
      <p><a href="/create">+ Open a stack</a></p>
    </div>
  );
}
