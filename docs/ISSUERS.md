# Equity issuers on Arc — research note (2026-09-27, Dinari correction 2026-09-28)

Verdict: **Dinari dShares are live on Arc mainnet (2026-09-16).** No one else is.
See `DINARI.md` for mechanics + the custody fix they required (shipped).

## Issuer × Arc status

| Issuer | Product | Chains live | On Arc? |
|---|---|---|---|
| **Dinari** | **dShares (`XXX.d`), 700+ stocks/ETFs, full S&P 500** | **Ethereum, Avalanche, Arbitrum, Base + Arc** | **YES (mainnet)** |
| Coinbase | B20 (NVDAc, AAPLc, METAc, GOOGLc) | Base only | No |
| Ondo (Global Markets / Ondo Stocks) | `XXXon` total-return trackers, 440+ assets, ~$1B TVL | Ethereum, BNB Chain, Solana | No |
| Backed / Kraken (xStocks) | `XXXx` 1:1 tracker certs, 60–100+ assets, $25B+ volume | Solana, Ethereum, Mantle, TON, Ink (+Arbitrum via xChange RFQ) | No |

## Rails that DO exist on Arc

* **Chainlink Data Feeds on Arc mainnet** (since 2026-09-09 changelog). Exact equity tickers
  unconfirmed — check `docs.chain.link/data-feeds/price-feeds/addresses?network=arc` before assuming NVDA/AAPL.
* **Chainlink Data Streams + CRE + Proof of Reserve** integrated with Arc (Scale program).
* **CCIP on Arc testnet** (router `0xdE4E7FED43FAC37EB21aA0643d9852f75332eab8`,
  selector `3034092155422581607`, lane to Ethereum Sepolia). Mainnet CCIP lane status unconfirmed.

## Realistic paths to real collateral (in order)

1. **xStocks CCIP lane to Arc.** xStocks public bridge already runs on CCIP. If Backed/Kraken
   onboard Arc, `NVDAx`/`AAPLx` can move to Arc without any issuer deal on our side.
   Watch: xStocks docs "other EVM-compatible networks" list + CCIP directory Arc mainnet page.
2. **Ondo deploys on Arc.** Ondo expands chain-by-chain (ETH → BNB → Solana pattern).
   Watch: `ondo.finance/ondo-stocks` "Available on Multiple Chains".
3. **Coinbase B20 multichain.** No signal; Base-only by design today.

## Integration caveats (when a trigger fires)

* **xStocks rebase:** on EVM, `balanceOf()` returns the *adjusted* balance and the multiplier moves on
  dividends/splits. `StackUp` custody math assumes fixed raw units — the price adapter must pin a
  valuation rule (adjusted-balance × spot feed, or raw × total-return feed), never both.
* **Ondo `XXXon`:** total-return trackers like B20 (dividends reinvested as balance growth).
  Same rule: pick ONE side of the adjustment.
* **Market-hours staleness:** equity Chainlink feeds go stale overnight/weekends by design.
  `ChainlinkPriceAdapter` already maps that to `INVALID` → financed opens pause. No code change needed.
* Each new asset still needs: token address, Chainlink feed proxy, spot liquidity venue for the swap
  adapter, then `listAsset()` + manifest entry. No redeploy of core contracts.

## Sources

* Chainlink changelog "Data Feeds Expands to Arc Mainnet" (2026-09-09)
* Chainlink CCIP directory: Arc testnet page; ecosystem page for Arc
* xStocks docs (developers + introduction), Backed/Kraken acquisition (Dec 2025)
* Ondo ondo-stocks page + BNB/Solana expansion posts; Coinbase KOon page (confirms Ondo tokens on ETH + BNB only)
