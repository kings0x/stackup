// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Script.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {ChainlinkPriceAdapter} from "../src/ChainlinkPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockStock, MockUSDC} from "../src/mocks/Mocks.sol";
import {IStackPrice} from "../src/interfaces/IStackModules.sol";

/// @notice Deploys StackUp + vault + 2 mock equities to Arc testnet.
/// @dev Set FEED_SNVDA / FEED_SAAPL to Chainlink aggregator proxies to use real feeds;
///      otherwise an admin-set mock price adapter is deployed per asset.
///      Usage: forge script script/DeployArcTestnet.s.sol --rpc-url $ARC_TESTNET_RPC --broadcast
contract DeployArcTestnet is Script {
    function run() external {
        uint256 key = vm.envUint("DEPLOYER_KEY");
        address admin = vm.addr(key);
        address feedNvda = vm.envOr("FEED_SNVDA", address(0));
        address feedAapl = vm.envOr("FEED_SAAPL", address(0));
        vm.startBroadcast(key);

        MockUSDC usdc = new MockUSDC();
        StackUp core = new StackUp(address(usdc), admin);
        StackVault vault = new StackVault(address(usdc), address(core), admin);
        core.linkVault(address(vault));

        _listOne(core, vault, usdc, admin, "sNVDA", feedNvda);
        _listOne(core, vault, usdc, admin, "sAAPL", feedAapl);
        vm.stopBroadcast();
    }

    function _listOne(
        StackUp core,
        StackVault vault,
        MockUSDC usdc,
        address admin,
        string memory name,
        address feed
    ) private {
        MockStock stock = new MockStock(name, name);
        IStackPrice price;
        if (feed == address(0)) {
            StackPriceAdapter mock = new StackPriceAdapter(address(stock), 8, 8, admin);
            mock.setPrice(200e8);
            price = IStackPrice(address(mock));
        } else {
            price = IStackPrice(address(new ChainlinkPriceAdapter(address(stock), 8, feed, admin)));
        }
        StackSwapAdapter swap = new StackSwapAdapter(address(stock), address(usdc), admin);
        stock.faucet(address(swap), 10_000e8);
        usdc.faucet(address(swap), 100_000e6);
        usdc.faucet(address(vault), 50_000e6);
        core.listAsset(address(stock), address(price), address(swap));
    }
}
