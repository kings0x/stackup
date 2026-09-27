#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
forge build 2>&1 | grep -E "^(Compiler run|Error|Warning \(20|.*error)" | head -20
forge test -vvv 2>&1 | tail -25
echo "BT_DONE"
