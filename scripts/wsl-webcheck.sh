#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup
echo "=== pnpm install ==="
pnpm install > /tmp/stackup-pnpm.log 2>&1; echo "PNPM_EXIT:$?"
tail -5 /tmp/stackup-pnpm.log
echo "=== typecheck ==="
pnpm --filter @stackup/web typecheck > /tmp/stackup-tsc.log 2>&1; echo "TSC_EXIT:$?"
tail -25 /tmp/stackup-tsc.log
