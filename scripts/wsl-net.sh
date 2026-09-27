#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
echo "=== dns ==="
getent hosts testnet.arcscan.app || echo DNS_FAIL
echo "=== tcp ==="
timeout 15 bash -c '</dev/tcp/rpc.testnet.arc.io/443' && echo TCP_OK || echo TCP_FAIL
echo "=== cast ==="
cast chain-id --rpc-url https://rpc.testnet.arc.io || echo RPC_FAIL
