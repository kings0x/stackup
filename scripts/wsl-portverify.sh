#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
DS="0x29602a5895fab2c015a4840deff5e0550b990385"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
K="$(cat ~/.stackup/deployer.key)"
echo -n "name="; cast call "$DS" "name()" | python3 -c "import sys;print(sys.stdin.read())" 2>/dev/null || cast call "$DS" "name()"
echo -n "symbol="; cast call "$DS" "symbol()"
echo -n "decimals="; cast call "$DS" "decimals()"
echo -n "balancePerShare="; cast call "$DS" "balancePerShare()"
echo -n "balance(deployer)="; cast call "$DS" "balanceOf(address)" "$ME"
echo "=== split 2:1 via setBalancePerShare ==="
cast send "$DS" "setBalancePerShare(uint128)" 2000000000000000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo -n "balance after split="; cast call "$DS" "balanceOf(address)" "$ME"
echo -n "revert split back="; cast send "$DS" "setBalancePerShare(uint128)" 1000000000000000000 --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"
echo -n "balance restored="; cast call "$DS" "balanceOf(address)" "$ME"
echo PORT_VERIFY_DONE
