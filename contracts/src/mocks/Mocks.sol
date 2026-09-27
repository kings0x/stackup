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

/// @notice Rebasing equity mock modeling Dinari-style split behavior.
/// @dev Displayed balances scale with `scale` (raw * scale / 1e18). A 2:1 split doubles `scale`;
///      a 1:2 reverse split halves it. Transfers move displayed amounts (rounded to raw units).
///      Like dShares, the token can be paused (transfers revert) during corporate-action processing.
contract MockRebasingStock is ERC20 {
    uint256 public scale = 1e18;
    address public admin;
    bool public paused;

    constructor(string memory n, string memory s) ERC20(n, s) {
        admin = msg.sender;
    }
    function decimals() public pure override returns (uint8) {
        return 8;
    }
    function balanceOf(address a) public view override returns (uint256) {
        return super.balanceOf(a) * scale / 1e18;
    }
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() * scale / 1e18;
    }
    function _update(address from, address to, uint256 value) internal override {
        if (paused) revert("paused");
        uint256 rawMove = (value * 1e18 + scale - 1) / scale; // ceil: never create value from rounding
        super._update(from, to, rawMove);
    }
    function faucet(address to, uint256 displayedAmt) external {
        super._update(address(0), to, displayedAmt * 1e18 / scale);
    }
    function rebase(uint256 newScale) external {
        require(msg.sender == admin, "admin");
        require(newScale > 0, "scale");
        scale = newScale;
    }
    function setPaused(bool v) external {
        require(msg.sender == admin, "admin");
        paused = v;
    }
}
