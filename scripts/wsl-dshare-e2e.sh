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
python3 - <<'EOF'
import json
b = json.load(open('/mnt/c/Users/Admin/Code/stackup/contracts/broadcast/ListDShare.s.sol/5042002/run-latest.json'))
for t in b['transactions']:
    if t.get('transactionType') == 'CREATE':
        print(t.get('contractName'), t.get('contractAddress'))
    if t.get('functionName') == 'listAsset':
        print('listAsset receipt:', t.get('hash'))
EOF
echo "=== mint real dShares to operator ==="
tx "$DS" "mint(address,uint256)" "$ME" 5000000000000000000
echo "=== approve + financed open 1.25x with REAL DShare (asset 4) ==="
tx "$DS" "approve(address,uint256)" "$CORE" 1000000000000000000
tx "$CORE" "openStack(uint256,uint256,uint256,uint256,string)" 4 1000000000000000000 12500 0 "real dshare accept"
echo -n "effective(5)="; cast call "$CORE" "effectiveStockOf(uint256)" 5
echo -n "debt(5)="; cast call "$CORE" "debtOf(uint256)" 5
echo "=== REAL split 3:2 via setBalancePerShare ==="
tx "$DS" "setBalancePerShare(uint128)" 1500000000000000000
echo -n "effective after split="; cast call "$CORE" "effectiveStockOf(uint256)" 5
echo -n "nav="; cast call "$CORE" "healthOf(uint256)" 5
echo "=== repay + close ==="
DEBT=$(cast call "$CORE" "debtOf(uint256)" 5 | python3 -c "import sys;print(int(sys.stdin.read().strip().split()[0],16))")
echo "DEBT=$DEBT"
tx "$USDC" "faucet(address,uint256)" "$ME" "$DEBT"
tx "$USDC" "approve(address,uint256)" "$CORE" "$DEBT"
tx "$CORE" "repay(uint256,uint256)" 5 "$DEBT"
tx "$CORE" "closeStack(uint256)" 5
echo -n "dshare dust in core="; cast call "$DS" "balanceOf(address)" "$CORE"
echo DSHARE_E2E_DONE
