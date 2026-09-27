#!/usr/bin/env bash
rm -rf /mnt/c/Users/Admin/Code/stackup/contracts/gz
mkdir -p /mnt/c/Users/Admin/Code/stackup/contracts/gz
split -n l/6 /tmp/sugz.txt /mnt/c/Users/Admin/Code/stackup/contracts/gz/g
python3 - <<'EOF'
import glob
for f in sorted(glob.glob('/mnt/c/Users/Admin/Code/stackup/contracts/gz/g*')):
    d = open(f,'rb').read().replace(b'\n',b'')
    print(f.split('/')[-1], 'len=', len(d), 'sum=', sum(d) % 1000000007)
EOF
echo GZ6_DONE
