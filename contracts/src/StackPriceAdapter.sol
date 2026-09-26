// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IStackPrice} from "./interfaces/IStackModules.sol";

/// @title StackPriceAdapter
/// @notice Arc-testnet price adapter. Wraps a Chainlink-style feed answer into LIVE/HELD/INVALID + USDC valuation.
/// @dev For testnet: admin can set price + state. For mainnet: replace setter with real aggregator + staleness checks.
contract StackPriceAdapter is IStackPrice {
    address public immutable override STOCK;
    uint8 public immutable STOCK_DEC;
    uint8 public immutable FEED_DEC;
    uint8 public constant USDC_DEC = 6;

    address public admin;
    uint256 public price;
    uint256 public updatedAt;
    bool public paused;
    uint256 public maxAge = 8 hours;

    error NotAdmin();

    constructor(address stock_, uint8 stockDec_, uint8 feedDec_, address admin_) {
        STOCK = stock_;
        STOCK_DEC = stockDec_;
        FEED_DEC = feedDec_;
        admin = admin_;
    }

    function setPrice(uint256 p) external {
        if (msg.sender != admin) revert NotAdmin();
        price = p;
        updatedAt = block.timestamp;
    }

    function setPaused(bool v) external {
        if (msg.sender != admin) revert NotAdmin();
        paused = v;
    }

    function latest() external view override returns (Quote memory q) {
        if (paused) return Quote(FeedState.HELD, price, updatedAt);
        if (price == 0 || updatedAt == 0 || block.timestamp < updatedAt) return Quote(FeedState.INVALID, price, updatedAt);
        if (block.timestamp - updatedAt > maxAge) return Quote(FeedState.INVALID, price, updatedAt);
        return Quote(FeedState.LIVE, price, updatedAt);
    }

    function valueUsdc(uint256 stockAmount, uint256 px) external view override returns (uint256) {
        return (stockAmount * px * (10 ** USDC_DEC)) / (10 ** STOCK_DEC) / (10 ** FEED_DEC);
    }
}
