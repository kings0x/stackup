#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd ~/.dinari-sbt
git submodule update --init lib/forge-std lib/openzeppelin-contracts lib/openzeppelin-contracts-upgradeable lib/solady lib/prb-math 2>&1 | tail -3
echo "--- build ---"
forge build 2>&1 | tail -5
echo "--- release refs ---"
cat releases/v1.0.0/transfer_restrictor.json 2>/dev/null | head -30
cat releases/v1.0.0/dshare.json 2>/dev/null | head -40
