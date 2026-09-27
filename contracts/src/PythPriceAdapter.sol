// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IStackPrice} from "./interfaces/IStackModules.sol";

interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (Price memory);
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256);
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
}

/// @title PythPriceAdapter
/// @notice Pull-model price adapter for Arc. Reads a Pyth price only if fresh within maxAge
///         and confidence-tolerated; otherwise INVALID. HELD is explicit (issuer halt notice).
/// @dev Pyth never pushes: a fresh price must be written first via updatePriceFeeds (Hermes
///      payload + fee) — either by a keeper or prepended to the user's own transaction bundle.
///      Without a recent update, financed actions safely refuse (same as a stale Chainlink feed).
///      Price is normalized to 8 feed decimals. Confidence gate rejects wide spreads.
///      Arc testnet Pyth: 0x2880aB155794e7179c9eE2e38200202908C17B43 (price IDs = universal per asset).
contract PythPriceAdapter is IStackPrice {
    address public immutable override STOCK;
    uint8 public immutable STOCK_DEC;
    uint8 public constant FEED_DEC = 8;
    uint8 public constant USDC_DEC = 6;

    IPyth public immutable PYTH;
    bytes32 public immutable PRICE_ID;
    address public admin;
    bool public held;
    uint256 public maxAge = 8 hours;
    uint256 public maxConfBps = 100; // 1% — wider spreads are INVALID

    error NotAdmin();

    event Held(bool held);
    event MaxAgeSet(uint256 maxAge);
    event MaxConfSet(uint256 maxConfBps);

    constructor(address stock_, uint8 stockDec_, address pyth_, bytes32 priceId_, address admin_) {
        STOCK = stock_;
        STOCK_DEC = stockDec_;
        PYTH = IPyth(pyth_);
        PRICE_ID = priceId_;
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

    function setMaxConfBps(uint256 v) external {
        if (msg.sender != admin) revert NotAdmin();
        maxConfBps = v;
        emit MaxConfSet(v);
    }

    /// @notice Fee (in native gas token) required to push `updateData` on-chain.
    function updateFee(bytes[] calldata updateData) external view returns (uint256) {
        return PYTH.getUpdateFee(updateData);
    }

    function latest() external view override returns (Quote memory q) {
        uint256 now_ = block.timestamp;
        try PYTH.getPriceNoOlderThan(PRICE_ID, maxAge) returns (IPyth.Price memory p) {
            uint256 n = _norm(p);
            if (held) return Quote(FeedState.HELD, n, p.publishTime);
            if (p.price <= 0 || n == 0 || p.publishTime > now_) return Quote(FeedState.INVALID, 0, p.publishTime);
            if (p.conf * 10_000 > uint64(p.price) * maxConfBps) {
                return Quote(FeedState.INVALID, 0, p.publishTime);
            }
            return Quote(FeedState.LIVE, n, p.publishTime);
        } catch {
            return Quote(FeedState.INVALID, 0, 0);
        }
    }

    function valueUsdc(uint256 stockAmount, uint256 px) external view override returns (uint256) {
        return (stockAmount * px * (10 ** USDC_DEC)) / (10 ** STOCK_DEC) / (10 ** FEED_DEC);
    }

    /// @dev Pyth expo is negative for USD prices (e.g. -8): price8 = price * 10^(8+expo).
    function _norm(IPyth.Price memory p) private pure returns (uint256) {
        if (p.price <= 0) return 0;
        int256 e = int256(8) + int256(p.expo);
        if (e >= 0) return uint256(int256(p.price)) * (10 ** uint256(e));
        return uint256(int256(p.price)) / (10 ** uint256(-e));
    }
}
