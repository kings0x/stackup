#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
forge flatten src/StackUp.sol > /tmp/StackUp.flat.sol 2>/tmp/flat-err.log || tail -5 /tmp/flat-err.log
wc -l /tmp/StackUp.flat.sol
cp /tmp/StackUp.flat.sol /mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol
echo FLAT_DONE
