#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/extern/dshare
forge build 2>&1 | tail -6
echo PORT_BUILD_DONE
