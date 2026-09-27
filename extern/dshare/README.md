# Dinari dShare testnet port (Arc testnet, chain 5042002)

Deploys **unmodified** Dinari contracts as a testnet port so StackUp can integrate
against genuine dShare mechanics (shares-based rebase, blacklist restrictor, UUPS).

## Sources (not vendored here — fetch to reproduce)

| Component | Source | Pin |
|---|---|---|
| `sbt/` (DShare, TransferRestrictor, ERC20Rebasing, …) | `github.com/dinaricrypto/sbt-contracts`, GPL-3.0-or-later | main @ `50f7cb5` (Sep 2026) |
| `lib/solady` | `github.com/Vectorized/solady` | tag `v0.0.255` |
| `lib/openzeppelin-contracts` | `github.com/OpenZeppelin/openzeppelin-contracts` | tag `v5.0.2` |
| `lib/openzeppelin-contracts-upgradeable` | `github.com/OpenZeppelin/openzeppelin-contracts-upgradeable` | tag `v5.0.2` |
| `lib/forge-std` | `github.com/foundry-rs/forge-std` | tag `v1.9.4` |
| `lib/prb-math`, `lib/kinto-contracts-helpers` | upstream | main (only needed if building full `sbt/src`; the port compiles the token subset) |

Only a subset of `sbt/src` is compiled (token core + restrictor + `common/NumberUtils` +
`deployment/ControlledUpgradeable`); orders/dividend/factory modules are excluded.
No Dinari file is modified. solc 0.8.25, 800 optimizer runs, cancun.

## What `script/PortDShare.s.sol` deploys

1. `TransferRestrictor` impl + ERC1967 proxy (owner = deployer, empty blacklist = permissive).
2. `DShare` impl + ERC1967 proxy, `initialize(owner, "testNVDA", "tNVDA.d", restrictor)`.
3. Grants `MINTER_ROLE` to deployer, mints 10,000 test tokens.

Deployed set: see `broadcast/PortDShare.s.sol/5042002/run-latest.json` and
`deployments/arc-testnet.json` (asset `tNVDA.d`, SHARE mode).
