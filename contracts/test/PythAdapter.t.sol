// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import {PythPriceAdapter} from "../src/PythPriceAdapter.sol";
import {IStackPrice} from "../src/interfaces/IStackModules.sol";

contract MockPyth {
    int64 public px = 200_00000000; // $200 @ expo -8
    uint64 public cf = 50_000000; // $0.50 conf
    int32 public ex = -8;
    uint256 public ts;
    bool public shouldRevert;

    constructor() {
        ts = block.timestamp;
    }
    function getPriceNoOlderThan(bytes32, uint256 age) external view returns (int64, uint64, int32, uint256) {
        if (shouldRevert) revert("stale");
        if (block.timestamp - ts > age) revert("stale");
        return (px, cf, ex, ts);
    }
    function getUpdateFee(bytes[] calldata) external pure returns (uint256) {
        return 1;
    }
    function setVals(int64 p, uint64 c) external {
        px = p;
        cf = c;
        ts = block.timestamp;
    }
    function setExpo(int32 e) external {
        ex = e;
    }
    function setRevert() external {
        shouldRevert = true;
    }
}

contract PythAdapterTest is Test {
    MockPyth pyth;
    PythPriceAdapter adapter;
    bytes32 constant NVDA = bytes32(uint256(1));

    function setUp() public {
        pyth = new MockPyth();
        adapter = new PythPriceAdapter(address(0xBEEF), 18, address(pyth), NVDA, address(this));
    }

    function test_live_18d() public view {
        IStackPrice.Quote memory q = adapter.latest();
        assertEq(uint256(q.state), uint256(IStackPrice.FeedState.LIVE));
        assertEq(q.price, 200e8);
        assertEq(adapter.valueUsdc(1e18, 200e8), 200e6);
    }

    function test_stale_invalid() public {
        vm.warp(block.timestamp + 9 hours);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_wide_conf_invalid() public {
        pyth.setVals(200_00000000, 5_00000000); // $50 conf on $200 = 25%
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_negative_revert_invalid() public {
        pyth.setVals(-1, 1);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
        pyth.setRevert();
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.INVALID));
    }

    function test_expo_conversion() public {
        pyth.setExpo(-6); // $200.00 with expo -6
        pyth.setVals(200_000000, 10000);
        assertEq(adapter.latest().price, 200e8);
    }

    function test_held() public {
        adapter.setHeld(true);
        assertEq(uint256(adapter.latest().state), uint256(IStackPrice.FeedState.HELD));
    }
}
