#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
forge verify-contract 0xb823dd1180dd8d31493614b86f19e0a7d282c28d src/StackUp.sol:StackUp \
  --chain-id 5042002 --rpc-url https://rpc.testnet.arc.io \
  --verifier sourcify 2>&1 | tail -8
echo SOURCIFY_TRY_DONE
