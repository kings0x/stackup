#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
RPC="https://rpc.testnet.arc.io"
OLD_CORE="0xf3155d27a9cbbce18e4618b8562e69ded0058329"
K="$(cat ~/.stackup/deployer.key)"
ME="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
export ETH_RPC_URL="$RPC"
tx() { cast send "$@" --private-key "$K" --json | python3 -c "import json,sys;print(json.load(sys.stdin)['transactionHash'])"; }

echo "=== 1. close legacy spot token 1 on old core ==="
tx "$OLD_CORE" "closeStack(uint256)" 1

echo "=== 2. redeploy (RAW sNVDA/sAAPL + SHARE sREB) ==="
cd /mnt/c/Users/Admin/Code/stackup/contracts
export DEPLOYER_KEY="$K"
forge script script/DeployArcTestnet.s.sol --rpc-url "$RPC" --broadcast --slow > /tmp/stackup-deploy2.log 2>&1
tail -3 /tmp/stackup-deploy2.log

python3 - <<'EOF'
import json
b = json.load(open('/mnt/c/Users/Admin/Code/stackup/contracts/broadcast/DeployArcTestnet.s.sol/5042002/run-latest.json'))
created = [(t.get('contractName'), t.get('contractAddress')) for t in b['transactions'] if t.get('transactionType') == 'CREATE']
for name, addr in created: print(name, addr)
json.dump(created, open('/tmp/stackup-addrs.json', 'w'))
EOF
echo REDEPLOY_DONE
