#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
echo "=== Arc testnet RPC check ==="
cast chain-id --rpc-url "$RPC"
echo "=== deployer wallet ==="
mkdir -p ~/.stackup
if [ ! -f ~/.stackup/deployer.key ]; then
  cast wallet new --json > ~/.stackup/deployer.json 2>/dev/null || cast wallet new > ~/.stackup/deployer.txt
  echo "created new wallet (see ~/.stackup/)"
  cat ~/.stackup/deployer.json 2>/dev/null || cat ~/.stackup/deployer.txt
else
  echo "reusing existing ~/.stackup/deployer.key"
fi
if [ -f ~/.stackup/deployer.key ]; then
  ADDR=$(cast wallet address --private-key "$(cat ~/.stackup/deployer.key)")
  echo "ADDRESS:$ADDR"
  echo "=== balance ==="
  cast balance "$ADDR" --rpc-url "$RPC" --ether
fi
