#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/extern/dshare
rm -f t.tgz prb.tgz dl.tgz
dl() { mkdir -p "$2"; curl -sSL --max-time 180 "$1" -o dl.tgz && tar xzf dl.tgz --strip-components=1 -C "$2" && rm dl.tgz; }
[ -d lib/prb-math/src ] || dl https://codeload.github.com/PaulRBerg/prb-math/tar.gz/refs/heads/main lib/prb-math
[ -d lib/kinto-contracts-helpers/src ] || dl https://codeload.github.com/dinaricrypto/kinto-contracts-helpers/tar.gz/refs/heads/main lib/kinto-contracts-helpers
forge build 2>&1 | tail -6
echo PORT_BUILD2_DONE
