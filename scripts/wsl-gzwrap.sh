#!/usr/bin/env bash
rm -rf /mnt/c/Users/Admin/Code/stackup/contracts/gz
mkdir -p /mnt/c/Users/Admin/Code/stackup/contracts/gz
gzip -9 -c /mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol | base64 -w 1000 > /mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt
wc -lc /mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt
python3 - <<'EOF'
d = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt','rb').read().replace(b'\n',b'')
print('total len=', len(d), 'sum=', sum(d) % 1000000007)
EOF
echo GZWRAP_DONE
