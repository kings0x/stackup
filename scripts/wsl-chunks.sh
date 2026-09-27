#!/usr/bin/env bash
set -e
cd /mnt/c/Users/Admin/Code/stackup/contracts
base64 -w 1200 StackUp.flat.sol > /tmp/stackup-b64.txt
wc -c /tmp/stackup-b64.txt
split -n l/6 /tmp/stackup-b64.txt /tmp/stackup-chunk-
ls -la /tmp/stackup-chunk-* | awk '{print $NF, $5}'
cp /tmp/stackup-chunk-* /mnt/c/Users/Admin/Code/stackup/contracts/.chunk-
ls /mnt/c/Users/Admin/Code/stackup/contracts/.chunk-*
