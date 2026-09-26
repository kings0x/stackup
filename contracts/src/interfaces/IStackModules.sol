// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IStackVault {
    function USDC() external view returns (address);
    function stackUp() external view returns (address);
    function draw(uint256 amount) external;
    function available() external view returns (uint256);
}

interface IStackPrice {
    enum FeedState {
        LIVE,
        HELD,
        INVALID
    }
    struct Quote {
        FeedState state;
        uint256 price;
        uint256 updatedAt;
    }
    function STOCK() external view returns (address);
    function latest() external view returns (Quote memory);
    function valueUsdc(uint256 stockAmount, uint256 price) external view returns (uint256);
}

interface IStackSwap {
    function STOCK() external view returns (address);
    function USDC() external view returns (address);
    function buy(uint256 usdcIn, uint256 minOut, uint256 refPrice) external returns (uint256 stockOut);
    function sell(uint256 stockIn, uint256 minOut, uint256 refPrice) external returns (uint256 usdcOut);
}
