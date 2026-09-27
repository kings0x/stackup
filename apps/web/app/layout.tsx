import type { Metadata } from "next";

export const metadata: Metadata = { title: "StackUp — stacked spot on Arc", description: "Deposit spot stock, stack protocol capital, own the stack as a portrait NFT." };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif", background: "#0c0d10", color: "#f2f2f2" }}>
        <header style={{ display: "flex", gap: 16, padding: "14px 20px", borderBottom: "1px solid #26282e", alignItems: "center" }}>
          <a href="/" style={{ color: "#fff", fontWeight: 800, letterSpacing: 2, textDecoration: "none" }}>STACKUP</a>
          <nav style={{ display: "flex", gap: 12 }}>
            <a href="/" style={{ color: "#ccc" }}>Portfolio</a>
            <a href="/explore" style={{ color: "#ccc" }}>Explore</a>
            <a href="/create" style={{ color: "#ccc" }}>Create</a>
          </nav>
          <span style={{ marginLeft: "auto", fontSize: 12, color: "#888" }}>Arc Testnet · 5042002 · gas in USDC</span>
        </header>
        <main style={{ maxWidth: 960, margin: "0 auto", padding: 20 }}>{children}</main>
      </body>
    </html>
  );
}
