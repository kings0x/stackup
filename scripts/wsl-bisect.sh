#!/usr/bin/env bash
python3 - <<'EOF'
d = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt','rb').read().replace(b'\n',b'')
print('total', len(d))
for a in (16000, 20000, 24000, 28000, 32000, 36000, 40000):
    seg = d[a:a+4000]
    print(a, 'len=', len(seg), 'sum=', sum(seg) % 1000000007)
EOF
