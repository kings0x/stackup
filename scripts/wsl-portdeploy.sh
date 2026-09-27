#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/extern/dshare
if [ ! -d lib/forge-std/src ]; then
  mkdir -p lib/forge-std
  curl -sSL --max-time 180 https://codeload.github.com/foundry-rs/forge-std/tar.gz/refs/tags/v1.9.4 -o dl.tgz
  tar xzf dl.tgz --strip-components=1 -C lib/forge-std
  rm dl.tgz
fi
ls lib/
export DEPLOYER_KEY="$(cat ~/.stackup/deployer.key)"
forge script script/PortDShare.s.sol --rpc-url https://rpc.testnet.arc.io --broadcast --slow 2>&1 | tail -12
echo PORT_DEPLOY_DONE
