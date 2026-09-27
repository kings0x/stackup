#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
forge flatten src/StackUp.sol > /tmp/StackUpV2.flat.sol 2>/dev/null
wc -lc /tmp/StackUpV2.flat.sol
cp /tmp/StackUpV2.flat.sol /mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol
base64 -w 1200 /tmp/StackUpV2.flat.sol > /tmp/suv2-b64.txt
wc -c /tmp/suv2-b64.txt
rm -rf /mnt/c/Users/Admin/Code/stackup/contracts/chunks
mkdir -p /mnt/c/Users/Admin/Code/stackup/contracts/chunks
split -n l/6 /tmp/suv2-b64.txt /mnt/c/Users/Admin/Code/stackup/contracts/chunks/c
ls /mnt/c/Users/Admin/Code/stackup/contracts/chunks/
echo FLAT2_DONE
