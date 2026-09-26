#!/usr/bin/env bash
set -euo pipefail
# Installs Foundry deps (gitignored) for StackUp contracts.
mkdir -p contracts/lib
if [ ! -d contracts/lib/openzeppelin-contracts ]; then
  git clone --depth 1 https://github.com/OpenZeppelin/openzeppelin-contracts.git contracts/lib/openzeppelin-contracts
fi
if [ ! -d contracts/lib/forge-std ]; then
  git clone --depth 1 https://github.com/foundry-rs/forge-std.git contracts/lib/forge-std
fi
echo "forge deps ready."
