// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Testnet mock: 8-decimal synthetic equity (sNVDA etc). No issuer backing. Faucet-mintable.
contract MockStock is ERC20 {
    uint8 private _dec;
    constructor(string memory n, string memory s) ERC20(n, s) {
        _dec = 8;
    }
    function decimals() public view override returns (uint8) {
        return _dec;
    }
    function faucet(address to, uint256 amt) external {
        _mint(to, amt);
    }
}

/// @notice Testnet mock USDC (6 decimals).
contract MockUSDC is ERC20 {
    constructor() ERC20("Test USDC", "tUSDC") {}
    function decimals() public view override returns (uint8) {
        return 6;
    }
    function faucet(address to, uint256 amt) external {
        _mint(to, amt);
    }
}
