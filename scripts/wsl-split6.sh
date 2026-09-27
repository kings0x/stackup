#!/usr/bin/env bash
rm -rf /mnt/c/Users/Admin/Code/stackup/contracts/chunks
mkdir -p /mnt/c/Users/Admin/Code/stackup/contracts/chunks
split -n l/6 /tmp/suv2-b64.txt /mnt/c/Users/Admin/Code/stackup/contracts/chunks/c
python3 - <<'EOF'
import glob
for f in sorted(glob.glob('/mnt/c/Users/Admin/Code/stackup/contracts/chunks/c*')):
    d = open(f,'rb').read().replace(b'\n',b'')
    print(f.split('/')[-1], 'len=', len(d), 'sum=', sum(d) % 1000000007)
EOF
echo SPLIT6_DONE
