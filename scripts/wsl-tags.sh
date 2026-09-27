#!/usr/bin/env bash
curl -s --max-time 30 "https://api.github.com/repos/Vectorized/solady/tags?per_page=100" > /tmp/solady-tags.json
python3 - <<'EOF'
import json
tags = [t["name"] for t in json.load(open('/tmp/solady-tags.json'))]
print('total:', len(tags))
print('newest 5:', tags[:5])
print('v0.0.2xx sample:', [t for t in tags if t.startswith('v0.0.2')][:8])
EOF
