#!/usr/bin/env bash
rm -rf /mnt/c/Users/Admin/Code/stackup/contracts/gz
mkdir -p /mnt/c/Users/Admin/Code/stackup/contracts/gz
gzip -9 -c /mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol | base64 -w 8000 > /tmp/sugz.txt
wc -c /tmp/sugz.txt
split -n l/5 /tmp/sugz.txt /mnt/c/Users/Admin/Code/stackup/contracts/gz/g
python3 - <<'EOF'
import glob
for f in sorted(glob.glob('/mnt/c/Users/Admin/Code/stackup/contracts/gz/g*')):
    d = open(f,'rb').read().replace(b'\n',b'')
    print(f.split('/')[-1], 'len=', len(d), 'sum=', sum(d) % 1000000007)
EOF
echo GZ_DONE
