#!/usr/bin/env bash
python3 - <<'EOF'
import re
t = open('/tmp/llms.txt').read()
print('chain 5042002/5042 mentions:', len(re.findall(r'5042002|5042', t)))
print('NVDA mentions:', len(re.findall(r'NVDA', t)))
for m in re.finditer(r'NVDA.{0,120}', t):
    print('NVDA-CTX:', m.group(0)[:130].replace('\n',' '))
    break
# networks list in addresses page?
i = t.find('networks')
print('---networks section---')
print(t[i:i+800].replace('\n',' ')[:800] if i>0 else 'none')
EOF
