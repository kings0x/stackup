#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
CORE="0xb823Dd1180dD8d31493614b86F19e0A7D282C28d"
USDC="0xC41E67a92364353EDBb6f9ee0537F8d685562628"
DS="0x29602a5895faB2C015a4840deFF5E0550B990385"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
K="$(cat ~/.stackup/deployer.key)"
tx() { cast send "$@" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"; }
for i in 1 2 3; do
  DEBT=$(cast call "$CORE" "debtOf(uint256)" 5 | python3 -c "import sys;print(int(sys.stdin.read().strip().split()[0],16))")
  echo "round $i debt=$DEBT"
  if [ "$DEBT" != "0" ]; then
    tx "$USDC" "faucet(address,uint256)" "$ME" "$DEBT" > /dev/null
    tx "$USDC" "approve(address,uint256)" "$CORE" "$DEBT" > /dev/null
    tx "$CORE" "repay(uint256,uint256)" 5 "$DEBT" > /dev/null
  fi
  if tx "$CORE" "closeStack(uint256)" 5; then echo CLOSED; break; fi
  echo "close reverted (interest dust), retrying"
done
echo -n "dshare dust in core="; cast call "$DS" "balanceOf(address)" "$CORE"
echo -n "owner(5) check="; cast call "$CORE" "ownerOf(uint256)" 5 || echo "BURNED_OK"
echo CLOSE_DONE
