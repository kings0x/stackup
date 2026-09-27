#!/usr/bin/env bash
cd /mnt/c/Users/Admin/Code/stackup/contracts
echo "=== 0x0.st ==="
curl -sS -F "file=@StackUp.flat.sol" https://0x0.st -o /tmp/stackup-paste2.txt --max-time 90 || echo "FAIL0X"
cat /tmp/stackup-paste2.txt; echo
echo DONE
