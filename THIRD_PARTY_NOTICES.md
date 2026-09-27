StackUp contains original code written for this project.

Design influence:
- The transferable financed spot position pattern was popularized by public Base projects
  (e.g. hurley87/margin-call, MIT-style Next.js + Foundry + ERC-721-custody architecture).
- No code, artwork, copy, or git history was copied into this repository. All contracts,
  frontend routes, docs, and NFT concepts here are original expressions.
- If any snippet is later found to be substantially similar to third-party code, add the
  applicable license text here and in the file header.

Dependencies retain their own licenses (OpenZeppelin MIT, etc.).

Dinari sbt-contracts (GPL-3.0-or-later):
- `extern/dshare/` builds and deploys UNMODIFIED Dinari contracts
  (dinaricrypto/sbt-contracts, main @ 50f7cb5) as an Arc-testnet port for
  integration testing. Exact dependency pins in `extern/dshare/README.md`.
- No Dinari source is vendored into this repository; fetch per that README to
  reproduce. The deployed testnet bytecode corresponds to those sources.
- StackUp's own contracts (MIT, `contracts/src/`) were written independently and
  interact with dShares solely through public ERC-20 / minter interfaces at
  arms length; no Dinari code is included in them.
