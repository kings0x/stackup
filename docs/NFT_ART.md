# StackUp portrait NFT

No puppies. Each Stack is a **human portrait**: person wearing a cap + chunky chain, chain pendant shows the stock logo.

## States (5 per asset)

| Stage | Visual | Trigger |
|-------|--------|---------|
| `stacked` | confident, bright, cap forward | HF >= 1.5 or spot |
| `watching` | sideways glance, muted bg | 1.0 <= HF < 1.5 |
| `at-risk` | sweat, tilted cap, red rim | 0 < HF < 1.0 but unwind not yet called |
| `liquidated` | silhouette, broken chain | terminal unwind (app-only, NFT burned) |
| `closed` | portrait walks off, cap on hook | terminal close (app-only, NFT burned) |

4 assets × 5 = 20 base images under `apps/web/public/cards/{nvda,aapl,meta,googl}/{stacked,watching,at-risk,liquidated,closed}.png`.

## Metadata

`GET /api/cards/[tokenId]` returns:

```json
{ "name": "StackUp #12 — sNVDA 1.25x", "description": "<note> — Stock <amt>, debt <usdc>.", "image": "https://stackup.fun/cards/nvda/watching.png", "attributes": [{"trait_type":"Stage","value":"watching"},{"trait_type":"Asset","value":"sNVDA"}] }
```

`StackUp.CARD_BASE = https://stackup.fun/api/cards/`. Onchain stores only `noteOf[tokenId]` (≤280 bytes, immutable). Art is off-chain so health rendering never costs gas. Marketplaces see the `stacked` face when pricing is stale (don't cache panic art on a halt).

## Generation brief (for artist / model)

"Streetwear portrait, 3/4 view, baseball cap with {TICKER} embroidery, thick gold chain with circular {TICKER} pendant, flat vector + grain, dark backdrop with {COLOR} rim light, square 1024px, no text except ticker."
Colors: NVDA green, AAPL white/grey, META blue, GOOGL multi.
