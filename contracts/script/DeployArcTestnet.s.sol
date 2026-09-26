// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Script.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockStock, MockUSDC} from "../src/mocks/Mocks.sol";

/// @notice Deploys StackUp + vault + 2 mock equities to Arc testnet. Usage:
///   forge script script/DeployArcTestnet.s.sol --rpc-url $ARC_TESTNET_RPC --broadcast
contract DeployArcTestnet is Script {
    function run() external {
        uint256 key = vm.envUint("DEPLOYER_KEY");
        address admin = vm.addr(key);
        vm.startBroadcast(key);

        MockUSDC usdc = new MockUSDC();
        StackUp core = new StackUp(address(usdc), admin);
        StackVault vault = new StackVault(address(usdc), address(core), admin);
        core.linkVault(address(vault));

        string[2] memory names = ["sNVDA", "sAAPL"];
        for (uint256 i = 0; i < names.length; i++) {
            MockStock stock = new MockStock(names[i], names[i]);
            StackPriceAdapter price = new StackPriceAdapter(address(stock), 8, 8, admin);
            StackSwapAdapter swap = new StackSwapAdapter(address(stock), address(usdc), admin);
            price.setPrice(200e8); // $200 test mark
            stock.faucet(address(swap), 10_000e8);
            usdc.faucet(address(swap), 100_000e6);
            usdc.faucet(address(vault), 50_000e6);
            core.listAsset(address(stock), address(price), address(swap));
        }
        vm.stopBroadcast();
    }
}
