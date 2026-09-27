#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
CORE="0xf3155d27a9cbbce18e4618b8562e69ded0058329"
USDC="0x8f34ae9c5afe4c8ced8aad1038e8f03e38314227"
SNVDA="0x493aea8c0483999594adc73739debc1d81bd04ab"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
K="$(cat ~/.stackup/deployer.key)"
echo "=== faucet stock + approve ==="
cast send "$SNVDA" "faucet(address,uint256)" "$ME" 1000000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
cast send "$SNVDA" "approve(address,uint256)" "$CORE" 1000000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo "=== spot open 1.0x ==="
cast send "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 1 1000000 10000 0 "" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo "=== financed open 1.25x ==="
cast send "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 1 1000000 12500 0 "stackup acceptance" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo "=== state ==="
echo -n "debt(1)="; cast call "$CORE" "debtOf(uint256)" 1
echo -n "debt(2)="; cast call "$CORE" "debtOf(uint256)" 2
echo -n "health(2)="; cast call "$CORE" "healthOf(uint256)" 2 || echo UNAVAILABLE
DEBT=$(cast call "$CORE" "debtOf(uint256)" 2 | python3 -c "import sys;print(int(sys.stdin.read().strip().split()[0],16))")
echo "DEBT_RAW=$DEBT"
echo "=== faucet usdc + repay + close 2 ==="
cast send "$USDC" "faucet(address,uint256)" "$ME" "$DEBT" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
cast send "$USDC" "approve(address,uint256)" "$CORE" "$DEBT" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
cast send "$CORE" "repay(uint256,uint256)" 2 "$DEBT" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo -n "debt(2) after repay="; cast call "$CORE" "debtOf(uint256)" 2
cast send "$CORE" "closeStack(uint256)" 2 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo -n "owner(1)="; cast call "$CORE" "ownerOf(uint256)" 1
echo "ACCEPT_DONE"
