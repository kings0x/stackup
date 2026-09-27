#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/extern/dshare
forge build > /tmp/dshare-build.log 2>&1
echo "BUILD_EXIT:$?"
grep -E "Compiler run" /tmp/dshare-build.log | head -3
grep -cE "^Error" /tmp/dshare-build.log
