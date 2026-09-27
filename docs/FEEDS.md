# Chainlink feeds on Arc

Chainlink Data Feeds are live on Arc testnet (Data Feeds, Data Streams, CCIP, Proof of Reserve).
StackUp consumes them through `ChainlinkPriceAdapter` (one adapter per asset, feed address immutable).

## Testnet: how to point at real feeds

1. Open https://docs.chain.link/data-feeds/price-feeds/addresses, filter network = **Arc Testnet**.
2. Copy the aggregator (proxy) address for each feed you need (e.g. NVDA/USD, AAPL/USD).
   Equity examples that exist on other chains: `NVDA/USD` Data Feed, `NVDA/USD-Streams-RegularHoursEquityPrice`.
   If an equity feed is missing on Arc testnet, use the closest available feed or keep the mock for that asset —
   never hand-roll a price.
3. Export before deploying:

```bash
export FEED_SNVDA=0x...  # aggregator proxy, NOT the implementation
export FEED_SAAPL=0x...
```

4. `forge script script/DeployArcTestnet.s.sol` uses `FEED_*` when set, otherwise deploys the
   admin-set `StackPriceAdapter` mock (test price $200, `setPrice()` admin-only).

## Adapter semantics

* `held` flag (admin) = issuer halt notice → `HELD`. Only explicit holds count; staleness alone = `INVALID`.
* `INVALID` = zero/negative answer, `updatedAt == 0`, future timestamp, `answeredInRound < roundId`,
  age > `maxAge` (default 8h), or feed revert.
* Financed actions (`openStack` levered, `trim`, `liquidate`, `healthOf`) require `LIVE`.
  Spot open, repay, delegate, transfer, debt-zero close never touch the feed.

## Mainnet switch

* Deploy one `ChainlinkPriceAdapter` per real asset with the Arc mainnet (chain 5042) feed proxy.
* Set `maxAge` per feed volatility (equities: keep 8h to cover overnight/weekend staleness → opens pause off-hours by design).
* Add Arc sequencer-uptime guard if Chainlink publishes one for Arc (treat sequencer-down as `INVALID`).
