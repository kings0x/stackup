# Oracles on Arc: Chainlink + Pyth

Two live oracle rails on Arc. StackUp has a tested adapter for each; both collapse
into the same `LIVE / HELD / INVALID` surface, so protocol logic never cares which
one prices an asset.

| | Chainlink (`ChainlinkPriceAdapter`) | Pyth (`PythPriceAdapter`) |
|---|---|---|
| Model | Push (aggregator holds latest) | **Pull** (price must be pushed first) |
| Arc testnet contract | n/a (no confirmed equity aggregator) | `0x2880aB155794e7179c9eE2e38200202908C17B43` |
| Arc mainnet | Data Feeds live (tickers unconfirmed) | Live (Pro + Indices launched day one) |
| Per-asset config | Aggregator proxy address | 32-byte price ID (universal, e.g. NVDA/USD) |
| Staleness | `updatedAt` older than `maxAge` → INVALID | `getPriceNoOlderThan` revert/old `publishTime` → INVALID |
| Quality gate | Positive, non-future round | Positive price + confidence ≤ 1% (`maxConfBps`) |
| Halt | Explicit admin `held` → HELD | Explicit admin `held` → HELD |

## Chainlink: how to point at real feeds

1. Open https://docs.chain.link/data-feeds/price-feeds/addresses, filter network = **Arc**.
2. Copy the aggregator (proxy) address for each feed you need (e.g. NVDA/USD, AAPL/USD).
3. Export before deploying:

```bash
export FEED_SNVDA=0x...  # aggregator proxy, NOT the implementation
export FEED_SAAPL=0x...
```

4. `forge script script/DeployArcTestnet.s.sol` uses `FEED_*` when set, otherwise deploys the
   admin-set `StackPriceAdapter` mock (test price $200, `setPrice()` admin-only).

## Pyth: how to point at real feeds

1. Pick the price ID for the ticker (universal across chains; find it on the Pyth
   terminal / `docs.pyth.network/price-feeds`). Example shape: `0xef...` (32 bytes).
2. Deploy one `PythPriceAdapter` per asset:

```solidity
new PythPriceAdapter(stock, stockDec, PYTH, PRICE_ID, admin);
// Arc testnet PYTH = 0x2880aB155794e7179c9eE2e38200202908C17B43
```

3. **Push before you read.** A pull price only exists on-chain after someone calls
   `updatePriceFeeds(hermesBytes)` with value = `updateFee`. Options, in order:
   - a keeper pushes fresh prices on a schedule (anyone can call; fee in native gas token);
   - the user's own bundle prepends the update tx (Hermes payload fetched off-chain) —
     `prepare_open`'s ordered-transaction format already supports this;
   - Pyth push feeds, where available.
   Without a recent update, financed actions refuse with `PRICING_UNAVAILABLE` — safe by default.
4. **Hermes needs an API key** (since Aug 2026) to fetch update payloads. Get one from
   Pyth; the key lives in the *updater* (keeper/frontend), never in contracts.

## Adapter semantics (both)

* `held` flag (admin) = issuer halt notice → `HELD`. Only explicit holds count; staleness alone = `INVALID`.
* Financed actions (`openStack` levered, `trim`, `liquidate`, `healthOf`) require `LIVE`.
  Spot open, repay, delegate, transfer, debt-zero close never touch the feed.
* Equities: keep `maxAge` 8h so overnight/weekend staleness pauses leveraged opens by design.

## Current testnet wiring (2026-09-28)

Mocks (`$200` admin-set, always LIVE) — correct for proving custody/liquidation mechanics.
Chainlink equity aggregators on Arc: **unconfirmed** (docs contain no Arc/5042 entries).
Pyth on Arc testnet: **contract confirmed**, equity price IDs + Hermes updater still open items.
First real feed on either rail flips one env var / one adapter deploy — no contract changes.
