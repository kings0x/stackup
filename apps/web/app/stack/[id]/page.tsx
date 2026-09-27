"use client";
import { useEffect, useState } from "react";
import { createWalletClient, custom, parseUnits, type Address } from "viem";
import { ASSETS, CHAIN, STACK_UP, USDC, fmtStock, fmtUsdc, stageOf, cardImage, publicClient, normStack, normHealth } from "../../../lib/stackup";
import { stackUpAbi, erc20Abi } from "../../../lib/abi";
import { useWallet } from "../../../components/wallet";

export default function StackPage({ params }: { params: Promise<{ id: string }> }) {
  const [id, setId] = useState<string | null>(null);
  useEffect(() => { params.then((p) => setId(p.id)); }, [params]);
  const { addr, connect } = useWallet();
  const [d, setD] = useState<any>(null);
  const [repayAmt, setRepayAmt] = useState("");
  const [status, setStatus] = useState("");

  async function load() {
    if (!id) return;
    const c = publicClient();
    const tokenId = BigInt(id);
    const owner = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "ownerOf", args: [tokenId] })) as Address;
    const s = normStack(await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "stacks", args: [tokenId] }));
    const eff = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "effectiveStockOf", args: [tokenId] }).catch(() => s.units)) as bigint;
    const hraw: any = await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "healthOf", args: [tokenId] }).catch(() => null);
    const h = hraw ? normHealth(hraw) : null;
    const note = (await c.readContract({ address: STACK_UP, abi: stackUpAbi, functionName: "noteOf", args: [tokenId] }).catch(() => "")) as string;
    const a = ASSETS.find((x) => x.assetId === s.assetId);
    setD({ owner, asset: a?.name, symbol: a?.symbol, stock: eff, shares: s.units, principal: s.principal, accrued: s.accrued, delegate: s.delegate, nav: h?.nav, debt: h ? h.debt : s.principal + s.accrued, unwindable: h?.unwindable ?? false, note });
  }
  useEffect(() => { load(); }, [id]);

  async function act(fn: string, args: any[]) {
    setStatus("Working…");
    try {
      const eth = (window as any).ethereum;
      const c = publicClient();
      const wc = createWalletClient({ chain: CHAIN as any, transport: custom(eth), account: addr as Address });
      const hash = await wc.writeContract({ chain: CHAIN as any, address: STACK_UP, abi: stackUpAbi, functionName: fn as any, args: args as any });
      setStatus(`${fn}: ${hash}. Waiting…`);
      await c.waitForTransactionReceipt({ hash });
      setStatus(`${fn} confirmed.`);
      await load();
    } catch (e: any) { setStatus(`Failed: ${e?.shortMessage ?? e?.message ?? e}`); }
  }

  async function repay() {
    setStatus("Working…");
    try {
      const eth = (window as any).ethereum;
      const c = publicClient();
      const wc = createWalletClient({ chain: CHAIN as any, transport: custom(eth), account: addr as Address });
      const raw = parseUnits(repayAmt || "0", 6);
      const allow = (await c.readContract({ address: USDC, abi: erc20Abi, functionName: "allowance", args: [addr as Address, STACK_UP] })) as bigint;
      if (allow < raw) {
        const h1 = await wc.writeContract({ chain: CHAIN as any, address: USDC, abi: erc20Abi, functionName: "approve", args: [STACK_UP, raw] });
        setStatus(`USDC approval sent: ${h1}. Waiting…`);
        await c.waitForTransactionReceipt({ hash: h1 });
      }
      await act("repay", [BigInt(id!), raw]);
    } catch (e: any) { setStatus(`Failed: ${e?.shortMessage ?? e?.message ?? e}`); }
  }

  if (!id) return <p>Loading…</p>;
  return (
    <div>
      <a href="/explore">← Explore</a>
      <h1>Stack #{id}</h1>
      {!d ? <p>Loading…</p> : (
        <>
          <img src={cardImage(d.symbol, stageOf(d.nav ?? 0n, d.debt))} alt="" width={320} style={{ borderRadius: 12 }} />
          <p>Asset: <b>{d.asset}</b> · Stock: <b>{fmtStock(d.stock)}</b> · NAV: <b>{d.nav !== undefined ? `$${fmtUsdc(d.nav)}` : "stale pricing"}</b></p>
          <p>Debt: <b>${fmtUsdc(d.debt)}</b> (principal ${fmtUsdc(d.principal)} + interest ${fmtUsdc(d.accrued)})</p>
          <p>Owner: {d.owner} · Delegate: {d.delegate}</p>
          <p>Unwindable: {d.unwindable ? "YES — anyone may liquidate" : "no"}</p>
          {d.note && <p>Note: “{d.note}”</p>}
          {!addr ? <button onClick={connect}>Connect to manage</button> : (
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 12 }}>
              <span><input value={repayAmt} onChange={(e) => setRepayAmt(e.target.value)} placeholder="USDC amount" style={{ padding: 8 }} /> <button onClick={repay}>Repay</button></span>
              <button onClick={() => act("closeStack", [BigInt(id)])}>Close (needs $0 debt)</button>
              <button onClick={() => act("liquidate", [BigInt(id)])}>Liquidate</button>
            </div>
          )}
          <p style={{ color: "#888" }}>{status}</p>
        </>
      )}
    </div>
  );
}
