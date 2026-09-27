#!/usr/bin/env bash
python3 - <<'EOF'
import base64, gzip
b64 = open('/tmp/suv2-b64.txt','rb').read().replace(b'\n',b'')
raw = gzip.decompress(base64.b64decode(b64))
print('decoded len:', len(raw))
print('head:', raw[:60])
print('tail:', raw[-60:])
orig = open('/mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol','rb').read()
print('orig len:', len(orig), 'match:', raw == orig)
EOF
