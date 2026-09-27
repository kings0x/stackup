// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Script.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {ChainlinkPriceAdapter} from "../src/ChainlinkPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockStock, MockUSDC, MockRebasingStock} from "../src/mocks/Mocks.sol";
import {IStackPrice} from "../src/interfaces/IStackModules.sol";

/// @notice Deploys StackUp + vault + mock equities to Arc testnet.
/// @dev Set FEED_SNVDA / FEED_SAAPL to Chainlink aggregator proxies to use real feeds;
///      otherwise an admin-set mock price adapter is deployed per asset.
///      sREB is a Dinari-style rebasing mock listed in SHARE mode to prove split-safe custody.
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

        _listOne(core, vault, usdc, admin, "sNVDA", feedNvda, false, false);
        _listOne(core, vault, usdc, admin, "sAAPL", feedAapl, false, false);
        _listOne(core, vault, usdc, admin, "sREB", address(0), false, true);
        vm.stopBroadcast();
    }

    function _listOne(
        StackUp core,
        StackVault vault,
        MockUSDC usdc,
        address admin,
        string memory name,
        address feed,
        bool is18Dec,
        bool shareMode
    ) private {
        uint8 sdec = is18Dec ? 18 : 8;
        address stock;
        if (shareMode) {
            stock = address(new MockRebasingStock(name, name));
        } else {
            stock = address(new MockStock(name, name));
        }
        IStackPrice price;
        if (feed == address(0)) {
            StackPriceAdapter mock = new StackPriceAdapter(stock, sdec, 8, admin);
            mock.setPrice(200e8);
            price = IStackPrice(address(mock));
        } else {
            price = IStackPrice(address(new ChainlinkPriceAdapter(stock, sdec, feed, admin)));
        }
        StackSwapAdapter swap = new StackSwapAdapter(stock, address(usdc), sdec, 8, admin);
        if (shareMode) {
            MockRebasingStock(stock).faucet(address(swap), 10_000 * (10 ** sdec));
        } else {
            MockStock(stock).faucet(address(swap), 10_000 * (10 ** sdec));
        }
        usdc.faucet(address(swap), 100_000e6);
        usdc.faucet(address(vault), 50_000e6);
        core.listAsset(stock, sdec, address(price), address(swap), shareMode);
    }
}
