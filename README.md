# StackUp

**StackUp is a financing protocol for tokenized equities on Arc. Deposit real spot stock, stack protocol capital on top, own the whole stack as one transferable NFT.**

```text
spot stock
  + protocol USDC financing
  ↓
levered spot stack (real tokens in custody)
  ↓
transferable Stack NFT (portrait + cap + chain)
```

Long-only. One stock per stack. Borrowed USDC can only buy more of the same stock — never withdrawn as cash. Transferring the NFT moves control of the existing stock + debt without unwinding it.

> Inspired by the transferable-financed-position design space (see `THIRD_PARTY_NOTICES.md`). StackUp is an original implementation targeting **Arc** (testnet first, mainnet goal). No shared git history with any other project.

## Network target

| Env | Chain | Chain ID | RPC | Explorer | Gas |
|-----|-------|----------|-----|----------|-----|
| Arc Testnet (now) | arc-testnet | `5042002` | `https://rpc.testnet.arc.io` | `https://testnet.arcscan.app` | USDC |
| Arc Mainnet (goal) | arc | `5042` | `https://rpc.mainnet.arc.io` | Arcscan | USDC |

Source of truth for deployments: `deployments/arc-testnet.json` (testnet) → `deployments/arc-mainnet.json` (later). Frontend and SDKs read only those manifests — never hardcode addresses.

## How it works

1. **Deposit** a supported stock token (testnet: `sNVDA`, `sAAPL`, `sMETA`, `sGOOGL` mocks, 8 decimals).
2. **Pick leverage**: `1.0x` (spot, no debt), `1.1x`, `1.25x`, `1.4x`, `1.5x`. Fixed presets only, chosen at open, never increasable.
3. **Stack** — protocol vault lends USDC, swaps it into more of the same stock, custodies everything in `StackUp`.
4. **Hold a portrait NFT** — generative human portrait wearing a cap + chain with the stock logo. Art changes with health: `stacked → watching → at-risk → liquidated / closed`.
5. **Manage** — repay with external USDC (oracle-free), trim exposure (LIVE pricing only), transfer freely (no health gate), close when debt is zero (stock back, NFT burned), permissionless liquidation when `LIVE` + equity/NAV < 30%.

## Repo layout

```text
contracts/            Foundry workspace (StackUp, StackVault, adapters, mocks, scripts, tests)
deployments/          arc-testnet.json = canonical addresses (frontend reads this)
apps/web/             Next.js control plane (portfolio / explore / create / stack/[id])
docs/                 ARCHITECTURE.md, NFT_ART.md
```

## Quickstart (testnet)

```bash
pnpm install
cp .env.example .env.local
# fill ARC_TESTNET_RPC, DEPLOYER_KEY (test wallet only), ARCSCAN_API_KEY

# contracts (needs foundry: https://book.getfoundry.sh/getting-started/installation)
cd contracts
forge build
forge test
forge script script/DeployArcTestnet.s.sol --rpc-url $ARC_TESTNET_RPC --broadcast

# web
pnpm --filter @stackup/web dev
```

Get testnet USDC from `https://faucet.circle.com`, Chainlink test LINK from `https://faucets.chain.link/arc-testnet`.

## Risk constants (V1)

* Borrow APR: `10%` simple, immutable, interest-first repayment
* Maintenance equity ratio: `30%` → liquidatable when `LIVE` and `equity / NAV < 0.30`
* Max open leverage: `1.5x`. Post-open drift above `1.5x` does NOT liquidate — only the maintenance breach does.
* `1.0x` never liquidates, never accrues interest, never needs an oracle.

## Disclaimer

Testnet software. No real securities. Mock stocks on testnet track no real issuer. Not investment advice. Audits required before mainnet.
