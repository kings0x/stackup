"use client";
import { useState } from "react";

export function useWallet() {
  const [addr, setAddr] = useState<string | null>(null);
  async function connect() {
    const eth = (window as any).ethereum;
    if (!eth) return alert("No injected wallet found. Install MetaMask/Rabby and add Arc Testnet (chain 5042002).");
    const accounts: string[] = await eth.request({ method: "eth_requestAccounts" });
    try {
      await eth.request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x4CEF52" }] });
    } catch {
      await eth.request({
        method: "wallet_addEthereumChain",
        params: [{ chainId: "0x4CEF52", chainName: "Arc Testnet", rpcUrls: ["https://rpc.testnet.arc.io"], nativeCurrency: { name: "USDC", symbol: "USDC", decimals: 18 }, blockExplorerUrls: ["https://testnet.arcscan.app"] }],
      });
    }
    setAddr(accounts[0]);
  }
  return { addr, connect };
}
