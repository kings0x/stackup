#!/usr/bin/env bash
python3 - <<'EOF'
d = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt','rb').read().replace(b'\n',b'')
for a in (24000, 25000, 26000, 27000):
    seg = d[a:a+1000]
    print(a, 'sum=', sum(seg) % 1000000007)
print('lines25-28 check:')
lines = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt').read().split('\n')
for n in (25, 26, 27, 28):
    print('line', n, 'len=', len(lines[n-1]), 'sum=', sum(lines[n-1].encode()) % 1000000007)
EOF
