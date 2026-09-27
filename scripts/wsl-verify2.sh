#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
sleep 45
export ETHERSCAN_API_KEY="arc"
forge verify-contract 0xf3155d27a9cbbce18e4618b8562e69ded0058329 src/StackUp.sol:StackUp \
  --chain-id 5042002 --rpc-url https://rpc.testnet.arc.io \
  --verifier etherscan --verifier-url https://testnet.arcscan.app/api \
  --constructor-args "$(cast abi-encode 'constructor(address,address)' 0x8f34ae9c5afe4c8ced8aad1038e8f03e38314227 0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686)" 2>&1 | tail -4
echo VERIFY_RETRY_DONE
