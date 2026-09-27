# StackUp agent API + MCP

Public, unauthenticated, wallet-agnostic read-and-prepare surface for agents.
The service never signs or broadcasts. Chain: Arc testnet (`5042002`).

| HTTP | `GET/POST /api/agent/*` |
| MCP (Streamable HTTP) | `POST /api/mcp` |

## Tools (both transports)

| Tool / endpoint | Purpose |
|---|---|
| `get_assets` / `GET /api/agent/assets` | Stocks, canonical addresses, leverage presets (1.0x–1.5x) |
| `get_market_state` / `GET /api/agent/market-state?asset=sNVDA` | LIVE pricing? openings enabled? |
| `get_vault` / `GET /api/agent/vault` | Lendable USDC |
| `quote_stack` / `POST /api/agent/quote-open`→`quote-stack` | Size an open (contract-identical floor math) |
| `get_stack` / `GET /api/agent/stack/{id}` | Owner, units, effective stock, debt, NAV/health |
| `prepare_open` / `POST /api/agent/prepare-open` | Unsigned `{to,data,value,chainId}` txs in submit order |

Conventions: `{ok:true,...}` vs `{ok:false,code,message}` — branch on `code`.
Integers are decimal strings (stock 8d, dShares 18d, USDC 6d); leverage in bps.
Protocol refusals (`PRICING_UNAVAILABLE`, `INSUFFICIENT_CREDIT`, `INSUFFICIENT_BALANCE`,
`ASSET_OPENING_DISABLED`) return HTTP 200 — a closed market is an answer, not an outage.

## Canonical agent flow

1. `get_assets` → pick asset + preset.
2. `get_market_state` → stop if `canOpenLeveraged` is false and leverage was wanted (never silently fall back to 1.0x).
3. `quote_stack` → confirm principal vs vault credit.
4. Acquire the exact stock token with your own swap tooling (StackUp never swaps for you).
5. `prepare_open` → sign + submit `transactions` in order from that wallet → read `get_stack`.

MCP config:

```json
{ "mcpServers": { "stackup": { "url": "https://stackup.fun/api/mcp" } } }
```

Limits: read + prepare opens only (no repay/close/trim/liquidate tools yet); Arc testnet only.
