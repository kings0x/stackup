#!/usr/bin/env bash
python3 - <<'EOF'
lines = open('/mnt/c/Users/Admin/Code/stackup/contracts/gz/all.txt').read().split('\n')
if lines and lines[-1] == '': lines = lines[:-1]
for g in range(11):
    chunk = ''.join(lines[g*4:(g+1)*4])
    print(f'G{g+1} lines {g*4+1}-{min((g+1)*4,44)} len=', len(chunk), 'sum=', sum(chunk.encode()) % 1000000007)
EOF
