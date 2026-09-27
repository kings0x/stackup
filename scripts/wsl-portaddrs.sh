#!/usr/bin/env bash
python3 - <<'EOF'
import json
b = json.load(open('/mnt/c/Users/Admin/Code/stackup/extern/dshare/broadcast/PortDShare.s.sol/5042002/run-latest.json'))
for t in b['transactions']:
    if t.get('transactionType') == 'CREATE':
        print(t.get('contractName'), t.get('contractAddress'))
print('txns:', len(b['transactions']))
EOF
