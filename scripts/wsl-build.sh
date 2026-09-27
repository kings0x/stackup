#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup
echo "STEP1: installing forge deps"
bash scripts/install-forge-deps.sh
echo "STEP2: forge build"
cd contracts
forge build
echo "BUILD_DONE"
