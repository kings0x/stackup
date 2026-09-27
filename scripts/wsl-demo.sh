#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
CORE="0xb823dd1180dd8d31493614b86f19e0a7d282c28d"
SNVDA="0xb618a3e8302a29a94b069fb2ef95ba1e2b0db747"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
K="$(cat ~/.stackup/deployer.key)"
cast send "$SNVDA" "faucet(address,uint256)" "$ME" 5000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
cast send "$SNVDA" "approve(address,uint256)" "$CORE" 1000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
cast send "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 1 1000000 10000 0 "stackup demo stack" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo -n "owner(4)="; cast call "$CORE" "ownerOf(uint256)" 4
echo DEMO_DONE
