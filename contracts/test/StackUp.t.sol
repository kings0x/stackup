// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import {StackUp} from "../src/StackUp.sol";
import {StackVault} from "../src/StackVault.sol";
import {StackPriceAdapter} from "../src/StackPriceAdapter.sol";
import {StackSwapAdapter} from "../src/StackSwapAdapter.sol";
import {MockStock, MockUSDC, MockRebasingStock} from "../src/mocks/Mocks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StackUpTest is Test {
    StackUp core;
    StackVault vault;
    MockUSDC usdc;
    MockStock stock;
    StackPriceAdapter price;
    StackSwapAdapter swap;
    MockRebasingStock reb;
    StackPriceAdapter rebPrice;
    StackSwapAdapter rebSwap;
    address user = address(0xBEEF);
    address user2 = address(0xD00D);

    function setUp() public {
        usdc = new MockUSDC();
        core = new StackUp(address(usdc), address(this));
        vault = new StackVault(address(usdc), address(core), address(this));
        core.linkVault(address(vault));
        // RAW asset (fixed units)
        stock = new MockStock("sNVDA", "sNVDA");
        price = new StackPriceAdapter(address(stock), 8, 8, address(this));
        swap = new StackSwapAdapter(address(stock), address(usdc), 8, 8, address(this));
        price.setPrice(200e8);
        stock.faucet(address(swap), 10_000e8);
        usdc.faucet(address(swap), 100_000e6);
        usdc.faucet(address(vault), 50_000e6);
        core.listAsset(address(stock), 8, address(price), address(swap), false);
        stock.faucet(user, 1e8);
        vm.prank(user);
        stock.approve(address(core), type(uint256).max);
        // SHARE asset (rebasing, Dinari-style)
        reb = new MockRebasingStock("sREB", "sREB");
        rebPrice = new StackPriceAdapter(address(reb), 8, 8, address(this));
        rebSwap = new StackSwapAdapter(address(reb), address(usdc), 8, 8, address(this));
        rebPrice.setPrice(200e8);
        reb.faucet(address(rebSwap), 10_000e8);
        usdc.faucet(address(rebSwap), 100_000e6);
        core.listAsset(address(reb), 8, address(rebPrice), address(rebSwap), true);
        reb.faucet(user, 10e8);
        reb.faucet(user2, 10e8);
        vm.prank(user);
        reb.approve(address(core), type(uint256).max);
        vm.prank(user2);
        reb.approve(address(core), type(uint256).max);
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

    function test_share_split_up_flows_through() public {
        vm.prank(user);
        uint256 id = core.openStack(2, 1e8, 10_000, 0, "");
        assertEq(core.effectiveStockOf(id), 1e8);
        uint256 navBefore = core.healthOf(id).nav;
        reb.rebase(2e18); // 2:1 split
        assertEq(core.effectiveStockOf(id), 2e8);
        assertEq(core.healthOf(id).nav, navBefore * 2);
        vm.prank(user);
        core.closeStack(id);
        // wallet's own 9e8 also doubled in the split: 18e8 + 2e8 returned
        assertEq(reb.balanceOf(user), 20e8);
    }

    function test_share_split_down_no_stuck_funds() public {
        vm.prank(user);
        uint256 id = core.openStack(2, 1e8, 12_500, 0, "");
        uint256 d = core.debtOf(id);
        reb.rebase(0.5e18); // 1:2 reverse split halves balances
        uint256 eff = core.effectiveStockOf(id);
        assertApproxEqAbs(eff, 62251250, 10); // 1.245025e8 financed units halved
        usdc.faucet(user, d);
        vm.prank(user);
        usdc.approve(address(core), d);
        vm.prank(user);
        core.repay(id, d);
        uint256 before = reb.balanceOf(user);
        vm.prank(user);
        core.closeStack(id);
        assertEq(reb.balanceOf(user) - before, eff);
        assertLe(reb.balanceOf(address(core)), 10); // only rounding dust remains
    }

    function test_share_trim_proportional_across_positions() public {
        vm.prank(user);
        uint256 a = core.openStack(2, 2e8, 10_000, 0, "");
        vm.prank(user2);
        uint256 b = core.openStack(2, 1e8, 10_000, 0, "");
        reb.rebase(3e18); // 3:1 split
        assertEq(core.effectiveStockOf(a), 6e8);
        assertEq(core.effectiveStockOf(b), 3e8);
        // financed trim path needs debt; use repay-free partial close via trim on spot? trim sells to USDC and settles (no debt -> surplus to owner)
        vm.prank(user);
        core.trim(a, 3e8, 0);
        assertEq(core.effectiveStockOf(a), 3e8);
        assertEq(core.effectiveStockOf(b), 3e8);
        assertEq(usdc.balanceOf(user) > 0, true);
    }

    function test_sweep_dividends_not_stock() public {
        vm.prank(user);
        core.openStack(1, 1e8, 10_000, 0, "");
        usdc.faucet(address(core), 5e6); // simulated USD+ dividend to unverified holder
        address treasury = address(0x71EA);
        core.sweep(address(usdc), treasury);
        assertEq(usdc.balanceOf(treasury), 5e6);
        vm.expectRevert(StackUp.ProtectedToken.selector);
        core.sweep(address(stock), treasury);
    }
}
