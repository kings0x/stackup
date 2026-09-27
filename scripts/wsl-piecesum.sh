#!/usr/bin/env bash
python3 - <<'EOF'
lines = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt').read().split('\n')
if lines and lines[-1] == '': lines = lines[:-1]
print('total lines:', len(lines))
bounds = [(1,8),(9,16),(17,24),(25,32),(33,40),(41,44)]
for i,(a,b) in enumerate(bounds,1):
    chunk = ''.join(lines[a-1:b])
    print(f'P{i} lines {a}-{b} len=', len(chunk), 'sum=', sum(chunk.encode()) % 1000000007)
EOF
