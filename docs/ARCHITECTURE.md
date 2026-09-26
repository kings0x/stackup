# StackUp architecture (Arc)

Original design. Behavior mirrors the well-understood financed-spot-NFT pattern, expressed independently.

## Components

* `StackUp` — ERC-721 coordinator + custody + accounting + risk. One `Stack` struct per token: `assetId, stockAmount, principal, accrued, updatedAt, delegate`.
* `StackVault` — protocol USDC. `draw()` callable only by `StackUp`. `available()` = idle balance. Treasury sweeps idle only.
* `StackPriceAdapter` — per-asset `latest() -> (LIVE|HELD|INVALID, price, updatedAt)` + `valueUsdc()`. Testnet: admin-set price; mainnet: Chainlink Data Feeds / Streams with `updatedAt` staleness + pause flag.
* `StackSwapAdapter` — per-asset buy/sell with `max(callerMin, oracleFloor)`. Testnet: float-funded fixed-price venue with 1% adverse bound. Mainnet: real Arc DEX.
* Mocks — `MockStock` (8d), `MockUSDC` (6d), faucet-mintable.

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
* No B20 on Arc: testnet uses `sNVDA/sAAPL` mocks; mainnet needs issuance/bridging + Chainlink equity feeds + real DEX pool per asset.
