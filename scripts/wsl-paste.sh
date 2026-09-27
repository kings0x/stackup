#!/usr/bin/env bash
set -e
cd /mnt/c/Users/Admin/Code/stackup/contracts
echo "=== uploading flattened source ==="
curl -sS -X POST --data-binary @StackUp.flat.sol https://paste.rs -o /tmp/stackup-paste-url.txt --max-time 60 || echo "PASTE_RS_FAIL"
cat /tmp/stackup-paste-url.txt; echo
cp /tmp/stackup-paste-url.txt /mnt/c/Users/Admin/Code/stackup/contracts/.paste-url.txt 2>/dev/null || true
echo UPLOAD_DONE
