#!/usr/bin/env bash
python3 - <<'EOF'
lines = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt').read().split('\n')
if lines and lines[-1] == '': lines = lines[:-1]
for i,(a,b) in enumerate([(23,26),(27,30),(31,34),(35,38),(39,42),(43,44)],1):
    chunk = ''.join(lines[a-1:b])
    print(f'R{i} lines {a}-{b} len=', len(chunk), 'sum=', sum(chunk.encode()) % 1000000007)
EOF
