// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Script.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockUSDC} from "../src/mocks/Mocks.sol";

interface IDShareMint {
    function mint(address to, uint256 value) external;
}

/// @notice Lists the real Dinari-port DShare (tNVDA.d) in StackUp SHARE mode on Arc testnet.
/// @dev Deployer holds DShare MINTER_ROLE from the port script. No GPL code is copied here;
///      we only reference the deployed token's public ERC-20/minter interface.
///      Usage: forge script script/ListDShare.s.sol --rpc-url $ARC_TESTNET_RPC --broadcast
contract ListDShare is Script {
    address constant CORE = 0xb823Dd1180dD8d31493614b86F19e0A7D282C28d;
    address constant VAULT = 0x6F1C3Aa1356842D8dF38e7c6ec0BF96BAdD95456;
    address constant USDC = 0xC41E67a92364353EDBb6f9ee0537F8d685562628;
    address constant DSHARE = 0x29602a5895faB2C015a4840deFF5E0550B990385;

    function run() external {
        uint256 key = vm.envUint("DEPLOYER_KEY");
        address admin = vm.addr(key);
        vm.startBroadcast(key);

        StackPriceAdapter price = new StackPriceAdapter(DSHARE, 18, 8, admin);
        price.setPrice(200e8);
        StackSwapAdapter swap = new StackSwapAdapter(DSHARE, USDC, 18, 8, admin);
        IDShareMint(DSHARE).mint(address(swap), 10_000e18);
        MockUSDC(USDC).faucet(address(swap), 100_000e6);
        MockUSDC(USDC).faucet(VAULT, 50_000e6);
        uint256 assetId = StackUp(CORE).listAsset(DSHARE, 18, address(price), address(swap), true);

        vm.stopBroadcast();
        console2.log("dshare assetId:", assetId);
        console2.log("price:", address(price));
        console2.log("swap:", address(swap));
    }
}
