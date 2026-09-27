#!/usr/bin/env bash
curl -s --max-time 90 https://docs.chain.link/data-feeds/llms-full.txt -o /tmp/llms.txt
ls -la /tmp/llms.txt
python3 - <<'EOF'
import re
t = open('/tmp/llms.txt').read()
print('size:', len(t))
arcs = [m.start() for m in re.finditer(r'[Aa]rc', t)]
print('arc mentions:', len(arcs))
seen = set()
n = 0
for p in arcs:
    ctx = t[max(0,p-100):p+180].replace('\n', ' ')
    key = ctx[:70]
    if key not in seen and n < 25:
        seen.add(key)
        print('---', ctx[:200])
        n += 1
EOF
