// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import {ChainlinkPriceAdapter} from "../src/ChainlinkPriceAdapter.sol";
import {IStackPrice} from "../src/interfaces/IStackModules.sol";

contract MockFeed {
    uint8 public dec = 8;
    uint80 public rid = 7;
    int256 public ans = 200e8;
    uint256 public upd;
    uint80 public inRound = 7;
    bool public shouldRevert;

    constructor() {
        upd = block.timestamp;
    }
    function decimals() external view returns (uint8) {
        return dec;
    }
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        if (shouldRevert) revert("feed down");
        return (rid, ans, upd, upd, inRound);
    }
    function setAnswer(int256 a) external {
        ans = a;
        upd = block.timestamp;
    }
    function setStale(uint256 age) external {
        upd = block.timestamp - age;
    }
    function setFuture() external {
        upd = block.timestamp + 3600;
    }
    function setRevert(bool v) external {
        shouldRevert = v;
    }
}

contract ChainlinkAdapterTest is Test {
    MockFeed feed;
    ChainlinkPriceAdapter adapter;
    address stock = address(0xBEEF);

    function setUp() public {
        feed = new MockFeed();
        adapter = new ChainlinkPriceAdapter(stock, 18, address(feed), address(this));
    }

    function test_live_values_18d_stock() public view {
        IStackPrice.Quote memory q = adapter.latest();
        assertEq(uint256(q.state), uint256(IStackPrice.FeedState.LIVE));
        assertEq(q.price, 200e8);
        // 2.5 tokens @ $200 = $500
        assertEq(adapter.valueUsdc(2.5e18, 200e8), 500e6);
    }

    function test_stale_is_invalid() public {
        vm.warp(block.timestamp + 9 hours);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_zero_negative_invalid() public {
        feed.setAnswer(0);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
        feed.setAnswer(-5);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_future_invalid() public {
        feed.setFuture();
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_revert_invalid() public {
        feed.setRevert(true);
        IStackPrice.Quote memory q = adapter.latest();
        assertEq(uint256(q.state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_held_explicit() public {
        adapter.setHeld(true);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.HELD));
    }

    function test_admin_gate() public {
        vm.prank(address(0xCAFE));
        vm.expectRevert(ChainlinkPriceAdapter.NotAdmin.selector);
        adapter.setHeld(true);
    }
}
