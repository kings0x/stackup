// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockStock, MockUSDC} from "../src/mocks/Mocks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StackUpTest is Test {
    StackUp core;
    StackVault vault;
    MockUSDC usdc;
    MockStock stock;
    StackPriceAdapter price;
    StackSwapAdapter swap;
    address user = address(0xBEEF);

    function setUp() public {
        usdc = new MockUSDC();
        core = new StackUp(address(usdc), address(this));
        vault = new StackVault(address(usdc), address(core), address(this));
        core.linkVault(address(vault));
        stock = new MockStock("sNVDA", "sNVDA");
        price = new StackPriceAdapter(address(stock), 8, 8, address(this));
        swap = new StackSwapAdapter(address(stock), address(usdc), address(this));
        price.setPrice(200e8);
        stock.faucet(address(swap), 10_000e8);
        usdc.faucet(address(swap), 100_000e6);
        usdc.faucet(address(vault), 50_000e6);
        core.listAsset(address(stock), address(price), address(swap));
        stock.faucet(user, 1e8);
        vm.prank(user);
        stock.approve(address(core), type(uint256).max);
    }

    function test_spot_open_close() public {
        vm.prank(user);
        uint256 id = core.openStack(1, 1e8, 10_000, 0, "stackup genesis");
        assertEq(core.ownerOf(id), user);
        assertEq(core.debtOf(id), 0);
        vm.prank(user);
        core.closeStack(id);
        assertEq(stock.balanceOf(user), 1e8);
    }

    function test_stacked_open_repay_close() public {
        vm.prank(user);
        uint256 id = core.openStack(1, 1e8, 12_500, 0, "");
        assertGt(core.debtOf(id), 0);
        uint256 d = core.debtOf(id);
        usdc.faucet(user, d);
        vm.prank(user);
        usdc.approve(address(core), d);
        vm.prank(user);
        core.repay(id, d);
        vm.prank(user);
        core.closeStack(id);
    }

    function test_transfer_clears_delegate() public {
        vm.prank(user);
        uint256 id = core.openStack(1, 1e8, 10_000, 0, "");
        vm.prank(user);
        core.setDelegate(id, address(0xCAFE));
        vm.prank(user);
        core.transferFrom(user, address(0xD00D), id);
        assertEq(core.stacks(id).delegate, address(0));
    }
}
