// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IStackPrice} from "./interfaces/IStackModules.sol";

interface IFeed {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/// @title ChainlinkPriceAdapter
/// @notice Production price adapter for Arc. Wraps any Chainlink AggregatorV3 feed into LIVE/HELD/INVALID.
/// @dev HELD is set explicitly by admin (e.g. issuer halt notice). INVALID covers stale/zero/negative/future rounds.
///      Feed address is immutable per adapter; deploy one adapter per asset and list it in StackUp.
contract ChainlinkPriceAdapter is IStackPrice {
    address public immutable override STOCK;
    uint8 public immutable STOCK_DEC;
    uint8 public immutable FEED_DEC;
    uint8 public constant USDC_DEC = 6;

    IFeed public immutable FEED;
    address public admin;
    bool public held;
    uint256 public maxAge = 8 hours;

    error NotAdmin();

    event Held(bool held);
    event MaxAgeSet(uint256 maxAge);

    constructor(address stock_, uint8 stockDec_, address feed_, address admin_) {
        STOCK = stock_;
        STOCK_DEC = stockDec_;
        FEED = IFeed(feed_);
        FEED_DEC = IFeed(feed_).decimals();
        admin = admin_;
    }

    function setHeld(bool v) external {
        if (msg.sender != admin) revert NotAdmin();
        held = v;
        emit Held(v);
    }

    function setMaxAge(uint256 v) external {
        if (msg.sender != admin) revert NotAdmin();
        maxAge = v;
        emit MaxAgeSet(v);
    }

    function latest() external view override returns (Quote memory q) {
        if (held) {
            (, int256 a,, uint256 u,) = _read();
            return Quote(FeedState.HELD, a > 0 ? uint256(a) : 0, u);
        }
        (uint80 rid, int256 answer,, uint256 updatedAt, uint80 inRound) = _read();
        if (
            answer <= 0 || updatedAt == 0 || block.timestamp < updatedAt || inRound < rid
                || block.timestamp - updatedAt > maxAge
        ) {
            return Quote(FeedState.INVALID, 0, updatedAt);
        }
        return Quote(FeedState.LIVE, uint256(answer), updatedAt);
    }

    function valueUsdc(uint256 stockAmount, uint256 px) external view override returns (uint256) {
        return (stockAmount * px * (10 ** USDC_DEC)) / (10 ** STOCK_DEC) / (10 ** FEED_DEC);
    }

    function _read() private view returns (uint80, int256, uint256, uint256, uint80) {
        try FEED.latestRoundData() returns (uint80 a, int256 b, uint256 c, uint256 d, uint80 e) {
            return (a, b, c, d, e);
        } catch {
            return (0, 0, 0, 0, 0);
        }
    }
}
