#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
CORE="0xb823dd1180dd8d31493614b86f19e0a7d282c28d"
USDC="0xc41e67a92364353edbb6f9ee0537f8d685562628"
SNVDA="0xb618a3e8302a29a94b069fb2ef95ba1e2b0db747"
SREB="0x6479229e3fe2ddb4c3e8faaf844b0e86a8f8f988"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
K="$(cat ~/.stackup/deployer.key)"
tx() { cast send "$@" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"; }

echo "=== RAW spot open+close (asset 1) ==="
tx "$SNVDA" "faucet(address,uint256)" "$ME" 1000000
tx "$SNVDA" "approve(address,uint256)" "$CORE" 1000000
tx "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 1 1000000 10000 0 ""
echo -n "debt(1)="; cast call "$CORE" "debtOf(uint256)" 1
tx "$CORE" "closeStack(uint256)" 1

echo "=== RAW financed open+repay+close ==="
tx "$SNVDA" "faucet(address,uint256)" "$ME" 1000000
tx "$SNVDA" "approve(address,uint256)" "$CORE" 1000000
tx "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 1 1000000 12500 0 "v2 accept"
DEBT=$(cast call "$CORE" "debtOf(uint256)" 2 | python3 -c "import sys;print(int(sys.stdin.read().strip().split()[0],16))")
echo "DEBT2=$DEBT"
tx "$USDC" "faucet(address,uint256)" "$ME" "$DEBT"
tx "$USDC" "approve(address,uint256)" "$CORE" "$DEBT"
tx "$CORE" "repay(uint256,uint256)" 2 "$DEBT"
tx "$CORE" "closeStack(uint256)" 2

echo "=== SHARE spot open, split x2, trim half, close (asset 3) ==="
tx "$SREB" "faucet(address,uint256)" "$ME" 100000000
tx "$SREB" "approve(address,uint256)" "$CORE" 100000000
tx "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 3 100000000 10000 0 "rebasing accept"
echo -n "eff(3)="; cast call "$CORE" "effectiveStockOf(uint256)" 3
tx "$SREB" "rebase(uint256)" 2000000000000000000
echo -n "eff(3) after split="; cast call "$CORE" "effectiveStockOf(uint256)" 3
tx "$CORE" "trim(uint256,uint256,uint256)" 3 100000000 0
echo -n "eff(3) after trim="; cast call "$CORE" "effectiveStockOf(uint256)" 3
tx "$CORE" "closeStack(uint256)" 3
echo -n "sREB dust left in core="; cast call "$SREB" "balanceOf(address)" "$CORE"

echo "=== sweep stray USDC ==="
tx "$USDC" "faucet(address,uint256)" "$CORE" 5000000
tx "$CORE" "sweep(address,address)" "$USDC" "$ME"
echo ACCEPT_V2_DONE
