#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
HOST="https://explorer.testnet.arc.io"
ADDR="0xf3155d27a9cbbce18e4618b8562e69ded0058329"
USDC="0x8f34ae9c5afe4c8ced8aad1038e8f03e38314227"
ADMIN="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
ARGS=$(cast abi-encode 'constructor(address,address)' $USDC $ADMIN | sed 's/^0x//')
python3 - "$ADDR" "$ARGS" <<'EOF'
import json, sys, urllib.request
addr, args = sys.argv[1], sys.argv[2]
src = open('/mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol').read()
body = {
    "contract_name": "StackUp",
    "compiler_version": "v0.8.29+commit.ab55807c",
    "evm_version": "cancun",
    "optimization": True,
    "optimization_runs": 1000000,
    "source_code": src,
    "license_type": "mit",
    "constructor_args": args,
    "is_yul": False,
}
req = urllib.request.Request(
    f"https://explorer.testnet.arc.io/api/v2/smart-contracts/{addr}/verification/via/flattened-code",
    data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
try:
    print(urllib.request.urlopen(req, timeout=60).read().decode()[:500])
except Exception as e:
    print("SUBMIT_ERR:", e)
    try: print(e.read().decode()[:500])
    except Exception: pass
EOF
echo SUBMIT_DONE
