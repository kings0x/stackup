# Dinari dShares on Arc — integration note

Dinari brought dShares to **Arc mainnet on 2026-09-16** (launch day). 700+ stocks/ETFs,
full S&P 500. Chains: Ethereum, Avalanche, Arbitrum, Base **+ Arc**.
This is the most likely source of real StackUp collateral — but dShares have three
mechanics that break naive raw-unit custody. All three are handled below.

## dShare mechanics (from Dinari docs/whitepaper)

| Event | What happens on-chain | StackUp impact |
|---|---|---|
| Dividend | **USD+ stablecoin to verified (KYC) wallets only.** dShare balance unchanged. Min $0.10, snapshot 4AM ET ex-date. | An unverified protocol contract receives **nothing** — the yield is lost to positions unless captured. |
| Split (incl. reverse) | **Token rebases** to the split ratio; balance changes for every holder. Token **paused** during processing. | Raw-unit accounting breaks: closes revert or mis-pay, surplus gets stuck, NAV lies. |
| Transfer | ERC-20 + embedded logic. **Blacklist** (OFAC/AML), not allowlist. Issuance/redemption needs KYC; secondary transfers permissionless. | Deposits, repays, closes, liquidations all work from any non-blacklisted address. No approval gate. |
| Decimals | **18** (e.g. NVDA.d on Etherscan). | Adapters take decimals as constructor params — no hardcoded 8. |

Also: no Chainlink **Dinari** feed exists (provider catalog: Ondo, Robinhood, Coinbase only).
Price dShares with the **plain equity feed** (NVDA/USD 8-dec): correct, because dShares carry
no multiplier — dividends arrive separately, so there is nothing to double-count.

## The trap, fixed (shipped in StackUp)

**Before:** `stockAmount` was raw units. A 2:1 split doubles `balanceOf(StackUp)` while every
recorded amount stays put → closes underpay (surplus stuck), reverse splits make closes
revert, NAV misprices, liquidations misfire.

**After:** per-asset custody modes, chosen at `listAsset` and immutable:

* `RAW` — fixed-supply tokens. 1 unit = 1 token. Identical to the old behavior.
* `SHARE` — rebasing-capable tokens (all dShares). Positions hold **pool shares**;
  `effectiveStock = units × custodyBalance / poolShares`. Splits flow through pro-rata,
  up or down. External API unchanged (`trim`/`close`/`liquidate` take effective amounts).

Plus:

* `sweep(token, to)` (ADMIN-only, listed stocks rejected) forwards stray tokens —
  notably **USD+ dividends** landing on the contract — to treasury. Nothing rots.
* Payouts round down; residual dust is bounded to a few base units per payout.

## Dividend paths (pick one, disclose it)

1. **Accept the loss (default).** Positions earn price exposure only; USD+ never arrives
   (contract unverified). Disclose in UI: "dShare dividends are not captured."
2. **Register the StackUp address.** Dinari qualification is per-wallet: the operating entity
   completes entity KYC and registers the deployed `StackUp` address. USD+ then lands on the
   contract and `sweep` routes it to treasury for off-chain pro-rata redistribution.
   Needs Dinari partner onboarding — start at `dinari.com/work-with-dinari`.

## Pause behavior (document, don't code around)

Dinari pauses the token during split processing: any `openStack`/`trim`/`closeStack`/`liquidate`
touching stock reverts until unpause — same class as oracle `HELD`. `repay`, `setDelegate`,
transfers, and debt reads keep working. The UI must say "issuer halt", not "app broken".

## Listing checklist (dShare on Arc)

1. Token address from Dinari dashboard / `sbt.dinari.com` token list (per-chain addresses;
   the `sbt-deployments` repo is deprecated, use `sbt-contracts/releases` + dashboard).
2. Plain Chainlink equity feed proxy for the ticker (NOT a total-return/multiplier feed).
3. Spot venue on Arc holding dShare liquidity (or protocol float adapter for bootstrap).
4. `listAsset(stock, 18, priceAdapter, swapAdapter, shareMode=true)`.
5. Seed, open 1.25x test stack, force-read `effectiveStockOf`, close. Record in manifest.

Provenance: Dinari Arc blog (2026-09-16), dShares docs (dividends, splits, restrictions),
whitepaper §2.1–2.4, Chainlink tokenized-equity provider catalog (2026-08-26).
