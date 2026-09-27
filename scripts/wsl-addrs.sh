#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup
python3 - <<'EOF'
import json
b = json.load(open('contracts/broadcast/DeployArcTestnet.s.sol/5042002/run-latest.json'))
created = [(t.get('contractName'), t.get('contractAddress')) for t in b['transactions'] if t.get('transactionType') == 'CREATE']
for name, addr in created:
    print(name, addr)
json.dump(created, open('/tmp/stackup-created.json', 'w'))
EOF
