#!/usr/bin/env bash
export PATH="$HOME/.foundry/bin:$PATH"
cd /mnt/c/Users/Admin/Code/stackup/contracts
RPC="https://rpc.testnet.arc.io"
V() { echo "--- $1 $2 ---"; forge verify-contract "$2" "$1" --chain-id 5042002 --rpc-url "$RPC" --verifier sourcify 2>&1 | tail -2; }
V src/StackVault.sol:StackVault 0x6f1c3aa1356842d8df38e7c6ec0bf96badd95456
V src/mocks/Mocks.sol:MockUSDC 0xc41e67a92364353edbb6f9ee0537f8d685562628
V src/mocks/Mocks.sol:MockStock 0xb618a3e8302a29a94b069fb2ef95ba1e2b0db747
V src/mocks/Mocks.sol:MockStock 0xab60b01554301eb77ad2363cf29bf0513e66310e
V src/mocks/Mocks.sol:MockRebasingStock 0x6479229e3fe2ddb4c3e8faaf844b0e86a8f8f988
V src/StackPriceAdapter.sol:StackPriceAdapter 0x289e74b87341060040293feb79841ad713de95b6
V src/StackPriceAdapter.sol:StackPriceAdapter 0xe69050a8290755c6382c882cd9fa201794367bc9
V src/StackPriceAdapter.sol:StackPriceAdapter 0x61e5516ac41b70728866ab8ecd0f8efb008e6b5f
V src/StackSwapAdapter.sol:StackSwapAdapter 0x720cf35d75c1a3a5fb3c2faffed2475bbbd0889e
V src/StackSwapAdapter.sol:StackSwapAdapter 0xa3e2504a63a6f3d53fdf0b4dc40c2a6a099f0832
V src/StackSwapAdapter.sol:StackSwapAdapter 0xe28ee0ec0731e108a69acdbf0f23ef0e9224920f
echo SOURCIFY_ALL_DONE
