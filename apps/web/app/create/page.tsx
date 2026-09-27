"use client";
import { useEffect, useState } from "react";
import { createWalletClient, custom, parseUnits, type Address } from "viem";
import { ASSETS, CHAIN, LEVELS, STACK_UP, fmtStock, fmtUsdc, publicClient } from "../../lib/stackup";
import { stackUpAbi, erc20Abi } from "../../lib/abi";
import { useWallet } from "../../components/wallet";

export default function Create() {
  const { addr, connect } = useWallet();
  const [assetId, setAssetId] = useState(1);
  const [amount, setAmount] = useState("0.01");
  const [lev, setLev] = useState(12500);
  const [note, setNote] = useState("");
  const [bal, setBal] = useState("—");
  const [status, setStatus] = useState("");

  const asset = ASSETS.find((a) => a.assetId === assetId) ?? ASSETS[0];

  useEffect(() => {
    (async () => {
      if (!addr || !asset) return;
      try {
        const c = publicClient();
        const b = (await c.readContract({ address: asset.stock, abi: erc20Abi, functionName: "balanceOf", args: [addr as Address] })) as bigint;
        setBal(fmtStock(b));
      } catch { setBal("—"); }
    })();
  }, [addr, assetId]);

  async function open() {
    setStatus("Working…");
    try {
      const eth = (window as any).ethereum;
      const c = publicClient();
      const raw = parseUnits(amount || "0", 8);
      const allow = (await c.readContract({ address: asset.stock, abi: erc20Abi, functionName: "allowance", args: [addr as Address, STACK_UP] })) as bigint;
      const wc = createWalletClient({ chain: CHAIN as any, transport: custom(eth), account: addr as Address });
      if (allow < raw) {
        const h1 = await wc.writeContract({ chain: CHAIN as any, address: asset.stock, abi: erc20Abi, functionName: "approve", args: [STACK_UP, raw] });
        setStatus(`Approval sent: ${h1}. Waiting…`);
        await c.waitForTransactionReceipt({ hash: h1 });
      }
      const h2 = await wc.writeContract({ chain: CHAIN as any, address: STACK_UP, abi: stackUpAbi, functionName: "openStack", args: [BigInt(assetId), raw, BigInt(lev), 0n, note] });
      setStatus(`Opening: ${h2}. Waiting for receipt…`);
      await c.waitForTransactionReceipt({ hash: h2 });
      setStatus(`Done: ${h2}. Check Portfolio.`);
    } catch (e: any) { setStatus(`Failed: ${e?.shortMessage ?? e?.message ?? e}`); }
  }

  return (
    <div>
      <h1>Open a stack</h1>
      {!addr ? <button onClick={connect}>Connect wallet</button> : <p style={{ color: "#888" }}>{addr} · balance: {bal} {asset?.name}</p>}
      <h3>1 · Stock</h3>
      <div style={{ display: "flex", gap: 8 }}>
        {ASSETS.map((a) => (
          <button key={a.assetId} onClick={() => setAssetId(a.assetId)} style={{ padding: "8px 14px", background: a.assetId === assetId ? "#fff" : "#222", color: a.assetId === assetId ? "#000" : "#fff" }}>{a.name}</button>
        ))}
      </div>
      <h3>2 · Collateral</h3>
      <input value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0.01" style={{ padding: 8 }} /> <span>{asset?.name}</span>
      <h3>3 · Leverage</h3>
      <div style={{ display: "flex", gap: 8 }}>
        {LEVELS.map((l) => (
          <button key={l.bps} title={l.hint} onClick={() => setLev(l.bps)} style={{ padding: "8px 14px", background: l.bps === lev ? "#fff" : "#222", color: l.bps === lev ? "#000" : "#fff" }}>{l.label}</button>
        ))}
      </div>
      <h3>4 · Note (optional, immutable, ≤280 bytes)</h3>
      <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="Why this stack?" style={{ padding: 8, width: "100%" }} />
      <div style={{ marginTop: 16 }}>
        <button onClick={open} disabled={!addr} style={{ padding: "10px 22px", fontWeight: 700 }}>Open stack →</button>
      </div>
      <p style={{ color: "#888" }}>{status}</p>
      <p style={{ fontSize: 13, color: "#888" }}>Financed opens need live pricing. Off-hours they revert — 1.0x spot always works. Borrow APR 10% simple. Equity below 30% of NAV can be liquidated.</p>
    </div>
  );
}
