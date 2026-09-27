#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
export DEPLOYER_KEY="$(cat ~/.stackup/deployer.key)"
forge script script/DeployArcTestnet.s.sol --rpc-url https://rpc.testnet.arc.io --broadcast --slow
echo "DEPLOY_DONE"
ls broadcast/DeployArcTestnet.s.sol/5042002/
