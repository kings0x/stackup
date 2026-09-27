#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
# Extract key without printing it; lock down perms; remove JSON copies.
if [ ! -f ~/.stackup/deployer.key ]; then
  python3 -c "import json;d=json.load(open('/home/akc21/.stackup/deployer.json'));open('/home/akc21/.stackup/deployer.key','w').write(d['data'][0]['private_key'])"
  chmod 600 ~/.stackup/deployer.key
  rm -f ~/.stackup/deployer.json ~/.stackup/deployer.txt
  echo "KEY_SECURED"
else
  echo "KEY_EXISTS"
fi
ADDR=$(cast wallet address --private-key "$(cat ~/.stackup/deployer.key)")
echo "ADDRESS:$ADDR"
cast balance "$ADDR" --rpc-url https://rpc.testnet.arc.io --ether
