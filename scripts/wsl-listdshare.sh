#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
export DEPLOYER_KEY="$(cat ~/.stackup/deployer.key)"
forge script script/ListDShare.s.sol --rpc-url https://rpc.testnet.arc.io --broadcast --slow 2>&1 | tail -6
echo LIST_DONE
