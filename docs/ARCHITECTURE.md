# StackUp architecture (Arc)

Original design. Behavior mirrors the well-understood financed-spot-NFT pattern, expressed independently.

## Components

* `StackUp` — ERC-721 coordinator + custody + accounting + risk. One `Stack` struct per token: `assetId, units, principal, accrued, updatedAt, delegate`. `units` are raw stock (RAW assets) or pool shares (SHARE assets).
* `StackVault` — protocol USDC. `draw()` callable only by `StackUp`. `available()` = idle balance. Treasury sweeps idle only.
* `StackPriceAdapter` — per-asset `latest() -> (LIVE|HELD|INVALID, price, updatedAt)` + `valueUsdc()`. Testnet: admin-set price; mainnet: Chainlink Data Feeds / Streams with `updatedAt` staleness + pause flag.
* `ChainlinkPriceAdapter` — production adapter wrapping any AggregatorV3 feed (explicit `held` flag, staleness/zero/negative/future → `INVALID`).
* `StackSwapAdapter` — per-asset buy/sell with `max(callerMin, oracleFloor)`. Testnet: float-funded fixed-price venue with 1% adverse bound. Decimals parameterized (8-dec mocks, 18-dec dShares). Mainnet: real Arc DEX.
* Mocks — `MockStock` (8d), `MockUSDC` (6d), `MockRebasingStock` (8d, admin `rebase()` + pause, Dinari-split model), all faucet-mintable.

## Custody modes (the rebase trap, fixed)

Rebasing equities (Dinari dShares rebase on splits) change `balanceOf(StackUp)` without any
transaction. Raw-unit accounting would then underpay closes, revert on reverse splits, and
misprice NAV. Fix: per-asset mode chosen at `listAsset`, immutable.

* `RAW` (`shareMode=false`): 1 unit = 1 token. Fixed-supply tokens only.
* `SHARE` (`shareMode=true`): positions hold pool shares. `effectiveStock = units × custody / poolShares`
  — splits flow through pro-rata both directions. External API unchanged (`trim`/`close`/`liquidate`
  take effective amounts; minting converts measured inflow at the live pool ratio, ERC-4626 style).
* Payouts round down (dust stays in custody, benefits remaining holders, bounded to base units).
* `sweep(token, to)` (ADMIN-only, listed stocks rejected) forwards stray tokens such as USD+
  dividend distributions to treasury. See `DINARI.md`.

## Lifecycle

`openStack(assetId, stockAmount, leverageBps, minOut, note)` → `repay(tokenId, amount)` → `trim(tokenId, stockAmount, minOut)` → `setDelegate(tokenId, who)` → `closeStack(tokenId)` → `liquidate(tokenId)` → ERC-721 `transfer`.

* Presets: 10000 / 11000 / 12500 / 14000 / 15000. Spot skips oracle. Financed needs LIVE, sizes `loan = contrib*(lev-1)*0.99`, checks post-swap `NAV*10000 <= (NAV-loan)*lev`.
* Interest: `principal * 10% * elapsed / 365d`, lazy, interest-first repay, capped at debt (no overpay residue).
* Transfer: no oracle/health gate, clears `delegate` in `_update` before receiver callback.
* Unwind: permissionless, full, no reward. `out -> vault up to debt`, surplus -> owner, `short = debt - paid` emitted as `ShortfallCovered`, treasury absorbs.
* Oracle matrix: spot open / repay / delegate / transfer / debt-zero close = always; stacked open / trim / unwind / NAV = LIVE only.

## Arc specifics

* Chain IDs: testnet `5042002`, mainnet `5042`. Gas in USDC — scripts must fund deployer with testnet USDC from `faucet.circle.com`.
* Manifests: `deployments/arc-testnet.json` (now) / `arc-mainnet.json` (goal). Web reads manifest, never hardcodes.
* No B20 on Arc: testnet uses `sNVDA/sAAPL` mocks (RAW) + `sREB` rebasing mock (SHARE).
  Mainnet target is **Dinari dShares** (live on Arc mainnet since 2026-09-16) — see `DINARI.md`
  + `ISSUERS.md`. dShares are 18-decimal, rebase on splits, pay USD+ dividends to verified
  wallets only, and have no Chainlink issuer feed (use plain equity feeds).
