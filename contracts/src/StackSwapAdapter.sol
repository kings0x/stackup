// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStackSwap} from "./interfaces/IStackModules.sol";

/// @title StackSwapAdapter
/// @notice Testnet fixed-price swap venue with 1% adverse bound. Mainnet: point at a real Arc DEX.
/// @dev Holds a USDC + stock float funded by treasury for testnet fills. Enforces oracle-relative floor.
///      Decimals are constructor parameters so 8-dec mocks and 18-dec dShares both work.
contract StackSwapAdapter is IStackSwap {
    using SafeERC20 for IERC20;

    address public immutable override STOCK;
    address public immutable override USDC;
    uint8 public immutable STOCK_DEC;
    uint8 public immutable FEED_DEC;
    uint8 public constant USDC_DEC = 6;
    address public treasury;
    uint256 public constant BOUND_BPS = 9_900; // worst fill = 99% of oracle mark

    error NotTreasury();

    constructor(address stock_, address usdc_, uint8 stockDec_, uint8 feedDec_, address treasury_) {
        STOCK = stock_;
        USDC = usdc_;
        STOCK_DEC = stockDec_;
        FEED_DEC = feedDec_;
        treasury = treasury_;
    }

    function buy(uint256 usdcIn, uint256 minOut, uint256 refPrice) external override returns (uint256 stockOut) {
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), usdcIn);
        stockOut = (usdcIn * (10 ** STOCK_DEC) * (10 ** FEED_DEC)) / refPrice / (10 ** USDC_DEC);
        stockOut = (stockOut * BOUND_BPS) / 10_000;
        require(stockOut >= minOut, "slip");
        IERC20(STOCK).safeTransfer(msg.sender, stockOut);
    }

    function sell(uint256 stockIn, uint256 minOut, uint256 refPrice) external override returns (uint256 usdcOut) {
        IERC20(STOCK).safeTransferFrom(msg.sender, address(this), stockIn);
        usdcOut = (stockIn * refPrice * (10 ** USDC_DEC)) / (10 ** STOCK_DEC) / (10 ** FEED_DEC);
        usdcOut = (usdcOut * BOUND_BPS) / 10_000;
        require(usdcOut >= minOut, "slip");
        IERC20(USDC).safeTransfer(msg.sender, usdcOut);
    }

    function sweep() external {
        if (msg.sender != treasury) revert NotTreasury();
        IERC20(USDC).safeTransfer(treasury, IERC20(USDC).balanceOf(address(this)));
        IERC20(STOCK).safeTransfer(treasury, IERC20(STOCK).balanceOf(address(this)));
    }
}
