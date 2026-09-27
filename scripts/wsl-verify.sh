#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
RPC="https://rpc.testnet.arc.io"
API="https://testnet.arcscan.app/api"
ADMIN="0x6B31DB6bF82654498d6Cc3fB3aDe7779E5672686"
USDC="0x8f34ae9c5afe4c8ced8aad1038e8f03e38314227"
CORE="0xf3155d27a9cbbce18e4618b8562e69ded0058329"
VAULT="0xb147d1f4284d1f0f075244237e2b91fb0c0d1699"
NVDA="0x493aea8c0483999594adc73739debc1d81bd04ab"
NVDAP="0xa963989e1bfc6dd711ee1000bd04f52de624f1fd"
NVDAS="0xadf9614dec5ec834582c25b0d74da12a07446c9c"
export ETHERSCAN_API_KEY="arc"
verify() {
  echo "--- $1 $2 ---"
  forge verify-contract "$2" "$1" --chain-id 5042002 --rpc-url "$RPC" \
    --verifier etherscan --verifier-url "$API" --constructor-args "$3" 2>&1 | tail -4 || true
}
verify src/StackUp.sol:StackUp "$CORE" "$(cast abi-encode 'constructor(address,address)' $USDC $ADMIN)"
verify src/StackVault.sol:StackVault "$VAULT" "$(cast abi-encode 'constructor(address,address,address)' $USDC $CORE $ADMIN)"
verify src/StackPriceAdapter.sol:StackPriceAdapter "$NVDAP" "$(cast abi-encode 'constructor(address,uint8,uint8,address)' $NVDA 8 8 $ADMIN)"
verify src/StackSwapAdapter.sol:StackSwapAdapter "$NVDAS" "$(cast abi-encode 'constructor(address,address,address)' $NVDA $USDC $ADMIN)"
echo VERIFY_DONE
